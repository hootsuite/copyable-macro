//Copyright © 2024 Hootsuite Media Inc. All rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class CopyableTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
            """
            @Copyable
            struct State {
                let a: Int
                let b: String?
            }
            """,
            expandedSource: 
            """
            struct State {
                let a: Int
                let b: String?
            }
            
            extension State {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                init(
                    a: Int,
                    b: String?,
                    forCopyInit: Void? = nil
                ) {
                    self.a = a
                    self.b = b
                }
            
                func copy(build: (inout Builder) -> Void) -> State {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                struct Builder {
                    var a: Int
                    var b: String?

                    fileprivate init(original: State) {
                        self.a = original.a
                        self.b = original.b
                    }

                    fileprivate func toState() -> State {
                        return State(
                            a: a,
                            b: b
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroThrowsErrorWhenUsedOnNonStruct() {
        assertMacroExpansion(
            """
            @Copyable
            class State {
                let a: Int
                let b: String?
            }
            """,
            expandedSource:
            """
            class State {
                let a: Int
                let b: String?
            }
            """,
            diagnostics:[
                DiagnosticSpec(message: "`@Copyable` must be used on a `struct`", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testMacroWithCustomProperties() {
        assertMacroExpansion(
            """
            @Copyable
            struct Student {
                let id: String
                let name: String
                let nickName: NickName
                let gender: Gender
            }
            """,
            expandedSource:
            """
            struct Student {
                let id: String
                let name: String
                let nickName: NickName
                let gender: Gender
            }
            
            extension Student {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                init(
                    id: String,
                    name: String,
                    nickName: NickName,
                    gender: Gender,
                    forCopyInit: Void? = nil
                ) {
                    self.id = id
                    self.name = name
                    self.nickName = nickName
                    self.gender = gender
                }
            
                func copy(build: (inout Builder) -> Void) -> Student {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                struct Builder {
                    var id: String
                    var name: String
                    var nickName: NickName
                    var gender: Gender

                    fileprivate init(original: Student) {
                        self.id = original.id
                        self.name = original.name
                        self.nickName = original.nickName
                        self.gender = original.gender
                    }

                    fileprivate func toState() -> Student {
                        return Student(
                            id: id,
                            name: name,
                            nickName: nickName,
                            gender: gender
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroWithArray() {
        assertMacroExpansion(
            """
            @Copyable
            struct Student {
                let nickNames: [NickName]
            }
            """,
            expandedSource:
            """
            struct Student {
                let nickNames: [NickName]
            }
            
            extension Student {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                init(
                    nickNames: [NickName],
                    forCopyInit: Void? = nil
                ) {
                    self.nickNames = nickNames
                }
            
                func copy(build: (inout Builder) -> Void) -> Student {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                struct Builder {
                    var nickNames: [NickName]

                    fileprivate init(original: Student) {
                        self.nickNames = original.nickNames
                    }

                    fileprivate func toState() -> Student {
                        return Student(
                            nickNames: nickNames
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroWithOptionalArray() {
        assertMacroExpansion(
            """
            @Copyable
            struct Student {
                let nickNames: [NickName]?
            }
            """,
            expandedSource:
            """
            struct Student {
                let nickNames: [NickName]?
            }
            
            extension Student {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                init(
                    nickNames: [NickName]?,
                    forCopyInit: Void? = nil
                ) {
                    self.nickNames = nickNames
                }
            
                func copy(build: (inout Builder) -> Void) -> Student {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                struct Builder {
                    var nickNames: [NickName]?

                    fileprivate init(original: Student) {
                        self.nickNames = original.nickNames
                    }

                    fileprivate func toState() -> Student {
                        return Student(
                            nickNames: nickNames
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroWithEmptyStruct() {
        assertMacroExpansion(
            """
            @Copyable
            struct State {}
            """,
            expandedSource:
            """
            struct State {}
            """,
            diagnostics:[
                DiagnosticSpec(message: "`struct` must not be empty", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testMacroWithVars() {
        assertMacroExpansion(
            """
            @Copyable
            struct State {
                var a: Int
                var b: String?
            }
            """,
            expandedSource:
            """
            struct State {
                var a: Int
                var b: String?
            }
            
            extension State {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                init(
                    a: Int,
                    b: String?,
                    forCopyInit: Void? = nil
                ) {
                    self.a = a
                    self.b = b
                }
            
                func copy(build: (inout Builder) -> Void) -> State {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                struct Builder {
                    var a: Int
                    var b: String?

                    fileprivate init(original: State) {
                        self.a = original.a
                        self.b = original.b
                    }

                    fileprivate func toState() -> State {
                        return State(
                            a: a,
                            b: b
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroWithDefaultValues() {
        assertMacroExpansion(
            """
            @Copyable
            struct State {
                let a: Int
                let b: String?
            
                init(
                    a: Int = 3,
                    b: String? = "default string"
                ) {
                    self.a = a
                    self.b = b
                }
            }
            """,
            expandedSource:
            """
            struct State {
                let a: Int
                let b: String?

                init(
                    a: Int = 3,
                    b: String? = "default string"
                ) {
                    self.a = a
                    self.b = b
                }
            }
            
            extension State {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                init(
                    a: Int,
                    b: String?,
                    forCopyInit: Void? = nil
                ) {
                    self.a = a
                    self.b = b
                }
            
                func copy(build: (inout Builder) -> Void) -> State {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                struct Builder {
                    var a: Int
                    var b: String?

                    fileprivate init(original: State) {
                        self.a = original.a
                        self.b = original.b
                    }

                    fileprivate func toState() -> State {
                        return State(
                            a: a,
                            b: b
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroDoesNotCopyComputedProperties() throws {
        assertMacroExpansion(
            """
            @Copyable
            struct State {
                let a: Int
                let b: String?
                var computed: String {
                    if a == 1 { "yes" } else { "no" }
                }
            }
            """,
            expandedSource:
            """
            struct State {
                let a: Int
                let b: String?
                var computed: String {
                    if a == 1 { "yes" } else { "no" }
                }
            }
            
            extension State {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                init(
                    a: Int,
                    b: String?,
                    forCopyInit: Void? = nil
                ) {
                    self.a = a
                    self.b = b
                }
            
                func copy(build: (inout Builder) -> Void) -> State {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                struct Builder {
                    var a: Int
                    var b: String?

                    fileprivate init(original: State) {
                        self.a = original.a
                        self.b = original.b
                    }

                    fileprivate func toState() -> State {
                        return State(
                            a: a,
                            b: b
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroDoesCopyClosureBasedProperties() throws {
        assertMacroExpansion(
            """
            @Copyable
            struct State {
                let a: Int
                let b: String?
                var c: String = {
                    if a == 1 { "yes" } else { "no" }
                }()
            }
            """,
            expandedSource:
            """
            struct State {
                let a: Int
                let b: String?
                var c: String = {
                    if a == 1 { "yes" } else { "no" }
                }()
            }
            
            extension State {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                init(
                    a: Int,
                    b: String?,
                    c: String,
                    forCopyInit: Void? = nil
                ) {
                    self.a = a
                    self.b = b
                    self.c = c
                }
            
                func copy(build: (inout Builder) -> Void) -> State {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                struct Builder {
                    var a: Int
                    var b: String?
                    var c: String

                    fileprivate init(original: State) {
                        self.a = original.a
                        self.b = original.b
                        self.c = original.c
                    }

                    fileprivate func toState() -> State {
                        return State(
                            a: a,
                            b: b,
                            c: c
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroRespectsModifiers() throws {
        assertMacroExpansion(
            """
            @Copyable
            public struct State {
                let a: Int
                let b: String?
            }
            """,
            expandedSource:
            """
            public struct State {
                let a: Int
                let b: String?
            }
            
            extension State {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                public init(
                    a: Int,
                    b: String?,
                    forCopyInit: Void? = nil
                ) {
                    self.a = a
                    self.b = b
                }
            
                public func copy(build: (inout Builder) -> Void) -> State {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                public struct Builder {
                    var a: Int
                    var b: String?

                    fileprivate init(original: State) {
                        self.a = original.a
                        self.b = original.b
                    }

                    fileprivate func toState() -> State {
                        return State(
                            a: a,
                            b: b
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroRespectsModifiersWithDefaultValues() throws {
        assertMacroExpansion(
            """
            @Copyable
            public struct State {
                let a: Int
                let b: String?
            
                public init(
                    a: Int = 3,
                    b: String? = "default string"
                ) {
                    self.a = a
                    self.b = b
                }
            }
            """,
            expandedSource:
            """
            public struct State {
                let a: Int
                let b: String?
            
                public init(
                    a: Int = 3,
                    b: String? = "default string"
                ) {
                    self.a = a
                    self.b = b
                }
            }
            
            extension State {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                public init(
                    a: Int,
                    b: String?,
                    forCopyInit: Void? = nil
                ) {
                    self.a = a
                    self.b = b
                }
            
                public func copy(build: (inout Builder) -> Void) -> State {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                public struct Builder {
                    var a: Int
                    var b: String?

                    fileprivate init(original: State) {
                        self.a = original.a
                        self.b = original.b
                    }

                    fileprivate func toState() -> State {
                        return State(
                            a: a,
                            b: b
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroRespectsModifiersOnProperties() throws {
        assertMacroExpansion(
            """
            @Copyable
            public struct State {
                public let a: Int
                public let b: String?
            }
            """,
            expandedSource:
            """
            public struct State {
                public let a: Int
                public let b: String?
            }
            
            extension State {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                public init(
                    a: Int,
                    b: String?,
                    forCopyInit: Void? = nil
                ) {
                    self.a = a
                    self.b = b
                }
            
                public func copy(build: (inout Builder) -> Void) -> State {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                public struct Builder {
                    public var a: Int
                    public var b: String?

                    fileprivate init(original: State) {
                        self.a = original.a
                        self.b = original.b
                    }

                    fileprivate func toState() -> State {
                        return State(
                            a: a,
                            b: b
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroWithNameSpaceConflict() throws {
        assertMacroExpansion(
            """
            @Copyable
            struct State {
                let a: Int
                let b: SomeClass.Image?
            }
            """,
            expandedSource:
            """
            struct State {
                let a: Int
                let b: SomeClass.Image?
            }
            
            extension State {
                /// This init exists to prevent overriding the default init and your other custom initializers if it exists already; ignore this initializer
                init(
                    a: Int,
                    b: SomeClass.Image?,
                    forCopyInit: Void? = nil
                ) {
                    self.a = a
                    self.b = b
                }
            
                func copy(build: (inout Builder) -> Void) -> State {
                    var builder = Builder(original: self)
                    build(&builder)
                    return builder.toState()
                }
            
                struct Builder {
                    var a: Int
                    var b: SomeClass.Image?

                    fileprivate init(original: State) {
                        self.a = original.a
                        self.b = original.b
                    }

                    fileprivate func toState() -> State {
                        return State(
                            a: a,
                            b: b
                        )
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}
