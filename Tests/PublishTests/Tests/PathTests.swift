/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Foundation
import Synchronization
import Publish
import Codextended

@Suite("Path", .serialized) struct PathTests: PublishTestCase {
    @Test func testAbsoluteString() {
        #expect(Path("relative").absoluteString ==  "/relative")
        #expect(Path("/absolute").absoluteString ==  "/absolute")
    }

    @Test func testAppendingComponent() {
        let path = Path("one")
        #expect(path.appendingComponent("two") ==  "one/two")
    }

    @Test func testStringInterpolation() {
        let path = Path("my/path")
        #expect("\(path)" ==  "my/path")
    }

    @Test func testCoding() throws {
        struct Wrapper: Equatable, Codable {
            let path: Path
        }

        let wrapper = Wrapper(path: Path("my/path"))
        let data = try wrapper.encoded()
        #expect(try wrapper == data.decoded())
    }
}
