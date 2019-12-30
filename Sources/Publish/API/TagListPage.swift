/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

/// A representation of the page that contains all of a website's tags.
public struct TagListPage: Location {
    /// All of the tags used within the website.
    public var tags: Set<Tag>
    public let path: Path
    public var content: Content
}
