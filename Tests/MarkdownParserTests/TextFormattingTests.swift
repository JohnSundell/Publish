/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class TextFormattingTests: XCTestCase {
    func testParagraph() {
        let html = MarkdownParser().html(from: "Hello, world!")
        XCTAssertEqual(html, "<p>Hello, world!</p>")
    }

    func testParagraphs() {
        let html = MarkdownParser().html(from: "Hello, world!\n\nAgain.")
        XCTAssertEqual(html, "<p>Hello, world!</p><p>Again.</p>")
    }

    func xtestDosParagraphs() {
        let html = MarkdownParser().html(from: "Hello, world!\r\n\r\nAgain.")
        XCTAssertEqual(html, "<p>Hello, world!</p><p>Again.</p>")
    }

    func testItalicText() {
        let html = MarkdownParser().html(from: "Hello, *world*!")
        XCTAssertEqual(html, "<p>Hello, <em>world</em>!</p>")
    }

    func testBoldText() {
        let html = MarkdownParser().html(from: "Hello, **world**!")
        XCTAssertEqual(html, "<p>Hello, <strong>world</strong>!</p>")
    }

    func testItalicBoldText() {
        let html = MarkdownParser().html(from: "Hello, ***world***!")
        XCTAssertEqual(html, "<p>Hello, <em><strong>world</strong></em>!</p>")
    }

    func testItalicBoldTextWithSeparateStartMarkers() {
        let html = MarkdownParser().html(from: "**Hello, *world***!")
        XCTAssertEqual(html, "<p><strong>Hello, <em>world</em></strong>!</p>")
    }

    func testItalicTextWithinBoldText() {
        let html = MarkdownParser().html(from: "**Hello, *world*!**")
        XCTAssertEqual(html, "<p><strong>Hello, <em>world</em>!</strong></p>")
    }

    func testBoldTextWithinItalicText() {
        let html = MarkdownParser().html(from: "*Hello, **world**!*")
        XCTAssertEqual(html, "<p><em>Hello, <strong>world</strong>!</em></p>")
    }

    func testItalicTextWithExtraLeadingMarkers() {
        let html = MarkdownParser().html(from: "**Hello*")
        XCTAssertEqual(html, "<p>*<em>Hello</em></p>")
    }

    func testBoldTextWithExtraLeadingMarkers() {
        let html = MarkdownParser().html(from: "***Hello**")
        XCTAssertEqual(html, "<p>*<strong>Hello</strong></p>")
    }

    func testItalicTextWithExtraTrailingMarkers() {
        let html = MarkdownParser().html(from: "*Hello**")
        XCTAssertEqual(html, "<p><em>Hello</em>*</p>")
    }

    func testBoldTextWithExtraTrailingMarkers() {
        let html = MarkdownParser().html(from: "**Hello***")
        XCTAssertEqual(html, "<p><strong>Hello</strong>*</p>")
    }

    func testItalicBoldTextWithExtraTrailingMarkers() {
        let html = MarkdownParser().html(from: "**Hello, *world*****!")
        XCTAssertEqual(html, "<p><strong>Hello, <em>world</em></strong>**!</p>")
    }

    func testUnterminatedItalicMarker() {
        let html = MarkdownParser().html(from: "*Hello")
        XCTAssertEqual(html, "<p>*Hello</p>")
    }

    func testUnterminatedBoldMarker() {
        let html = MarkdownParser().html(from: "**Hello")
        XCTAssertEqual(html, "<p>**Hello</p>")
    }

    func testUnterminatedItalicBoldMarker() {
        let html = MarkdownParser().html(from: "***Hello")
        XCTAssertEqual(html, "<p>***Hello</p>")
    }

    func testUnterminatedItalicMarkerWithinBoldText() {
        let html = MarkdownParser().html(from: "**Hello, *world!**")
        XCTAssertEqual(html, "<p>*<em>Hello, <em>world!</em></em></p>")
    }

    func testUnterminatedBoldMarkerWithinItalicText() {
        let html = MarkdownParser().html(from: "*Hello, **world!*")
        XCTAssertEqual(html, "<p>*Hello, *<em>world!</em></p>")
    }

    func testStrikethroughText() {
        let html = MarkdownParser().html(from: "Hello, ~~world!~~")
        XCTAssertEqual(html, "<p>Hello, <s>world!</s></p>")
    }

    func testSingleTildeWithinStrikethroughText() {
        let html = MarkdownParser().html(from: "Hello, ~~wor~ld!~~")
        XCTAssertEqual(html, "<p>Hello, <s>wor~ld!</s></p>")
    }

    func testUnterminatedStrikethroughMarker() {
        let html = MarkdownParser().html(from: "~~Hello")
        XCTAssertEqual(html, "<p>~~Hello</p>")
    }

    func testEncodingSpecialCharacters() {
        let html = MarkdownParser().html(from: "Hello < World & >")
        XCTAssertEqual(html, "<p>Hello &lt; World &amp; &gt;</p>")
    }

    func testSingleLineBlockquote() {
        let html = MarkdownParser().html(from: "> Hello, world!")
        XCTAssertEqual(html, "<blockquote><p>Hello, world!</p></blockquote>")
    }

    func testMultiLineBlockquote() {
        let html = MarkdownParser().html(from: """
        > One
        > Two
        > Three
        """)

        XCTAssertEqual(html, "<blockquote><p>One Two Three</p></blockquote>")
    }

    func testEscapingSymbolsWithBackslash() {
        let html = MarkdownParser().html(from: """
        \\# Not a title
        \\*Not italic\\*
        """)

        XCTAssertEqual(html, "<p># Not a title *Not italic*</p>")
    }


    func testListAfterFormattedText() {
        let html = MarkdownParser().html(from: """
            This is a test
            - One
            - Two
            """)

        XCTAssertEqual(html, """
            <p>This is a test</p><ul><li>One</li><li>Two</li></ul>
            """)
    }

    func testDoubleSpacedHardLinebreak() {
        let html = MarkdownParser().html(from: "Line 1  \nLine 2")

        XCTAssertEqual(html, "<p>Line 1<br/>Line 2</p>")
    }

    func testEscapedHardLinebreak() {
        let html = MarkdownParser().html(from: "Line 1\\\nLine 2")

        XCTAssertEqual(html, "<p>Line 1<br/>Line 2</p>")
    }
}
