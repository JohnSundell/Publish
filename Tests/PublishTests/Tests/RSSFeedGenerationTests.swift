/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish
import Files
import Sweep

final class RSSFeedGenerationTests: PublishTestCase {
    func testOnlyIncludingSpecifiedSections() throws {
        let folder = try Folder.createTemporary()

        try generateFeed(in: folder, content: [
            "one/a.md": "Included",
            "two/b.md": "Not included"
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        XCTAssertTrue(feed.contains("Included"))
        XCTAssertFalse(feed.contains("Not included"))
    }

    func testConvertingRelativeLinksToAbsolute() throws {
        let folder = try Folder.createTemporary()

        try generateFeed(in: folder, content: [
            "one/item.md": """
            BEGIN [Link](/page) ![Image](/image.png) [Link](https://apple.com) END
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        let substring = feed.substrings(between: "BEGIN ", and: " END").first

        XCTAssertEqual(substring, """
        <a href="https://swiftbysundell.com/page">Link</a> \
        <img src=\"https://swiftbysundell.com/image.png\" alt=\"Image\"/> \
        <a href="https://apple.com">Link</a>
        """)
    }

    func testReusingPreviousFeedIfNoItemsWereModified() throws {
        let folder = try Folder.createTemporary()
        let contentFile = try folder.createFile(at: "Content/one/item.md")

        try generateFeed(in: folder)
        let feedA = try folder.file(at: "Output/feed.rss").readAsString()

        let newDate = Date().addingTimeInterval(60 * 60)
        try generateFeed(in: folder, date: newDate)
        let feedB = try folder.file(at: "Output/feed.rss").readAsString()

        XCTAssertEqual(feedA, feedB)

        try contentFile.append("New content")
        try generateFeed(in: folder, date: newDate)
        let feedC = try folder.file(at: "Output/feed.rss").readAsString()

        XCTAssertNotEqual(feedB, feedC)
    }

    func testNotReusingPreviousFeedIfConfigChanged() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(at: "Content/one/item.md")

        try generateFeed(in: folder)
        let feedA = try folder.file(at: "Output/feed.rss").readAsString()

        let newConfig = RSSFeedConfiguration(ttlInterval: 5000)
        let newDate = Date().addingTimeInterval(60 * 60)
        try generateFeed(in: folder, config: newConfig, date: newDate)
        let feedB = try folder.file(at: "Output/feed.rss").readAsString()

        XCTAssertNotEqual(feedA, feedB)
    }

    func testNotReusingPreviousFeedIfItemWasAdded() throws {
        let folder = try Folder.createTemporary()
        let itemA = Item.stub()
        let itemB = Item.stub().setting(\.lastModified, to: itemA.lastModified)

        try generateFeed(in: folder, generationSteps: [
            .addItem(itemA)
        ])

        let feedA = try folder.file(at: "Output/feed.rss").readAsString()

        try generateFeed(in: folder, generationSteps: [
            .addItem(itemA),
            .addItem(itemB)
        ])

        let feedB = try folder.file(at: "Output/feed.rss").readAsString()
        XCTAssertNotEqual(feedA, feedB)
    }
}

extension RSSFeedGenerationTests {
    static var allTests: Linux.TestList<RSSFeedGenerationTests> {
        [
            ("testOnlyIncludingSpecifiedSections", testOnlyIncludingSpecifiedSections),
            ("testConvertingRelativeLinksToAbsolute", testConvertingRelativeLinksToAbsolute),
            ("testReusingPreviousFeedIfNoItemsWereModified", testReusingPreviousFeedIfNoItemsWereModified),
            ("testNotReusingPreviousFeedIfConfigChanged", testNotReusingPreviousFeedIfConfigChanged),
            ("testNotReusingPreviousFeedIfItemWasAdded", testNotReusingPreviousFeedIfItemWasAdded)
        ]
    }
}

private extension RSSFeedGenerationTests {
    typealias Site = WebsiteStub.WithoutItemMetadata

    func generateFeed(
        in folder: Folder,
        config: RSSFeedConfiguration = .default,
        generationSteps: [PublishingStep<Site>] = [
            .addMarkdownFiles()
        ],
        date: Date = Date(),
        content: [Path : String] = [:]
    ) throws {
        try publishWebsite(in: folder, using: [
            .group(generationSteps),
            .generateRSSFeed(
                including: [.one],
                config: config,
                date: date
            )
        ], content: content)
    }
}
