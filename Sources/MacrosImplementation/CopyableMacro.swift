//Copyright © 2024 Hootsuite Media Inc. All rights reserved.

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `Copyable` macro, which takes a struct to create an extension
/// and provides a copy function, passing back the struct itself to access its properties to modify the fields
/// while keeping all other fields unchanged.
public struct CopyableMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw CopyableMacroError.notAStruct
        }
        
        guard !structDecl.memberBlock.members.isEmpty else {
            throw CopyableMacroError.emptyStruct
        }
        
        let varDecl = structDecl.memberBlock.members.compactMap { member in
            // Check if the member is a variable declaration
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                // Iterate over the bindings in the variable declaration
                return variableDecl
            }
            return nil
        }
        
        let paramTypeAnnotations = varDecl.enumerated().flatMap { (index, decl) in
            decl.bindings.compactMap { patternBindingListSyntax -> FunctionParameterSyntax? in
                guard patternBindingListSyntax.accessorBlock == nil else {
                    // computed property, skip
                    return nil
                }
                
                guard let identifier = patternBindingListSyntax.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                      let typeSyntax = patternBindingListSyntax.typeAnnotation else {
                    return nil
                }
                return FunctionParameterSyntax(
                    modifiers: decl.modifiers.trimmed,
                    firstName: identifier,
                    type: typeSyntax.type.trimmed,
                    trailingComma: .commaToken()
                )
            }
        }
        
        let modifiers = structDecl.modifiers.trimmed
        let extDecl = ExtensionDeclSyntax(
            extensionKeyword: .keyword(.extension),
            extendedType: type,
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax(
                    arrayLiteral: initMemberBlock(paramTypeAnnotations: paramTypeAnnotations, modifiers: modifiers),
                    copyBuilderMemberBlock(type: type, modifiers: modifiers),
                    try builderStructMemberBlock(type: type, paramTypeAnnotations: paramTypeAnnotations, modifiers: modifiers)
                )
            )
        )
        
        return [extDecl]
    }
}

private func initMemberBlock(paramTypeAnnotations: [FunctionParameterSyntax], modifiers: DeclModifierListSyntax) -> MemberBlockItemSyntax {
    
    let initFunctionParams: [FunctionParameterSyntax] = {
        let inputParams = paramTypeAnnotations.enumerated().map { (index, param) in
            return FunctionParameterSyntax(
                leadingTrivia: index == 0 ? .newline : nil,
                firstName: param.firstName,
                type: param.type,
                trailingComma: .commaToken(),
                trailingTrivia: .newline
            )
        }
        
        let forCopyInitParam = [FunctionParameterSyntax(
            firstName: "forCopyInit",
            type: OptionalTypeSyntax(wrappedType: IdentifierTypeSyntax(name: .identifier("Void")), questionMark: .postfixQuestionMarkToken()),
            defaultValue: InitializerClauseSyntax(value: NilLiteralExprSyntax())
        )]
        
        return inputParams + forCopyInitParam
    }()
    
    let initBody = CodeBlockSyntax(
        statements: CodeBlockItemListSyntax (
            paramTypeAnnotations.map {
                CodeBlockItemSyntax(
                    item: CodeBlockItemSyntax.Item(
                        InfixOperatorExprSyntax(
                            leftOperand: MemberAccessExprSyntax(
                                base: DeclReferenceExprSyntax(
                                    baseName: .keyword(
                                        .`self`
                                    )
                                ),
                                period: .periodToken(),
                                declName: DeclReferenceExprSyntax(
                                    baseName: .identifier($0.firstName.text)
                                )
                            ),
                            operator: AssignmentExprSyntax(),
                            rightOperand: DeclReferenceExprSyntax(
                                baseName: .identifier($0.firstName.text)
                            )
                        )
                    )
                )
            }
        ),
        trailingTrivia: .newline
    )
    
    return MemberBlockItemSyntax(
        leadingTrivia: [.docLineComment("/// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer"), .newlines(1)],
        decl: InitializerDeclSyntax(
            modifiers: modifiers,
            signature:
                FunctionSignatureSyntax(
                    parameterClause: FunctionParameterClauseSyntax(
                        leftParen: .leftParenToken(),
                        parameters: FunctionParameterListSyntax(
                            initFunctionParams
                        ),
                        rightParen: .rightParenToken(
                            leadingTrivia: .newline
                        )
                    )
                ),
            body: initBody,
            trailingTrivia: .newline
        )
    )
}

private func copyBuilderMemberBlock(type: TypeSyntaxProtocol, modifiers: DeclModifierListSyntax) -> MemberBlockItemSyntax {
    return MemberBlockItemSyntax(
        decl: FunctionDeclSyntax(
            modifiers: modifiers,
            funcKeyword: .keyword(.func),
            name: .identifier("copy"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax(
                        itemsBuilder: {
                            FunctionParameterSyntax(
                                stringLiteral: "build: (inout Builder) -> Void"
                            )
                        })
                ),
                returnClause: ReturnClauseSyntax(
                    arrow: .arrowToken(),
                    type: type
                )
            ),
            body: CodeBlockSyntax(
                leftBrace: .leftBraceToken(
                    trailingTrivia: .tab
                ),
                statements: CodeBlockItemListSyntax(
                    arrayLiteral: CodeBlockItemSyntax(stringLiteral: "var builder = Builder(original: self)"),
                    CodeBlockItemSyntax(stringLiteral: "build(&builder)"),
                    CodeBlockItemSyntax(stringLiteral: "return builder.toState()")
                ),
                rightBrace: .rightBraceToken(
                    trailingTrivia: .newline
                )
            ),
            trailingTrivia: .newline
        )
    
    )
}

