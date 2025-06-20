/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class ListTests: XCTestCase {
    func testOrderedList() {
        let html = MarkdownParser().html(from: """
        1. One
        2. Two
        """)

        XCTAssertEqual(html, #"<ol><li>One</li><li>Two</li></ol>"#)
    }
    
    func test10DigitOrderedList() {
        let html = MarkdownParser().html(from: """
        1234567890. Not a list
        """)

        XCTAssertEqual(html, "<p>1234567890. Not a list</p>")
    }
    
    func testOrderedListParentheses() {
        let html = MarkdownParser().html(from: """
        1) One
        2) Two
        """)

        XCTAssertEqual(html, #"<ol><li>One</li><li>Two</li></ol>"#)
    }

    func testOrderedListWithoutIncrementedNumbers() {
        let html = MarkdownParser().html(from: """
        1. One
        3. Two
        17. Three
        """)

        XCTAssertEqual(html, "<ol><li>One</li><li>Two</li><li>Three</li></ol>")
    }

    func testOrderedListWithInvalidNumbers() {
        let html = MarkdownParser().html(from: """
        1. One
        3!. Two
        17. Three
        """)

        XCTAssertEqual(html, "<ol><li>One 3!. Two</li><li>Three</li></ol>")
    }

    func testUnorderedList() {
        let html = MarkdownParser().html(from: """
        - One
        - Two
        - Three
        """)

        XCTAssertEqual(html, "<ul><li>One</li><li>Two</li><li>Three</li></ul>")
    }
    
    func testMixedUnorderedList() {
        let html = MarkdownParser().html(from: """
        - One
        * Two
        * Three
        - Four
        """)

        XCTAssertEqual(html, "<ul><li>One</li></ul><ul><li>Two</li><li>Three</li></ul><ul><li>Four</li></ul>")
    }
    
    func testMixedList() {
        let html = MarkdownParser().html(from: """
        1. One
        2. Two
        3) Three
        * Four
        """)
        
        XCTAssertEqual(html, #"<ol><li>One</li><li>Two</li></ol><ol start="3"><li>Three</li></ol><ul><li>Four</li></ul>"#)
    }

    func testUnorderedListWithMultiLineItem() {
        let html = MarkdownParser().html(from: """
        - One
        Some text
        - Two
        """)

        XCTAssertEqual(html, "<ul><li>One Some text</li><li>Two</li></ul>")
    }

    func testUnorderedListWithNestedList() {
        let html = MarkdownParser().html(from: """
        - A
        - B
            - B1
                - B11
            - B2
        """)

        let expectedComponents: [String] = [
            "<ul>",
                "<li>A</li>",
                "<li>B",
                    "<ul>",
                        "<li>B1",
                            "<ul>",
                                "<li>B11</li>",
                            "</ul>",
                        "</li>",
                        "<li>B2</li>",
                    "</ul>",
                "</li>",
            "</ul>"
        ]

        XCTAssertEqual(html, expectedComponents.joined())
    }

    func testUnorderedListWithInvalidMarker() {
        let html = MarkdownParser().html(from: """
        - One
        -Two
        - Three
        """)

        XCTAssertEqual(html, "<ul><li>One -Two</li><li>Three</li></ul>")
    }
    
    func testOrderedIndentedList() {
        let html = MarkdownParser().html(from: """
          1. One
          2. Two
        """)

        XCTAssertEqual(html, #"<ol><li>One</li><li>Two</li></ol>"#)
    }
    
    func testUnorderedIndentedList() {
        let html = MarkdownParser().html(from: """
          - One
          - Two
          - Three
        """)

        XCTAssertEqual(html, "<ul><li>One</li><li>Two</li><li>Three</li></ul>")
    }
}
