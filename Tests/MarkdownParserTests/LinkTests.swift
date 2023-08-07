/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class LinkTests: XCTestCase {
    func testLinkWithURL() {
        let html = MarkdownParser().html(from: "[Title](url)")
        XCTAssertEqual(html, #"<p><a href="url">Title</a></p>"#)
    }

    func testLinkWithReference() {
        let html = MarkdownParser().html(from: """
        [Title][url]

        [url]: swiftbysundell.com
        """)

        XCTAssertEqual(html, #"<p><a href="swiftbysundell.com">Title</a></p>"#)
    }

    func testCaseMismatchedLinkWithReference() {
        let html = MarkdownParser().html(from: """
        [Title][Foo]
        [Title][αγω]

        [FOO]: /url
        [ΑΓΩ]: /φου
        """)

        XCTAssertEqual(html, #"<p><a href="/url">Title</a> <a href="/φου">Title</a></p>"#)
    }

    func testNumericLinkWithReference() {
        let html = MarkdownParser().html(from: """
        [1][1]

        [1]: swiftbysundell.com
        """)

        XCTAssertEqual(html, #"<p><a href="swiftbysundell.com">1</a></p>"#)
    }

    func testBoldLinkWithInternalMarkers() {
        let html = MarkdownParser().html(from: "[**Hello**](/hello)")
        XCTAssertEqual(html, #"<p><a href="/hello"><strong>Hello</strong></a></p>"#)
    }

    func testBoldLinkWithExternalMarkers() {
        let html = MarkdownParser().html(from: "**[Hello](/hello)**")
        XCTAssertEqual(html, #"<p><strong><a href="/hello">Hello</a></strong></p>"#)
    }

    func testLinkWithUnderscores() {
        let html = MarkdownParser().html(from: "[He_llo](/he_llo)")
        XCTAssertEqual(html, "<p><a href=\"/he_llo\">He_llo</a></p>")
    }

    func testLinkWithParenthesis() {
        let html = MarkdownParser().html(from: "[Hello](/(hello))")
        XCTAssertEqual(html, "<p><a href=\"/(hello)\">Hello</a></p>")
    }

    func testLinkWithNestedParenthesis() {
        let html = MarkdownParser().html(from: "[Hello](/(h(e(l(l(o()))))))")
        XCTAssertEqual(html, "<p><a href=\"/(h(e(l(l(o())))))\">Hello</a></p>")
    }

    func testLinkWithParenthesisAndClosingParenthesisInContent() {
        let html = MarkdownParser().html(from: "[Hello](/(hello)))")
        XCTAssertEqual(html, "<p><a href=\"/(hello)\">Hello</a>)</p>")
    }

    func testUnterminatedLink() {
        let html = MarkdownParser().html(from: "[Hello]")
        XCTAssertEqual(html, "<p>[Hello]</p>")
    }
    
    func testLinkWithEscapedSquareBrackets() {
        let html = MarkdownParser().html(from: "[\\[Hello\\]](hello)")
        XCTAssertEqual(html, #"<p><a href="hello">[Hello]</a></p>"#)
    }
}
