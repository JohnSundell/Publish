/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot
import Codextended

/// A representation of a location's audio data. Can be used to
/// implement podcast feeds, or inline audio players using the
/// `audioPlayer` Plot component.
public struct Audio: Hashable {
    /// The URL of the audio. Should be an absolute URL.
    public var url: URL
    /// The format of the audio. See `HTMLAudioFormat`.
    public var format: HTMLAudioFormat
    /// The duration of the audio. Required for podcasts.
    public var duration: Duration?
    /// The audio's file size (in bytes). Required for podcasts.
    public var byteSize: Int?

    /// Initialize a new instance of this type.
    /// - parameter url: The URL of the audio.
    /// - parameter format: The format of the audio.
    /// - parameter duration: The duration of the audio.
    /// - parameter byteSize: The audio's file size (in bytes).
    public init(url: URL,
                format: HTMLAudioFormat = .mp3,
                duration: Duration? = nil,
                byteSize: Int? = nil) {
        self.url = url
        self.format = format
        self.duration = duration
        self.byteSize = byteSize
    }
}

public extension Audio {
    /// A representation of an audio file's duration.
    struct Duration: Hashable {
        /// The duration's number of hours.
        public var hours: Int
        /// The duration's number of minutes.
        public var minutes: Int
        /// The duration's number of seconds.
        public var seconds: Int

        /// Initialize a new instance of this type.
        /// - Parameter hours: The duration's number of hours.
        /// - Parameter minutes: The duration's number of minutes.
        /// - Parameter seconds: The duration's number of seconds.
        public init(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) {
            self.hours = hours
            self.minutes = minutes
            self.seconds = seconds
        }
    }
}

extension Audio: Decodable {
    public init(from decoder: Decoder) throws {
        url = try decoder.decode("url")
        format = try decoder.decodeIfPresent("format") ?? .mp3
        duration = try decoder.decodeIfPresent("duration")
        byteSize = try decoder.decodeIfPresent("size")
    }
}

extension Audio.Duration: Decodable {
    public init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        let components = string.split(separator: ":")

        guard (1...3).contains(components.count) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: """
                Audio duration strings should be formatted as either HH:mm:ss or mm:ss
                """
            )
        }

        let keyPaths: [WritableKeyPath<Self, Int>] = [\.seconds, \.minutes, \.hours]

        for (keyPath, string) in zip(keyPaths, components.reversed()) {
            guard let value = Int(string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: """
                    Invalid audio duration component '\(string)'
                    """
                )
            }

            self[keyPath: keyPath] = value
        }
    }
}
