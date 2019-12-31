/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Protocol adopted by types that represent the content for a location.
public protocol ContentProtocol {
    /// The location's title. When parsing a location from Markdown,
    /// the top-level H1 heading will be used as the location's title,
    /// which can also be overridden using the `title` metadata key.
    var title: String { get set }
    /// A description of the location. When parsing a location from
    /// Markdown, a description may be defined using the `description`
    /// metadata key.
    var description: String { get set }
    /// The main body of the location's content. Can either be defined
    /// using raw HTML, Markdown, or by using a Plot `Node` hierarchy.
    var body: Content.Body { get set }
    /// The main publishing date of the location. Typically used to sort
    /// lists of locations or when generating RSS feeds, and can also be
    /// formatted and displayed to the user. When parsing a location from
    /// Markdown, this date can be defined using the `date` metadata key,
    /// and otherwise defaults to the last modification date of the file.
    var date: Date { get set }
    /// The date when the location was last modified. When parsing a location
    /// from Markdown, this date will default to the last modification
    /// date of the file.
    var lastModified: Date { get set }
    /// Any path to an image that should be associated with the location.
    /// Can be defined using the Markdown `image` metadata key. When using
    /// Publish's built-in way to define HTML head elements, this property
    /// is used for the location's social media image.
    var imagePath: Path? { get set }
    /// Any audio data that should be associated with the location. Can be
    /// used to implement Podcast feeds, or to display inline audio players
    /// within a website, using the `audioPlayer` Plot component. Required
    /// when using the `generatePodcastFeed` step. See `Audio` for more info.
    var audio: Audio? { get set }
    /// Any video data that should be associated with the location, which
    /// can be used to display inline video players using the `videoPlayer`
    /// Plot component. See `Video` for more info.
    var video: Video? { get set }
}
