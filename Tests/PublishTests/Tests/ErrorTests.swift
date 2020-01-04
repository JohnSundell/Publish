/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class ErrorTests: PublishTestCase {
    func testErrorForInvalidRootPath() throws {
        assertErrorThrown(
            try WebsiteStub.WithoutItemMetadata().publish(
                at: "🤷‍♂️",
                using: []
            ),
            PublishingError(
                path: "🤷‍♂️",
                infoMessage: "Could not find the requested root folder"
            )
        )
    }

    func testErrorForMissingMarkdownMetadata() throws {
        struct Metadata: WebsiteItemMetadata {
            let string: String
        }

        let markdown = """
        ---
        title: Hello
        ---
        """

        assertErrorThrown(
            try generateItem(
                withMetadataType: Metadata.self,
                in: .one,
                fromMarkdown: markdown,
                fileName: "file.md"
            ),
            PublishingError(
                stepName: "Add Markdown files from 'Content' folder",
                path: "one/file.md",
                infoMessage: "Missing metadata value for key 'string'"
            )
        )
    }

    func testErrorForInvalidMarkdownMetadata() throws {
        let markdown = """
        ---
        audio.url: 🤷‍♂️
        ---
        """

        assertErrorThrown(
            try generateItem(
                in: .one,
                fromMarkdown: markdown,
                fileName: "file.md"
            ),
            PublishingError(
                stepName: "Add Markdown files from 'Content' folder",
                path: "one/file.md",
                infoMessage: "Invalid metadata value for key 'audio.url'"
            )
        )
    }

    func testErrorForThrowingDuringItemMutation() throws {
        struct Error: LocalizedError {
            var errorDescription: String? { "An error" }
        }

        assertErrorThrown(
            try publishWebsite(using: [
                .addItem(.stub(withPath: "path/to/item")),
                .mutateAllItems { _ in
                    throw Error()
                }
            ]),
            PublishingError(
                stepName: "Mutate items",
                path: "one/path/to/item",
                infoMessage: "Item mutation failed",
                underlyingError: Error()
            )
        )
    }

    func testErrorForMissingPage() throws {
        assertErrorThrown(
            try publishWebsite(using: [
                .mutatePage(at: "invalid/path") { _ in }
            ]),
            PublishingError(
                stepName: "Mutate page at 'invalid/path'",
                path: "invalid/path",
                infoMessage: "Page not found"
            )
        )
    }

    func testErrorForThrowingDuringPageMutation() throws {
        struct Error: LocalizedError {
            var errorDescription: String? { "An error" }
        }

        assertErrorThrown(
            try publishWebsite(using: [
                .addPage(.stub(withPath: "page")),
                .mutateAllPages { _ in
                    throw Error()
                }
            ]),
            PublishingError(
                stepName: "Mutate all pages",
                path: "page",
                infoMessage: "Page mutation failed",
                underlyingError: Error()
            )
        )
    }

    func testErrorForMissingFolder() throws {
        assertErrorThrown(
            try publishWebsite(using: [
                .copyFiles(at: "non/existing")
            ]),
            PublishingError(
                stepName: "Copy 'non/existing' files",
                path: "non/existing",
                infoMessage: "Folder not found"
            )
        )
    }

    func testErrorForMissingFile() throws {
        assertErrorThrown(
            try publishWebsite(using: [
                .copyFile(at: "non/existing.png")
            ]),
            PublishingError(
                stepName: "Copy file 'non/existing.png'",
                path: "non/existing.png",
                infoMessage: "File not found"
            )
        )
    }

    func testErrorForNoPublishingSteps() throws {
        assertErrorThrown(
            try publishWebsite(using: []),
            PublishingError(
                infoMessage: "WebsiteName has no generation steps."
            )
        )

        CommandLine.arguments.append("--deploy")

        assertErrorThrown(
            try publishWebsite(using: []),
            PublishingError(
                infoMessage: "WebsiteName has no deployment steps."
            )
        )

        CommandLine.arguments.removeLast()
    }
}

extension ErrorTests {
    static var allTests: Linux.TestList<ErrorTests> {
        [
            ("testErrorForInvalidRootPath", testErrorForInvalidRootPath),
            ("testErrorForMissingMarkdownMetadata", testErrorForMissingMarkdownMetadata),
            ("testErrorForInvalidMarkdownMetadata", testErrorForInvalidMarkdownMetadata),
            ("testErrorForThrowingDuringItemMutation", testErrorForThrowingDuringItemMutation),
            ("testErrorForMissingPage", testErrorForMissingPage),
            ("testErrorForThrowingDuringPageMutation", testErrorForThrowingDuringPageMutation),
            ("testErrorForMissingFolder", testErrorForMissingFolder),
            ("testErrorForMissingFile", testErrorForMissingFile),
            ("testErrorForNoPublishingSteps", testErrorForNoPublishingSteps)
        ]
    }
}
