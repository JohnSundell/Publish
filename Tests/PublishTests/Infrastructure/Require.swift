/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

func require<T>(_ expression: @autoclosure () -> T?,
                file: StaticString = #file,
                line: UInt = #line) throws -> T {
    guard let value = expression() else {
        throw RequireError<T>(file: file, line: line)
    }

    return value
}

private struct RequireError<Value>: LocalizedError {
    let file: StaticString
    let line: UInt

    var errorDescription: String? {
        return "Required value of type \(Value.self) was nil at line \(line) in \(file)."
    }
}
