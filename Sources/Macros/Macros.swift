//Copyright © 2024 Hootsuite Media Inc. All rights reserved.

/// A macro that creates an extension on a struct to give a kotlin-like copy functionality
/// source code from: https://shopify.engineering/kotlin-style-copy-function-swift-structs
/// Used to make a copy of the struct while updating values passed in as parameters into a closure that receives the builder as the sole argument, and allows you to set overrides for selected properties.
@attached(extension, conformances: Equatable, names: arbitrary)
public macro Copyable() = #externalMacro(module: "MacrosImplementation", type: "CopyableMacro")
