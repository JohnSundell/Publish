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

        try publishWebsiteWithPodcast(in: folder, using: [
            .addMarkdownFiles(),
            .generatePodcastFeed(for: .one, config: makeConfigStub())
        ], content: [
            "one/a.md": """
            ---
            audio.url: https://audio.mp3
            audio.duration: 05:02
            audio.size: 12345
            ---
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

        try publishWebsiteWithPodcast(in: folder, using: [
            .addMarkdownFiles(),
            .generatePodcastFeed(for: .one, config: makeConfigStub())
        ], content: [
            "one/item.md": """
            ---
            audio.url: https://audio.mp3
            audio.duration: 05:02
            audio.size: 12345
            ---
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
}

extension PodcastFeedGenerationTests {
    static var allTests: Linux.TestList<PodcastFeedGenerationTests> {
        [
            ("testOnlyIncludingSpecifiedSection", testOnlyIncludingSpecifiedSection),
            ("testConvertingRelativeLinksToAbsolute", testConvertingRelativeLinksToAbsolute)
        ]
    }
}

private extension PodcastFeedGenerationTests {
    func makeConfigStub() throws -> PodcastFeedConfiguration<WebsiteStub.WithPodcastMetadata> {
        try PodcastFeedConfiguration(
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
}
