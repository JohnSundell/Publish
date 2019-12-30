/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest

func assertErrorThrown<T, E: Error & Equatable>(
    _ expression: @autoclosure () throws -> T,
    _ expectedError: @autoclosure () -> E,
    file: StaticString = #file,
    line: UInt = #line
) {
    do {
        _ = try expression()
        XCTFail(
            "Expected an error to be thrown",
            file: file,
            line: line
        )
    } catch let error as E {
        XCTAssertEqual(
            error,
            expectedError(),
            file: file,
            line: line
        )
    } catch {
        XCTFail(
            "Unexpected error thrown: \(error)",
            file: file,
            line: line
        )
    }
}
