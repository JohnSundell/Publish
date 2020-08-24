/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Ink
import Files
import Codextended

internal struct MarkdownContentFactory<Site: Website> {
    let parser: MarkdownParser
    let dateFormatter: DateFormatter

    func makeContent(fromFile file: File) throws -> Content {
        let markdown = try parser.parse(file.readAsString())
        let decoder = makeMetadataDecoder(for: markdown)
        return try makeContent(fromMarkdown: markdown, file: file, decoder: decoder)
    }

    func makeItem(fromFile file: File,
                  at path: Path,
                  sectionID: Site.SectionID) throws -> Item<Site> {
        let markdown = try parser.parse(file.readAsString())
        let decoder = makeMetadataDecoder(for: markdown)

        let metadata = try Site.ItemMetadata(from: decoder)
        let path = try decoder.decodeIfPresent("path", as: Path.self) ?? path
        let tags = try decoder.decodeIfPresent("tags", as: [Tag].self)
        let content = try makeContent(fromMarkdown: markdown, file: file, decoder: decoder)
        let rssProperties = try decoder.decodeIfPresent("rss", as: ItemRSSProperties.self)

        return Item(
            path: path,
            sectionID: sectionID,
            metadata: metadata,
            tags: tags ?? [],
            content: content,
            rssProperties: rssProperties ?? .init()
        )
    }

    func makePage(fromFile file: File, at path: Path) throws -> Page {
        let markdown = try parser.parse(file.readAsString())
        let decoder = makeMetadataDecoder(for: markdown)
        let content = try makeContent(fromMarkdown: markdown, file: file, decoder: decoder)
        return Page(path: path, content: content)
    }
}

private extension MarkdownContentFactory {
    func makeMetadataDecoder(for markdown: Markdown) -> MarkdownMetadataDecoder {
        MarkdownMetadataDecoder(
            metadata: markdown.metadata,
            dateFormatter: dateFormatter
        )
    }

    func makeContent(fromMarkdown markdown: Markdown,
                     file: File,
                     decoder: MarkdownMetadataDecoder) throws -> Content {
        let title = try decoder.decodeIfPresent("title", as: String.self)
        let description = try decoder.decodeIfPresent("description", as: String.self)
        let date = try resolvePublishingDate(fromFile: file, decoder: decoder)
        let lastModified = file.modificationDate ?? date
        let imagePath = try decoder.decodeIfPresent("image", as: Path.self)
        let audio = try decoder.decodeIfPresent("audio", as: Audio.self)
        let video = try decoder.decodeIfPresent("video", as: Video.self)
        let isDraft = try decoder.decodeIfPresent("isDraft", as: Bool.self)

        return Content(
            title: title ?? markdown.title ?? file.nameExcludingExtension,
            description: description ?? "",
            body: Content.Body(html: markdown.html),
            date: date,
            lastModified: lastModified,
            imagePath: imagePath,
            audio: audio,
            video: video,
            isDraft: isDraft ?? false
        )
    }

    func resolvePublishingDate(fromFile file: File,
                               decoder: MarkdownMetadataDecoder) throws -> Date {
        if let date = try decoder.decodeIfPresent("date", as: Date.self) {
            return date
        }

        return file.modificationDate ?? Date()
    }
}