private func builderStructMemberBlock(type: TypeSyntaxProtocol, paramTypeAnnotations: [FunctionParameterSyntax], modifiers: DeclModifierListSyntax) throws -> MemberBlockItemSyntax {
    let propertyMemberBlocks = paramTypeAnnotations.enumerated().map { (index, funcParam) in
        let isLastSyntax = index == paramTypeAnnotations.count - 1
        return MemberBlockItemSyntax(
            decl: VariableDeclSyntax(
                modifiers: funcParam.modifiers,
                bindingSpecifier: .keyword(.var),
                bindings: PatternBindingListSyntax {
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(identifier: funcParam.firstName.trimmed),
                        typeAnnotation: TypeAnnotationSyntax(type: funcParam.type)
                    )
                }
            ),
            trailingTrivia: isLastSyntax ? .newline : nil
        )
    }
    
    let structMemberBlocks = propertyMemberBlocks + [filePrivateInitMemberBlock(type: type, paramTypeAnnotations: paramTypeAnnotations),
                                                     try filePrivateToStateMemberBlock(type: type, paramTypeAnnotations: paramTypeAnnotations)]
    
    return MemberBlockItemSyntax(
        decl: StructDeclSyntax(
            modifiers: modifiers,
            structKeyword: .keyword(.struct),
            name: .identifier("Builder"),
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax(structMemberBlocks)
            )
        )
    )
}

private func filePrivateInitMemberBlock(type: TypeSyntaxProtocol, paramTypeAnnotations: [FunctionParameterSyntax]) -> MemberBlockItemSyntax {
    let assignMemberBlocks = paramTypeAnnotations.map { funcParam in
        CodeBlockItemSyntax(
            item: CodeBlockItemSyntax.Item(
                InfixOperatorExprSyntax(
                    leftOperand: MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .keyword(.`self`)),
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: funcParam.firstName.trimmed)),
                    operator: AssignmentExprSyntax(equal: .equalToken()),
                    rightOperand: MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .identifier("original")),
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: funcParam.firstName.trimmed)
                    )
                )
            )
        )
    }
    
    return MemberBlockItemSyntax(
        leadingTrivia: .newline,
        decl: InitializerDeclSyntax(
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.fileprivate))
            },
            initKeyword: .keyword(.`init`),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(parameters: FunctionParameterListSyntax {
                    FunctionParameterSyntax(
                        firstName: .identifier("original"),
                        colon: .colonToken(),
                        type: type
                    )
                })
            ),
            body: CodeBlockSyntax(statements: CodeBlockItemListSyntax(assignMemberBlocks))
        ),
        trailingTrivia: .newline
    )
}

private func filePrivateToStateMemberBlock(type: TypeSyntaxProtocol, paramTypeAnnotations: [FunctionParameterSyntax]) throws -> MemberBlockItemSyntax {
    guard let structName = type.as(IdentifierTypeSyntax.self)?.name.text else {
        throw CopyableMacroError.unexpected
    }
    
    let labeledExpressions = paramTypeAnnotations.enumerated().map { (index, funcParam) in
        let isLastSyntax = index == paramTypeAnnotations.count - 1
        return LabeledExprSyntax(
            leadingTrivia: [.tabs(1), .newlines(1)],
            label: .identifier(funcParam.firstName.trimmedDescription),
            colon: .colonToken(),
            expression: DeclReferenceExprSyntax(baseName: .identifier(funcParam.firstName.trimmedDescription)),
            trailingComma: isLastSyntax ? nil : .commaToken()
        )
    }
    
    return MemberBlockItemSyntax(
        leadingTrivia: .newline,
        decl: FunctionDeclSyntax(
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.fileprivate))
            },
            funcKeyword: .keyword(.func),
            name: .identifier("toState"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax()
                ),
                returnClause: ReturnClauseSyntax(
                    arrow: .arrowToken(),
                    type: type
                )
            ),
            body: CodeBlockSyntax(
                statements: CodeBlockItemListSyntax {
                    CodeBlockItemSyntax(
                        item: CodeBlockItemSyntax.Item(
                            ReturnStmtSyntax(
                                returnKeyword: .keyword(.return),
                                expression: FunctionCallExprSyntax(
                                    calledExpression: DeclReferenceExprSyntax(baseName: .identifier(structName)),
                                    leftParen: .leftParenToken(),
                                    arguments: LabeledExprListSyntax(labeledExpressions),
                                    rightParen: .rightParenToken(
                                        leadingTrivia: .newline
                                    )
                                )
                            )
                        )
                    )
                }
            )
        )
    )
}

enum CopyableMacroError: CustomStringConvertible, Error {
    case notAStruct
    case emptyStruct
    case unexpected
    
    var description: String {
        switch self {
        case .notAStruct:
            return "`@Copyable` must be used on a `struct`"
        case .unexpected:
            return "Unexpectedly failed while expanding `@Copyable` macro"
        case .emptyStruct:
            return "`struct` must not be empty"
        }
    }
}
