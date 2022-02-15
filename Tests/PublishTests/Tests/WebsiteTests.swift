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
    
    func testIgnorePatterns() {
        XCTAssertTrue(website.shouldIgnore(name: "templates"))
        XCTAssertFalse(website.shouldIgnore(name: "templates1"))
        XCTAssertFalse(website.shouldIgnore(name: "@templates"))
        
        XCTAssertTrue(website.shouldIgnore(name: "skip-this-file.md"))
        XCTAssertTrue(website.shouldIgnore(name: "skip-this-file-too.png"))
        XCTAssertTrue(website.shouldIgnore(name: "skip-this-file"))
        XCTAssertFalse(website.shouldIgnore(name: "dont-skip-this-file"))

        XCTAssertTrue(website.shouldIgnore(name: "notes"))
        XCTAssertFalse(website.shouldIgnore(name: "notes1"))

        XCTAssertTrue(website.shouldIgnore(name: "batter"))
        XCTAssertTrue(website.shouldIgnore(name: "butter"))
        XCTAssertFalse(website.shouldIgnore(name: "butter1"))
        
        XCTAssertTrue(website.shouldIgnore(name: "lisp"))
        XCTAssertTrue(website.shouldIgnore(name: "lip"))
        XCTAssertTrue(website.shouldIgnore(name: "lp"))
        XCTAssertTrue(website.shouldIgnore(name: "l1234567890p"))
        XCTAssertFalse(website.shouldIgnore(name: "lisp-too"))
    }
}

extension Website {
    var ignoredPaths: [String]? { [
        "templates", // Should only match the exact string
        "skip-this-file.*", // Should match anyhing starting with "skip-this-file" and 0 or more chars after that
        "^notes$", // Should match "notes" exactly and nothing else. Included because `shouldIgnore` adds a "^" and "$", which should not be affected by including those in the pattern.
        "b.tter",
        "l.*p"
    ] }
}

