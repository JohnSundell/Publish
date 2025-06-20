/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Publish
import Foundation

@Suite("Error", .serialized) struct ErrorTests: PublishTestCase {
    @Test func testErrorForInvalidRootPath() throws {
        #expect(throws: PublishingError(
            path: "🤷‍♂️",
            infoMessage: "Could not find the requested root folder"
        )) {
            try WithoutItemMetadata().publish(
                at: "🤷‍♂️",
                using: [],
                deploy: false
            )
        }
    }

    @Test func testErrorForMissingMarkdownMetadata() throws {
        struct Metadata: WebsiteItemMetadata {
            let string: String
        }

        let markdown = """
        ---
        title: Hello
        ---
        """

        #expect(
            throws: PublishingError(
                stepName: "Add Markdown files from 'Content' folder",
                path: "one/file.md",
                infoMessage: "Missing metadata value for key 'string'"
            )
        ) {
            try generateItem(
                withMetadataType: Metadata.self,
                in: .one,
                fromMarkdown: markdown,
                fileName: "file.md"
            )
        }
    }

    @Test func testErrorForInvalidMarkdownMetadata() throws {
        let markdown = """
        ---
        audio.url: 🤷‍♂️
        ---
        """
        #expect(
            throws: PublishingError(
                stepName: "Add Markdown files from 'Content' folder",
                path: "one/file.md",
                infoMessage: "Invalid metadata value for key 'audio.url'"
            )
        ) {
            try generateItem(
                in: .one,
                fromMarkdown: markdown,
                fileName: "file.md"
            )
        }
    }

    @Test func testErrorForThrowingDuringItemMutation() throws {
        struct Error: LocalizedError {
            var errorDescription: String? { "An error" }
        }

        #expect(throws: PublishingError(
            stepName: "Mutate all items",
            path: "one/path/to/item",
            infoMessage: "Item mutation failed",
            underlyingError: Error()
        )) {
            try publishWebsite(using: [
                .addItem(.stub(withPath: "path/to/item")),
                .mutateAllItems { _ in
                    throw Error()
                }
            ])
        }
    }

    @Test func testErrorForMissingPage() throws {
        #expect(throws: PublishingError(
            stepName: "Mutate page at 'invalid/path'",
            path: "invalid/path",
            infoMessage: "Page not found"
        )) {
            try publishWebsite(using: [
                .mutatePage(at: "invalid/path") { _ in }
            ])
        }
    }

    @Test func testErrorForThrowingDuringPageMutation() throws {
        struct Error: LocalizedError {
            var errorDescription: String? { "An error" }
        }

        #expect(throws: PublishingError(
            stepName: "Mutate all pages",
            path: "page",
            infoMessage: "Page mutation failed",
            underlyingError: Error()
        )) {
            try publishWebsite(using: [
                .addPage(.stub(withPath: "page")),
                .mutateAllPages { _ in
                    throw Error()
                }
            ])
        }
    }

    @Test func testErrorForMissingFolder() throws {
        #expect(throws: PublishingError(
            stepName: "Copy 'non/existing' files",
            path: "non/existing",
            infoMessage: "Folder not found"
        )) {
            try publishWebsite(using: [
                .copyFiles(at: "non/existing")
            ])
        }
    }

    @Test func testErrorForMissingFile() throws {
        #expect(throws: PublishingError(
            stepName: "Copy file 'non/existing.png'",
            path: "non/existing.png",
            infoMessage: "File not found"
        )) {
            try publishWebsite(using: [
                .copyFile(at: "non/existing.png")
            ])
        }
    }

    @Test func testErrorForNoPublishingSteps() throws {
        #expect(throws: PublishingError(
            infoMessage: "WebsiteName has no generation steps."
        )) {
            try publishWebsite(using: [])
        }

        #expect(throws: PublishingError(
            infoMessage: "WebsiteName has no deployment steps."
        )) {
            try publishWebsite(using: [], deploy: true)
        }
    }
}
