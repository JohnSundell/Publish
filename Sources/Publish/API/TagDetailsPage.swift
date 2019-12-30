/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// A representation of a page that contains details about a given tag.
public struct TagDetailsPage: Location {
    /// The tag that the details page is for.
    public var tag: Tag
    public let path: Path
    public var content: Content
}
