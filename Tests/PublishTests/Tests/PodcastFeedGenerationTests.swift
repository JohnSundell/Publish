/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish
import Files

final class PodcastFeedGenerationTests: PublishTestCase {
    func testOnlyIncludingSpecifiedSection() throws {
        let folder = try Folder.createTemporary()

        try generateFeed(in: folder, content: [
            "one/a.md": """
            \(makeStubbedAudioMetadata())
            # Included
            """,
            "two/b": "# Not included"
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        XCTAssertTrue(feed.contains("Included"))
        XCTAssertFalse(feed.contains("Not included"))
    }

    func testConvertingRelativeLinksToAbsolute() throws {
        let folder = try Folder.createTemporary()

        try generateFeed(in: folder, content: [
            "one/item.md": """
            \(makeStubbedAudioMetadata())
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
        try contentFile.write(makeStubbedAudioMetadata())

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
        let contentFile = try folder.createFile(at: "Content/one/item.md")
        try contentFile.write(makeStubbedAudioMetadata())

        try generateFeed(in: folder)
        let feedA = try folder.file(at: "Output/feed.rss").readAsString()

        var newConfig = try makeConfigStub()
        newConfig.author.name = "New author name"
        let newDate = Date().addingTimeInterval(60 * 60)
        try generateFeed(in: folder, config: newConfig, date: newDate)
        let feedB = try folder.file(at: "Output/feed.rss").readAsString()

        XCTAssertNotEqual(feedA, feedB)
    }
}

extension PodcastFeedGenerationTests {
    static var allTests: Linux.TestList<PodcastFeedGenerationTests> {
        [
            ("testOnlyIncludingSpecifiedSection", testOnlyIncludingSpecifiedSection),
            ("testConvertingRelativeLinksToAbsolute", testConvertingRelativeLinksToAbsolute),
            ("testReusingPreviousFeedIfNoItemsWereModified", testReusingPreviousFeedIfNoItemsWereModified),
            ("testNotReusingPreviousFeedIfConfigChanged", testNotReusingPreviousFeedIfConfigChanged)
        ]
    }
}

private extension PodcastFeedGenerationTests {
    typealias Configuration = PodcastFeedConfiguration<WebsiteStub.WithPodcastMetadata>

    func makeConfigStub() throws -> Configuration {
        try Configuration(
            targetPath: .defaultForRSSFeed,
            imageURL: require(URL(string: "image.png")),
            copyrightText: "John Appleseed 2019",
            author: PodcastAuthor(
                name: "John Appleseed",
                emailAddress: "john.appleseed@apple.com"
            ),
            description: "Description",
            subtitle: "Subtitle",
            category: "Category"
        )
    }

    func makeStubbedAudioMetadata() -> String {
        """
        ---
        audio.url: https://audio.mp3
        audio.duration: 05:02
        audio.size: 12345
        ---
        """
    }

    func generateFeed(in folder: Folder,
                      config: Configuration? = nil,
                      date: Date = Date(),
                      content: [Path : String] = [:]) throws {
        try publishWebsiteWithPodcast(in: folder, using: [
            .addMarkdownFiles(),
            .generatePodcastFeed(
                for: .one,
                config: config ?? makeConfigStub(),
                date: date
            )
        ], content: content)
    }
}
