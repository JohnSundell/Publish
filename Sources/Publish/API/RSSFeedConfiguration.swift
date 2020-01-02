/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot

/// Configuration type used to customize how an RSS feed is generated
/// when using the `generateRSSFeed` step. To use a default implementation,
/// use `RSSFeedConfiguration.default`.
public struct RSSFeedConfiguration: FeedConfiguration {
    public var targetPath: Path
    public var ttlInterval: TimeInterval
    public var maximumItemCount: Int
    public var indentation: Indentation.Kind?

    /// Initialize a new configuration instance.
    /// - Parameter targetPath: The path that the feed should be generated at.
    /// - Parameter ttlInterval: The feed's TTL time interval.
    /// - Parameter maximumItemCount: The maximum number of items that the
    ///   feed should contain.
    /// - Parameter indentation: How the feed should be indented.
    public init(
        targetPath: Path = .defaultForRSSFeed,
        ttlInterval: TimeInterval = 250,
        maximumItemCount: Int = 100,
        indentation: Indentation.Kind? = nil
    ) {
        self.targetPath = targetPath
        self.ttlInterval = ttlInterval
        self.maximumItemCount = maximumItemCount
        self.indentation = indentation
    }
}

public extension RSSFeedConfiguration {
    /// Create a default RSS feed configuration implementation.
    static var `default`: RSSFeedConfiguration { .init() }
}
