/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class HeadingTests: XCTestCase {
    func testHeading() {
        let html = MarkdownParser().html(from: "# Hello, world!")
        XCTAssertEqual(html, "<h1>Hello, world!</h1>")
    }

    func testHeadingsSeparatedBySingleNewline() {
        let html = MarkdownParser().html(from: "# Hello\n## World")
        XCTAssertEqual(html, "<h1>Hello</h1><h2>World</h2>")
    }

    func testHeadingsWithLeadingNumbers() {
        let html = MarkdownParser().html(from: """
        # 1. First
        ## 2. Second
        ## 3. Third
        ### 4. Forth
        """)

        XCTAssertEqual(html, """
        <h1>1. First</h1><h2>2. Second</h2><h2>3. Third</h2><h3>4. Forth</h3>
        """)
    }

    func testHeadingWithPreviousWhitespace() {
        let html = MarkdownParser().html(from: "Text \n## Heading")
        XCTAssertEqual(html, "<p>Text</p><h2>Heading</h2>")
    }

    func testHeadingWithPreviousNewlineAndWhitespace() {
        let html = MarkdownParser().html(from: "Hello\n \n## Heading\n\nWorld")
        XCTAssertEqual(html, "<p>Hello</p><h2>Heading</h2><p>World</p>")
    }

    func testInvalidHeaderLevel() {
        let markdown = String(repeating: "#", count: 7)
        let html = MarkdownParser().html(from: markdown)
        XCTAssertEqual(html, "<p>\(markdown)</p>")
    }

    func testRemovingTrailingMarkersFromHeading() {
        let markdown = "# Heading #######"
        let html = MarkdownParser().html(from: markdown)
        XCTAssertEqual(html, "<h1>Heading</h1>")
    }

    func testHeadingWithOnlyTrailingMarkers() {
        let markdown = "# #######"
        let html = MarkdownParser().html(from: markdown)
        XCTAssertEqual(html, "<h1></h1>")
    }
}
