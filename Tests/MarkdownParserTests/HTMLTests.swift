/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class HTMLTests: XCTestCase {
    func testTopLevelHTML() {
        let html = MarkdownParser().html(from: """
        Hello

        <div>
            <span class="text">Whole wide</span>
        </div>

        World
        """)

        XCTAssertEqual(html, """
        <p>Hello</p><div>
            <span class="text">Whole wide</span>
        </div>
        <p>World</p>
        """)
    }

    func testNestedTopLevelHTML() {
        let html = MarkdownParser().html(from: """
        <div>
            <div>Hello</div>
            <div>World</div>
        </div>
        """)

        XCTAssertEqual(html, """
        <div>
            <div>Hello</div>
            <div>World</div>
        </div>

        """)
    }

    func testTopLevelHTMLWithPreviousNewline() {
        let html = MarkdownParser().html(from: "Text\n<h2>Heading</h2>")
        XCTAssertEqual(html, "<p>Text</p><h2>Heading</h2>\n")
    }

    func testIgnoringFormattingWithinTopLevelHTML() {
        let html = MarkdownParser().html(from: "<div>_Hello_</div>")
        XCTAssertEqual(html, "<div>_Hello_</div>\n")
    }

    func testTextFormattingWithinInlineHTML() {
        let html = MarkdownParser().html(from: "Hello <span>_World_</span>")
        XCTAssertEqual(html, "<p>Hello <span><em>World</em></span></p>")
    }

    func testIgnoringListsWithinInlineHTML() {
        let html = MarkdownParser().html(from: "<h2>1. Hello</h2><h2>- World</h2>")
        XCTAssertEqual(html, "<h2>1. Hello</h2><h2>- World</h2>\n")
    }

    func testInlineParagraphTagEndingCurrentParagraph() {
        let html = MarkdownParser().html(from: "One <p>Two</p> Three")
        XCTAssertEqual(html, "<p>One <p>Two</p> Three</p>")
    }

    func testTopLevelSelfClosingHTMLElement() {
        let html = MarkdownParser().html(from: """
        Hello

        <img src="image.png"/>

        World
        """)

        XCTAssertEqual(html, "<p>Hello</p><img src=\"image.png\"/>\n<p>World</p>")
    }

    func testInlineSelfClosingHTMLElement() {
        let html = MarkdownParser().html(from: #"Hello <img src="image.png"/> World"#)
        XCTAssertEqual(html, #"<p>Hello <img src="image.png"/> World</p>"#)
    }

    func testTopLevelHTMLLineBreak() {
        let html = MarkdownParser().html(from: """
        Hello
        <br/>
        World
        """)

        XCTAssertEqual(html, "<p>Hello <br/> World</p>")
    }

    func testHTMLComment() {
        let html = MarkdownParser().html(from: """
        Hello
        <!-- Comment -->
        World
        """)

        XCTAssertEqual(html, "<p>Hello</p><!-- Comment -->\n<p>World</p>")
    }

    func testHTMLEntities() {
        let html = MarkdownParser().html(from: """
        Hello &amp; welcome to &lt;Ink&gt;
        """)

        XCTAssertEqual(html, "<p>Hello &amp; welcome to &lt;Ink&gt;</p>")
    }
}
