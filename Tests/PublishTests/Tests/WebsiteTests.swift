/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class WebsiteTests: PublishTestCase {
    private var website: WebsiteStub.WithoutItemMetadata!

    override func setUp() {
        super.setUp()
        website = .init()
    }

    func testDefaultTagListPath() {
        XCTAssertEqual(website.tagListPath, "tags")
    }

    func testCustomTagListPath() {
        website.tagHTMLConfig = TagHTMLConfiguration(basePath: "custom")
        XCTAssertEqual(website.tagListPath, "custom")
    }

    func testPathForSectionID() {
        XCTAssertEqual(website.path(for: .one), "one")
    }
    
    func testPathForSectionIDWithRawValue() {
        XCTAssertEqual(website.path(for: .customRawValue), "custom-raw-value")
    }

    func testDefaultPathForTag() {
        let tag = Tag("some tag")
        XCTAssertEqual(website.path(for: tag), "tags/some-tag")
    }

    func testCustomPathForTag() {
        website.tagHTMLConfig = TagHTMLConfiguration(basePath: "custom")
        let tag = Tag("some tag")
        XCTAssertEqual(website.path(for: tag), "custom/some-tag")
    }

    func testDefaultURLForTag() {
        XCTAssertEqual(
            website.url(for: Tag("some tag")),
            URL(string: "https://swiftbysundell.com/tags/some-tag")
        )
    }

    func testCustomURLForTag() {
        website.tagHTMLConfig = TagHTMLConfiguration(basePath: "custom")

        XCTAssertEqual(
            website.url(for: Tag("some tag")),
            URL(string: "https://swiftbysundell.com/custom/some-tag")
        )
    }

    func testURLForRelativePath() {
        XCTAssertEqual(
            website.url(for: Path("a/path")),
            URL(string: "https://swiftbysundell.com/a/path")
        )
    }

    func testURLForAbsolutePath() {
        XCTAssertEqual(
            website.url(for: Path("/a/path")),
            URL(string: "https://swiftbysundell.com/a/path")
        )
    }

    func testURLForLocation() {
        let page = Page(path: "mypage", content: Content())

        XCTAssertEqual(
            website.url(for: page),
            URL(string: "https://swiftbysundell.com/mypage")
        )
    }
}

extension WebsiteTests {
    static var allTests: Linux.TestList<WebsiteTests> {
        [
            ("testDefaultTagListPath", testDefaultTagListPath),
            ("testCustomTagListPath", testCustomTagListPath),
            ("testPathForSectionID", testPathForSectionID),
            ("testPathForSectionIDWithRawValue", testPathForSectionIDWithRawValue),
            ("testDefaultPathForTag", testDefaultPathForTag),
            ("testCustomPathForTag", testCustomPathForTag),
            ("testDefaultURLForTag", testDefaultURLForTag),
            ("testCustomURLForTag", testCustomURLForTag),
            ("testURLForRelativePath", testURLForRelativePath),
            ("testURLForAbsolutePath", testURLForAbsolutePath),
            ("testURLForLocation", testURLForLocation)
        ]
    }
}
