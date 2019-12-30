/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Codextended

/// Type used to describe metadata for a podcast episode.
public struct PodcastEpisodeMetadata: Hashable {
    /// The episode's number.
    public var episodeNumber: Int?
    /// The number of the episode's season.
    public var seasonNumber: Int?
    /// Whether the episode contains explicit content.
    public var isExplicit: Bool

    /// Initialize a new instance of this type.
    /// - Parameter episodeNumber: The episode's number.
    /// - Parameter seasonNumber: The number of the episode's season.
    /// - Parameter isExplicit: Whether the episode contains explicit content.
    public init(episodeNumber: Int? = nil,
                seasonNumber: Int? = nil,
                isExplicit: Bool = false) {
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.isExplicit = isExplicit
    }
}

extension PodcastEpisodeMetadata: Decodable {
    public init(from decoder: Decoder) throws {
        episodeNumber = try decoder.decodeIfPresent("episode")
        seasonNumber = try decoder.decodeIfPresent("season")
        isExplicit = try decoder.decodeIfPresent("explicit") ?? false
    }
}
