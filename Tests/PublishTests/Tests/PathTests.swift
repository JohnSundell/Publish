/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish
import Codextended

final class PathTests: PublishTestCase {
    func testAbsoluteString() {
        XCTAssertEqual(Path("relative").absoluteString, "/relative")
        XCTAssertEqual(Path("/absolute").absoluteString, "/absolute")
    }

    func testAppendingComponent() {
        let path = Path("one")
        XCTAssertEqual(path.appendingComponent("two"), "one/two")
    }

    func testStringInterpolation() {
        let path = Path("my/path")
        XCTAssertEqual("\(path)", "my/path")
    }

    func testCoding() throws {
        struct Wrapper: Equatable, Codable {
            let path: Path
        }

        let wrapper = Wrapper(path: Path("my/path"))
        let data = try wrapper.encoded()
        XCTAssertEqual(wrapper, try data.decoded())
    }
}

extension PathTests {
    static var allTests: Linux.TestList<PathTests> {
        [
            ("testAbsoluteString", testAbsoluteString),
            ("testAppendingComponent", testAppendingComponent),
            ("testStringInterpolation", testStringInterpolation),
            ("testCoding", testCoding)
        ]
    }
}
