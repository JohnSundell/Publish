/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class ImageTests: XCTestCase {
    func testImageWithURL() {
        let html = MarkdownParser().html(from: "![](url)")
        XCTAssertEqual(html, #"<p><img src="url"/></p>"#)
    }

    func testImageWithReference() {
        let html = MarkdownParser().html(from: """
        ![][url]

        [url]: https://swiftbysundell.com
        """)

        XCTAssertEqual(html, #"<p><img src="https://swiftbysundell.com"/></p>"#)
    }

    func testImageWithURLAndAltText() {
        let html = MarkdownParser().html(from: "![Alt text](url)")
        XCTAssertEqual(html, #"<p><img src="url" alt="Alt text"/></p>"#)
    }

    func testImageWithReferenceAndAltText() {
        let html = MarkdownParser().html(from: """
        ![Alt text][url]
        
        [url]: swiftbysundell.com
        """)

        XCTAssertEqual(html, #"<p><img src="swiftbysundell.com" alt="Alt text"/></p>"#)
    }

    func testImageWithinParagraph() {
        let html = MarkdownParser().html(from: "Text ![](url) text")
        XCTAssertEqual(html, #"<p>Text <img src="url"/> text</p>"#)
    }
}
