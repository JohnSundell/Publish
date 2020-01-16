/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// An item represents a website page that is contained within a `Section`,
/// and is typically used to implement lists of content, such as a blogs or
/// article lists, podcasts, and so on. To implement free-form pages, use
/// the `Page` type. Items can either be added programmatically, or through
/// Markdown files placed in their corresponding section's folder.
public struct Item<Site: Website>: AnyItem, Hashable {
    /// The ID of the section that the item belongs to, as defined by the
    /// `Website` that this item is for.
    public internal(set) var sectionID: Site.SectionID
    /// The item's site-specific metadata, as defined by the `Website` that
    /// this item is for.
    public var metadata: Site.ItemMetadata
    public var tags: [Tag]
    public var path: Path { makeAbsolutePath() }
    public var content: Content
    public var rssProperties: ItemRSSProperties

    internal let relativePath: Path

    /// Initialize a new item programmatically. You can also create items from
    /// Markdown using the `addMarkdownFiles` step.
    /// - parameter path: The path of the item within its section.
    /// - parameter sectionID: The ID of the section that the item belongs to.
    /// - parameter metadata: The item's site-specific metadata.
    /// - parameter tags: The item's tags.
    /// - parameter content: The main content of the item.
    /// - parameter rssProperties: Properties customizing the item's RSS representation.
    public init(path: Path,
                sectionID: Site.SectionID,
                metadata: Site.ItemMetadata,
                tags: [Tag] = [],
                content: Content = Content(),
                rssProperties: ItemRSSProperties = .init()) {
        self.relativePath = path
        self.sectionID = sectionID
        self.metadata = metadata
        self.tags = tags
        self.content = content
        self.rssProperties = rssProperties
    }
}

internal extension Item {
    var rssTitle: String {
        let prefix = rssProperties.titlePrefix ?? ""
        let suffix = rssProperties.titleSuffix ?? ""
        return prefix + title + suffix
    }
}

private extension Item {
    func makeAbsolutePath() -> Path {
        "\(sectionID.rawValue)/\(relativePath)"
    }
}
