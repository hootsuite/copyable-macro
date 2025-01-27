//Copyright © 2024 Hootsuite Media Inc. All rights reserved.

import SwiftSyntaxMacros

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MacrosImplementation)
import MacrosImplementation

// define the macros that you want to test here for them to be accessible in individual test classes
let testMacros: [String: Macro.Type] = [
    "Copyable": CopyableMacro.self
]
#endif
