/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Publish
import Foundation

@Suite("Website", .serialized) struct WebsiteTests: PublishTestCase {
    var website: WithoutItemMetadata = .init()

    @Test func testDefaultTagListPath() {
        #expect(WithoutItemMetadata().tagListPath == "tags")
    }

    @Test mutating func testCustomTagListPath() {
        website.tagHTMLConfig = TagHTMLConfiguration(basePath: "custom")
        #expect(website.tagListPath == "custom")
    }

    @Test func testPathForSectionID() {
        #expect(website.path(for: .one) == "one")
    }
    
    @Test func testPathForSectionIDWithRawValue() {
        #expect(website.path(for: .customRawValue) == "custom-raw-value")
    }

    @Test func testDefaultPathForTag() {
        let tag = Tag("some tag")
        #expect(website.path(for: tag) == "tags/some-tag")
    }

    @Test mutating func testCustomPathForTag() {
        website.tagHTMLConfig = TagHTMLConfiguration(basePath: "custom")
        let tag = Tag("some tag")
        #expect(website.path(for: tag) == "custom/some-tag")
    }

    @Test func testDefaultURLForTag() {
        #expect(
            website.url(for: Tag("some tag")) ==
            URL(string: "https://swiftbysundell.com/tags/some-tag")
        )
    }

    @Test mutating func testCustomURLForTag() {
        website.tagHTMLConfig = TagHTMLConfiguration(basePath: "custom")

        #expect(
            website.url(for: Tag("some tag")) ==
            URL(string: "https://swiftbysundell.com/custom/some-tag")
        )
    }

    @Test func testURLForRelativePath() {
        #expect(
            website.url(for: Path("a/path")) ==
            URL(string: "https://swiftbysundell.com/a/path")
        )
    }

    @Test func testURLForAbsolutePath() {
        #expect(
            website.url(for: Path("/a/path")) ==
            URL(string: "https://swiftbysundell.com/a/path")
        )
    }

    @Test func testURLForLocation() {
        let page = Page(path: "mypage", content: Content())

        #expect(
            website.url(for: page) ==
            URL(string: "https://swiftbysundell.com/mypage")
        )
    }
}
