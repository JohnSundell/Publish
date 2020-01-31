/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Files
import Ink
import Publish

final class MarkdownTests: PublishTestCase {
    func testParsingFileWithTitle() throws {
        let item = try generateItem(fromMarkdown: "# Title")
        XCTAssertEqual(item.title, "Title")
    }

    func testParsingFileWithOverriddenTitle() throws {
        let item = try generateItem(fromMarkdown: """
        ---
        title: Overridden title
        ---
        # Title
        """)

        XCTAssertEqual(item.title, "Overridden title")
    }

    func testParsingFileWithNoTitle() throws {
        let item = try generateItem(fromMarkdown: """
        ---
        description: A description
        ---
        No title here
        """, fileName: "fallback.md")

        XCTAssertEqual(item.title, "fallback")
    }

    func testParsingFileWithOverriddenPath() throws {
        let item = try generateItem(fromMarkdown: """
        ---
        path: overridden-path
        ---
        """)

        XCTAssertEqual(item.path, "one/overridden-path")
    }

    func testParsingFileWithBuiltInMetadata() throws {
        let item = try generateItem(fromMarkdown: """
        ---
        description: Description
        tags: One, Two, Three
        image: myImage.png
        date: 2019-12-14 10:30
        audio.url: https://myFile.mp3
        audio.duration: 01:03:05
        video.youTube: 12345
        ---
        """)

        var expectedDateComponents = DateComponents()
        expectedDateComponents.calendar = .autoupdatingCurrent
        expectedDateComponents.year = 2019
        expectedDateComponents.month = 12
        expectedDateComponents.day = 14
        expectedDateComponents.hour = 10
        expectedDateComponents.minute = 30

        XCTAssertEqual(item.description, "Description")
        XCTAssertEqual(item.tags, ["One", "Two", "Three"])
        XCTAssertEqual(item.imagePath, "myImage.png")
        XCTAssertEqual(item.date, expectedDateComponents.date)
        XCTAssertEqual(item.audio?.url, URL(string: "https://myFile.mp3"))
        XCTAssertEqual(item.audio?.duration, Audio.Duration(hours: 1, minutes: 3, seconds: 5))
        XCTAssertEqual(item.video, .youTube(id: "12345"))
    }

    func testParsingFileWithCustomMetadata() throws {
        struct Metadata: WebsiteItemMetadata {
            struct Nested: WebsiteItemMetadata {
                var string: String
                var url: URL
            }

            var string: String
            var url: URL
            var int: Int
            var double: Double
            var stringArray: [String]
            var urlArray: [URL]
            var intArray: [Int]
            var nested: Nested
        }

        let item = try generateItem(
            withMetadataType: Metadata.self,
            fromMarkdown: """
            ---
            string: Hello, world!
            url: https://url.com
            int: 42
            double: 3.14
            stringArray: One, Two, Three
            urlArray: https://a.url, https://b.url
            intArray: 1, 2, 3
            nested.string: I'm nested!
            nested.url: https://nested.url
            ---
            """
        )

        let expectedURLs = ["https://a.url", "https://b.url"].compactMap(URL.init)

        XCTAssertEqual(item.metadata.string, "Hello, world!")
        XCTAssertEqual(item.metadata.url, URL(string: "https://url.com"))
        XCTAssertEqual(item.metadata.int, 42)
        XCTAssertEqual(item.metadata.double, 3.14)
        XCTAssertEqual(item.metadata.stringArray, ["One", "Two", "Three"])
        XCTAssertEqual(item.metadata.urlArray, expectedURLs)
        XCTAssertEqual(item.metadata.intArray, [1, 2, 3])
        XCTAssertEqual(item.metadata.nested.string, "I'm nested!")
        XCTAssertEqual(item.metadata.nested.url, URL(string: "https://nested.url"))
    }

    func testParsingPageInNestedFolder() throws {
        let folder = try Folder.createTemporary()
        let pageFile = try folder.createFile(at: "Content/my/custom/page.md")
        try pageFile.write("# MyPage")

        let site = try publishWebsite(in: folder, using: [
            .addMarkdownFiles()
        ])

        XCTAssertEqual(site.pages["my/custom/page"]?.title, "MyPage")
    }

    func testNotParsingNonMarkdownFiles() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(at: "Content/image.png")
        try folder.createFile(at: "Content/one/image.png")
        try folder.createFile(at: "Content/custom/image.png")

        let site = try publishWebsite(in: folder, using: [
            .addMarkdownFiles()
        ])

        XCTAssertEqual(site.pages, [:])
        XCTAssertEqual(site.sections[.one].items, [])
    }
}

extension MarkdownTests {
    static var allTests: Linux.TestList<MarkdownTests> {
        [
            ("testParsingFileWithTitle", testParsingFileWithTitle),
            ("testParsingFileWithOverriddenTitle", testParsingFileWithOverriddenTitle),
            ("testParsingFileWithNoTitle", testParsingFileWithNoTitle),
            ("testParsingFileWithOverriddenPath", testParsingFileWithOverriddenPath),
            ("testParsingFileWithBuiltInMetadata", testParsingFileWithBuiltInMetadata),
            ("testParsingFileWithCustomMetadata", testParsingFileWithCustomMetadata),
            ("testParsingPageInNestedFolder", testParsingPageInNestedFolder),
            ("testNotParsingNonMarkdownFiles", testNotParsingNonMarkdownFiles)
        ]
    }
}
