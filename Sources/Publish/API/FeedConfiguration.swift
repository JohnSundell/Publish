/**
*  Publish
*  Copyright (c) John Sundell 2020
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot

/// Protocol that acts as a shared API for configuring various feed
/// generation steps, such as `generateRSSFeed` and `generatePodcastFeed`.
public protocol FeedConfiguration: Codable, Equatable {
    /// The path that the feed should be generated at.
    var targetPath: Path { get }
    /// The feed's TTL (or "Time to live") time interval.
    var ttlInterval: TimeInterval { get }
    /// The maximum number of items that the feed should contain.
    var maximumItemCount: Int { get }
    /// How the feed should be indented.
    var indentation: Indentation.Kind? { get }
}
