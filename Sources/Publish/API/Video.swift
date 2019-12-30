/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot

/// A representation of a location's video data. Can be used to implement
/// inline video players using the `videoPlayer` Plot component.
public enum Video: Hashable {
    /// A self-hosted video located at a given URL.
    case hosted(url: URL, format: HTMLVideoFormat = .mp4)
    /// A YouTube video with a given ID.
    case youTube(id: String)
    /// A Vimeo video with a given ID.
    case vimeo(id: String)
}

extension Video: Decodable {
    public init(from decoder: Decoder) throws {
        if let youTubeID: String = try decoder.decodeIfPresent("youTube") {
            self = .youTube(id: youTubeID)
        } else if let vimeoID: String = try decoder.decodeIfPresent("vimeo") {
            self = .vimeo(id: vimeoID)
        } else {
            self = try .hosted(
                url: decoder.decode("url"),
                format: decoder.decodeIfPresent("format") ?? .mp4
            )
        }
    }
}
