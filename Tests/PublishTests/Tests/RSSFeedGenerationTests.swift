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

        try publishWebsite(in: folder, using: [
            .addMarkdownFiles(),
            .generateRSSFeed(
                including: [.one],
                config: RSSFeedConfiguration(targetPath: "feed.rss")
            )
        ], content: [
            "one/a.md": "Included",
            "two/b.md": "Not included"
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        XCTAssertTrue(feed.contains("Included"))
        XCTAssertFalse(feed.contains("Not included"))
    }

    func testConvertingRelativeLinksToAbsolute() throws {
        let folder = try Folder.createTemporary()

        try publishWebsite(in: folder, using: [
            .addMarkdownFiles(),
            .generateRSSFeed(
                including: [.one],
                config: RSSFeedConfiguration(targetPath: "feed.rss")
            )
        ], content: [
            "one/item.md": "BEGIN [Link](/page) ![Image](/image.png) [Link](https://apple.com) END"
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

extension RSSFeedGenerationTests {
    static var allTests: Linux.TestList<RSSFeedGenerationTests> {
        [
            ("testOnlyIncludingSpecifiedSections", testOnlyIncludingSpecifiedSections),
            ("testConvertingRelativeLinksToAbsolute", testConvertingRelativeLinksToAbsolute)
        ]
    }
}
