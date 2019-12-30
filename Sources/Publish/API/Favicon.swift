/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// A representation of a website's "favicon" (a small icon typically
/// displayed along the website's title in various browser UIs).
public struct Favicon {
    /// The favicon's absolute path.
    public var path: Path
    /// The MIME type of the image.
    public var type: String

    /// Initialize a new instance of this type
    /// - Parameter path: The favicon's absolute path (default: "images/favicon.png").
    /// - Parameter type: The MIME type of the image (default: "image/png").
    public init(path: Path = .defaultForFavicon, type: String = "image/png") {
        self.path = path
        self.type = type
    }
}
