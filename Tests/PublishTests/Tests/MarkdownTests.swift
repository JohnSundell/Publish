/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Foundation
import Synchronization
import Files
import Publish

@Suite("Markdown", .serialized) struct MarkdownTests: PublishTestCase {
    @Test func testParsingFileWithTitle() throws {
        let item = try generateItem(fromMarkdown: "# Title")
        #expect(item.title ==  "Title")
    }

    @Test func testParsingFileWithOverriddenTitle() throws {
        let item = try generateItem(fromMarkdown: """
        ---
        title: Overridden title
        ---
        # Title
        """)

        #expect(item.title ==  "Overridden title")
    }

    @Test func testParsingFileWithNoTitle() throws {
        let item = try generateItem(fromMarkdown: """
        ---
        description: A description
        ---
        No title here
        """, fileName: "fallback.md")

        #expect(item.title ==  "fallback")
    }

    @Test func testParsingFileWithOverriddenPath() throws {
        let item = try generateItem(fromMarkdown: """
        ---
        path: overridden-path
        ---
        """)

        #expect(item.path ==  "one/overridden-path")
    }

    @Test func testParsingFileWithBuiltInMetadata() throws {
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

        #expect(item.description ==  "Description")
        #expect(item.tags ==  ["One", "Two", "Three"])
        #expect(item.imagePath ==  "myImage.png")
        #expect(item.date ==  expectedDateComponents.date)
        #expect(item.audio?.url ==  URL(string: "https://myFile.mp3"))
        #expect(item.audio?.duration ==  Audio.Duration(hours: 1, minutes: 3, seconds: 5))
        #expect(item.video ==  .youTube(id: "12345"))
    }

    @Test func testParsingFileWithCustomMetadata() throws {
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

        #expect(item.metadata.string ==  "Hello, world!")
        #expect(item.metadata.url ==  URL(string: "https://url.com"))
        #expect(item.metadata.int ==  42)
        #expect(item.metadata.double ==  3.14)
        #expect(item.metadata.stringArray ==  ["One", "Two", "Three"])
        #expect(item.metadata.urlArray ==  expectedURLs)
        #expect(item.metadata.intArray ==  [1, 2, 3])
        #expect(item.metadata.nested.string ==  "I'm nested!")
        #expect(item.metadata.nested.url ==  URL(string: "https://nested.url"))
    }

    @Test func testParsingPageInNestedFolder() throws {
        let folder = try Folder.createTemporary()
        let pageFile = try folder.createFile(at: "Content/my/custom/page.md")
        try pageFile.write("# MyPage")

        let site = try publishWebsite(in: folder, using: [
            .addMarkdownFiles()
        ])

        #expect(site.pages["my/custom/page"]?.title ==  "MyPage")
    }

    @Test func testNotParsingNonMarkdownFiles() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(at: "Content/image.png")
        try folder.createFile(at: "Content/one/image.png")
        try folder.createFile(at: "Content/custom/image.png")

        let site = try publishWebsite(in: folder, using: [
            .addMarkdownFiles()
        ])

        #expect(site.pages ==  [:])
        #expect(site.sections[.one].items ==  [])
    }
}
