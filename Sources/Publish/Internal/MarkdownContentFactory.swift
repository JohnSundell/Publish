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
    let keyDecodingStrategy: MetadataKeyDecodingStrategy

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
        let keys = MetadataKeys(with: keyDecodingStrategy)
        let tags = try decoder.decodeIfPresent(keys.tags, as: [Tag].self)
        let content = try makeContent(fromMarkdown: markdown, file: file, decoder: decoder)
        let rssProperties = try decoder.decodeIfPresent(keys.rss, as: ItemRSSProperties.self)

        return Item(
            path: path,
            sectionID: sectionID,
            metadata: metadata,
            tags: tags ?? [],
            content: content,
            rssProperties: rssProperties ?? .init()
        )
    }

    func makePage(fromFile file: File,
                  at path: Path) throws -> Page {
        let markdown = try parser.parse(file.readAsString())
        let decoder = makeMetadataDecoder(for: markdown)
        let content = try makeContent(fromMarkdown: markdown, file: file, decoder: decoder)
        return Page(path: path, content: content)
    }
}

struct MetadataKeys {
    var title: String = "title"
    var description: String = "description"
    var date: String = "date"
    var image: String = "image"
    var audio: String = "audio"
    var video: String = "video"
    var tags: String = "tags"
    var rss: String = "rss"

    init(with keyDecodingStrategy: MetadataKeyDecodingStrategy) {
        switch keyDecodingStrategy {
        case .capitalized:
            self.title = self.title.capitalized
            self.description = self.description.capitalized
            self.date = self.date.capitalized
            self.image = self.image.capitalized
            self.audio = self.audio.capitalized
            self.video = self.video.capitalized
            self.tags = self.tags.capitalized
            self.rss = self.rss.capitalized

            // Handle .lowercase specifically, instead of using case default:, even though we don't do anything
            // because we might add support for other decoding strategies in future
            // and we want the compiler to force us to handle them specifically here
        case .lowercase:
            // This is the default case, so leave the keys with their default values
            break
        }
    }
}

private extension MarkdownContentFactory {
    func makeMetadataDecoder(for markdown: Markdown) -> MarkdownMetadataDecoder {
        MarkdownMetadataDecoder(
            metadata: markdown.metadata,
            dateFormatter: dateFormatter,
            keyDecodingStrategy: keyDecodingStrategy
        )
    }

    func makeContent(fromMarkdown markdown: Markdown,
                     file: File,
                     decoder: MarkdownMetadataDecoder) throws -> Content {

        let keys = MetadataKeys(with: keyDecodingStrategy)

        let title = try decoder.decodeIfPresent(keys.title, as: String.self)
        let description = try decoder.decodeIfPresent(keys.description, as: String.self)
        let date = try resolvePublishingDate(fromFile: file, decoder: decoder, keys: keys)
        let lastModified = file.modificationDate ?? date
        let imagePath = try decoder.decodeIfPresent(keys.image, as: Path.self)
        let audio = try decoder.decodeIfPresent(keys.audio, as: Audio.self)
        let video = try decoder.decodeIfPresent(keys.video, as: Video.self)

        return Content(
            title: title ?? markdown.title ?? "",
            description: description ?? "",
            body: Content.Body(html: markdown.html),
            date: date,
            lastModified: lastModified,
            imagePath: imagePath,
            audio: audio,
            video: video
        )
    }

    func resolvePublishingDate(fromFile file: File,
                               decoder: MarkdownMetadataDecoder,
                               keys: MetadataKeys) throws -> Date {
        if let date = try decoder.decodeIfPresent(keys.date, as: Date.self) {
            return date
        }

        return file.modificationDate ?? Date()
    }
}
