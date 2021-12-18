/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot

/// Configuration type used to customize how a podcast feed is generated when
/// using the `generatePodcastFeed` step. To use a default implementation,
/// use `PodcastFeedConfiguration.default`.
public struct PodcastFeedConfiguration<Site: Website>: FeedConfiguration {
    public var targetPath: Path
    public var ttlInterval: TimeInterval
    public var maximumItemCount: Int
    public var indentation: Indentation.Kind?
    /// The type of the podcast. See `PodcastType`.
    public var type: PodcastType
    /// A URL that points to the podcast's main image.
    public var imageURL: URL
    /// The copyright text to add to the podcast feed.
    public var copyrightText: String
    /// The podcast's author. See `PodcastAuthor`.
    public var author: PodcastAuthor
    /// A longer description of the podcast.
    public var description: String
    /// A shorter description, or subtitle, for the podcast.
    public var subtitle: String
    /// Whether the podcast contains explicit content.
    public var isExplicit: Bool
    /// The podcast's main top-level category.
    public var category: String
    /// The podcast's subcategory.
    public var subcategory: String?
    /// Any new feed URL to instruct Apple Podcasts to use going forward.
    public var newFeedURL: URL?

    /// Initialize a new configuration instance.
    /// - Parameter targetPath: The path that the feed should be generated at.
    /// - Parameter ttlInterval: The feed's TTL time interval.
    /// - Parameter maximumItemCount: The maximum number of items that the
    ///   feed should contain.
    /// - Parameter type: The type of the podcast.
    /// - Parameter imageURL: A URL that points to the podcast's main image.
    /// - Parameter copyrightText: The copyright text to add to the podcast feed.
    /// - Parameter author: The podcast's author.
    /// - Parameter description: A longer description of the podcast.
    /// - Parameter subtitle: A shorter description, or subtitle, for the podcast.
    /// - Parameter isExplicit: Whether the podcast contains explicit content.
    /// - Parameter category: The podcast's main top-level category.
    /// - Parameter subcategory: The podcast's subcategory.
    /// - Parameter newFeedURL: Any new feed URL for the podcast.
    /// - Parameter indentation: How the feed should be indented.
    public init(
        targetPath: Path,
        ttlInterval: TimeInterval = 250,
        maximumItemCount: Int = .max,
        type: PodcastType = .episodic,
        imageURL: URL,
        copyrightText: String,
        author: PodcastAuthor,
        description: String,
        subtitle: String,
        isExplicit: Bool = false,
        category: String,
        subcategory: String? = nil,
        newFeedURL: URL? = nil,
        indentation: Indentation.Kind? = nil
    ) {
        self.targetPath = targetPath
        self.ttlInterval = ttlInterval
        self.maximumItemCount = maximumItemCount
        self.indentation = indentation
        self.type = type
        self.imageURL = imageURL
        self.copyrightText = copyrightText
        self.author = author
        self.description = description
        self.subtitle = subtitle
        self.category = category
        self.subcategory = subcategory
        self.isExplicit = isExplicit
        self.newFeedURL = newFeedURL
    }
}
