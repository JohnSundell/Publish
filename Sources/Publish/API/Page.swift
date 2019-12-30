/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Type that represents a free-form page within a website. Pages can have
/// any path or structure, and can contain any content. To implement collections
/// or lists of pages, that should be organized within sections, use `Section`
/// and `Item` instead. Pages can either be added programmatically, or through
/// Markdown files placed within the root of the website's content folder.
public struct Page: Location, Equatable {
    public var path: Path
    public var content: Content

    /// Initialize a new page programmatically. You can also create pages from
    /// Markdown using the `addMarkdownFiles` step.
    /// - Parameter path: The absolute path of the page.
    /// - Parameter content: The page's content.
    public init(path: Path, content: Content) {
        self.path = path
        self.content = content
    }
}
