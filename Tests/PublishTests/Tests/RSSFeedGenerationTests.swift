/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Synchronization
import Foundation
import Publish
import Files
import Sweep

@Suite("RSSFeedGeneration", .serialized) struct RSSFeedGenerationTests: PublishTestCase {
    @Test func testOnlyIncludingSpecifiedSections() throws {
        let folder = try Folder.createTemporary()

        try generateFeed(in: folder, content: [
            "one/a.md": "Included",
            "two/b.md": "Not included"
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        #expect(feed.contains("Included"))
        #expect(!feed.contains("Not included"))
    }

    @Test func testOnlyIncludingItemsMatchingPredicate() throws {
        let folder = try Folder.createTemporary()

        try generateFeed(
            in: folder,
            itemPredicate: \.path == "one/a",
            content: [
                "one/a.md": "Included",
                "one/b.md": "Not included"
            ]
        )

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        #expect(feed.contains("Included"))
        #expect(!feed.contains("Not included"))
    }

    @Test func testConvertingRelativeLinksToAbsolute() throws {
        let folder = try Folder.createTemporary()

        try generateFeed(in: folder, content: [
            "one/item.md": """
            BEGIN [Link](/page) ![Image](/image.png) [Link](https://apple.com) END
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        let substring = feed.firstSubstring(between: "BEGIN ", and: " END")

        #expect(substring ==  """
        <a href="https://swiftbysundell.com/page">Link</a> \
        <img src=\"https://swiftbysundell.com/image.png\" alt=\"Image\"/> \
        <a href="https://apple.com">Link</a>
        """)
    }

    @Test func testItemTitlePrefixAndSuffix() throws {
        let folder = try Folder.createTemporary()

        try generateFeed(in: folder, content: [
            "one/item.md": """
            ---
            rss.titlePrefix: Prefix
            rss.titleSuffix: Suffix
            ---
            # Title
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        #expect(feed.contains("<title>PrefixTitleSuffix</title>"))
    }

    @Test func testItemBodyPrefixAndSuffix() throws {
        let folder = try Folder.createTemporary()

        try generateFeed(in: folder, content: [
            "one/item.md": """
            ---
            rss.bodyPrefix: Prefix
            rss.bodySuffix: Suffix
            ---
            Body
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()

        #expect(feed.contains("""
        <content:encoded><![CDATA[Prefix<p>Body</p>Suffix]]></content:encoded>
        """))
    }

    @Test func testCustomItemLink() throws {
        let folder = try Folder.createTemporary()

        try generateFeed(in: folder, content: [
            "one/item.md": """
            ---
            rss.link: custom.link
            ---
            Body
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()

        #expect(feed.contains("<link>custom.link</link>"))

        #expect(feed.contains("""
        <guid isPermaLink="false">https://swiftbysundell.com/one/item</guid>
        """))
    }

    @Test func testReusingPreviousFeedIfNoItemsWereModified() throws {
        let folder = try Folder.createTemporary()
        let contentFile = try folder.createFile(at: "Content/one/item.md")

        try generateFeed(in: folder)
        let feedA = try folder.file(at: "Output/feed.rss").readAsString()

        let newDate = Date().addingTimeInterval(60 * 60)
        try generateFeed(in: folder, date: newDate)
        let feedB = try folder.file(at: "Output/feed.rss").readAsString()

        #expect(feedA ==  feedB)

        try contentFile.append("New content")
        try generateFeed(in: folder, date: newDate)
        let feedC = try folder.file(at: "Output/feed.rss").readAsString()

        #expect(feedB != feedC)
    }

    @Test func testNotReusingPreviousFeedIfConfigChanged() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(at: "Content/one/item.md")

        try generateFeed(in: folder)
        let feedA = try folder.file(at: "Output/feed.rss").readAsString()

        let newConfig = RSSFeedConfiguration(ttlInterval: 5000)
        let newDate = Date().addingTimeInterval(60 * 60)
        try generateFeed(in: folder, config: newConfig, date: newDate)
        let feedB = try folder.file(at: "Output/feed.rss").readAsString()

        #expect(feedA != feedB)
    }

    @Test func testNotReusingPreviousFeedIfItemWasAdded() throws {
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
        #expect(feedA != feedB)
    }
}

private extension RSSFeedGenerationTests {
    typealias Site = WithoutItemMetadata

    func generateFeed(
        in folder: Folder,
        config: RSSFeedConfiguration = .default,
        itemPredicate: Publish.Predicate<Item<Site>>? = nil,
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
                itemPredicate: itemPredicate,
                config: config,
                date: date
            )
        ], content: content)
    }
}
