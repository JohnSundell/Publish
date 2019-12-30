/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Protocol adopted by types that can act as a location
/// that a user can navigate to within a web browser.
public protocol Location: ContentProtocol {
    /// The absolute path of the location within the website,
    /// excluding its base URL. For example, an item "article"
    /// contained within a section "mySection" will have the
    /// path "mySection/article". You can resolve the absolute
    /// URL for a location and/or path using your `Website`.
    var path: Path { get }
    /// The location's main content. You can also access this
    /// type's nested properties as top-level properties on the
    /// location itself, so `title`, rather than `content.title`.
    var content: Content { get set }
}

public extension Location {
    var title: String {
        get { content.title }
        set { content.title = newValue }
    }


    var description: String {
        get { content.description }
        set { content.description = newValue }
    }

    var body: Content.Body {
        get { content.body }
        set { content.body = newValue }
    }

    var date: Date {
        get { content.date }
        set { content.date = newValue }
    }

    var lastModified: Date {
        get { content.lastModified }
        set { content.lastModified = newValue }
    }

    var imagePath: Path? {
        get { content.imagePath }
        set { content.imagePath = newValue }
    }

    var audio: Audio? {
        get { content.audio }
        set { content.audio = newValue }
    }

    var video: Video? {
        get { content.video }
        set { content.video = newValue }
    }
}
