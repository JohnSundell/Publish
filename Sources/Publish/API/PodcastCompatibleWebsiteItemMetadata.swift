/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Protocol adopted by `Website.ItemMetadata` implementations that
/// are podcast-compatible. Conforming to this protocol is a requirement
/// in order to use the `generatePodcastFeed` step.
public protocol PodcastCompatibleWebsiteItemMetadata: WebsiteItemMetadata {
    /// The item's podcast episode-specific metadata.
    var podcast: PodcastEpisodeMetadata? { get }
}
