/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish
import Plot
import Files

class PublishTestCase: XCTestCase {
    @discardableResult
    func publishWebsite(
        in folder: Folder? = nil,
        using steps: [PublishingStep<WebsiteStub.WithoutMetadata>],
        content: [Path : String] = [:]
    ) throws -> PublishedWebsite<WebsiteStub.WithoutMetadata> {
        try performWebsitePublishing(
            in: folder,
            using: steps,
            files: content,
            filePathPrefix: "Content/"
        )
    }

    func publishWebsite(
        _ site: WebsiteStub.WithoutMetadata = .init(),
        in folder: Folder? = nil,
        using theme: Theme<WebsiteStub.WithoutMetadata>,
        content: [Path : String] = [:],
        additionalSteps: [PublishingStep<WebsiteStub.WithoutMetadata>] = [],
        plugins: [Plugin<WebsiteStub.WithoutMetadata>] = [],
        expectedHTML: [Path : String],
        allowWhitelistedOutputFiles: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let folder = try folder ?? Folder.createTemporary()

        let contentFolderName = "Content"
        try? folder.subfolder(named: contentFolderName).delete()

        let contentFolder = try folder.createSubfolder(named: contentFolderName)
        try addFiles(withContent: content, to: contentFolder, pathPrefix: "")

        try site.publish(
            withTheme: theme,
            at: Path(folder.path),
            rssFeedSections: [],
            additionalSteps: additionalSteps,
            plugins: plugins
        )

        try verifyOutput(
            in: folder,
            expectedHTML: expectedHTML,
            allowWhitelistedFiles: allowWhitelistedOutputFiles,
            file: file,
            line: line
        )
    }

    func publishWebsiteWithPodcast(
        in folder: Folder? = nil,
        using steps: [PublishingStep<WebsiteStub.WithPodcastMetadata>],
        content: [Path : String] = [:],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        try performWebsitePublishing(
            in: folder,
            using: steps,
            files: content,
            filePathPrefix: "Content/"
        )
    }

    func verifyOutput(in folder: Folder,
                      expectedHTML: [Path : String],
                      allowWhitelistedFiles: Bool = true,
                      file: StaticString = #file,
                      line: UInt = #line) throws {
        let outputFolder = try folder.subfolder(named: "Output")

        let whitelistedPaths: Set<Path> = [
            "index.html",
            "one/index.html",
            "two/index.html",
            "three/index.html",
            "custom-raw-value/index.html",
            "tags/index.html"
        ]

        var expectedHTML = expectedHTML.mapValues { html in
            HTML(.body(.raw(html))).render()
        }

        for outputFile in outputFolder.files.recursive where outputFile.extension == "html" {
            let relativePath = Path(outputFile.path(relativeTo: outputFolder))

            guard let html = expectedHTML.removeValue(forKey: relativePath) else {
                guard allowWhitelistedFiles,
                      whitelistedPaths.contains(relativePath) else {
                    return XCTFail(
                        "Unexpected output file: \(relativePath)",
                        file: file,
                        line: line
                    )
                }

                continue
            }

            let outputHTML = try outputFile.readAsString()

            XCTAssert(
                outputHTML == html,
                "HTML mismatch. '\(outputHTML)' is not equal to '\(html)'.",
                file: file,
                line: line
            )
        }

        let missingPaths = expectedHTML.keys.map { $0.string }

        XCTAssert(
            missingPaths.isEmpty,
            "Missing output files: \(missingPaths.joined(separator: ", "))",
            file: file,
            line: line
        )
    }

    @discardableResult
    func publishWebsite<IT: WebsiteItemMetadata, PT: WebsitePageMetadata>(
        withItemMetadataType itemMetadataType: IT.Type,
        pageMetadataType: PT.Type,
        using steps: [PublishingStep<WebsiteStub.WithItemMetadata<IT, PT>>],
        content: [Path : String] = [:]
    ) throws -> PublishedWebsite<WebsiteStub.WithItemMetadata<IT, PT>> {
        try performWebsitePublishing(
            using: steps,
            files: content,
            filePathPrefix: "Content/"
        )
    }

    func generateItem(
        in section: WebsiteStub.SectionID = .one,
        fromMarkdown markdown: String,
        fileName: String = "markdown.md"
    ) throws -> Item<WebsiteStub.WithoutMetadata> {
        let site = try publishWebsite(
            using: [
                .addMarkdownFiles()
            ],
            content: [
                "\(section.rawValue)/\(fileName)" : markdown
            ]
        )

        return try require(site.sections[section].items.first)
    }
    
    struct EmptyPageMetadata: WebsitePageMetadata {}
    func generateItem<IT: WebsiteItemMetadata>(
        withMetadataType metadataType: IT.Type,
        in section: WebsiteStub.SectionID = .one,
        fromMarkdown markdown: String,
        fileName: String = "markdown.md"
    ) throws -> Item<WebsiteStub.WithItemMetadata<IT, EmptyPageMetadata>> {
        let site = try publishWebsite(
            withItemMetadataType: IT.self,
            pageMetadataType: EmptyPageMetadata.self,
            using: [
                .addMarkdownFiles()
            ],
            content: [
                "\(section.rawValue)/\(fileName)" : markdown
            ]
        )

        return try require(site.sections[section].items.first)
    }
}

private extension PublishTestCase {
    func addFiles(withContent fileContent: [Path : String],
                  to folder: Folder,
                  pathPrefix: String) throws {
        for (path, content) in fileContent {
            let path = pathPrefix + path.string
            try folder.createFile(at: path).write(content)
        }
    }

    @discardableResult
    func performWebsitePublishing<T: WebsiteStub>(
        in folder: Folder? = nil,
        using steps: [PublishingStep<T>],
        files: [Path : String],
        filePathPrefix: String = ""
    ) throws -> PublishedWebsite<T> {
        let folder = try folder ?? Folder.createTemporary()

        try addFiles(withContent: files, to: folder, pathPrefix: filePathPrefix)

        return try T().publish(
            at: Path(folder.path),
            using: steps
        )
    }
}
