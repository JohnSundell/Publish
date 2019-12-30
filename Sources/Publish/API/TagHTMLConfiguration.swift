/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

/// Configuration type used to customize how a website's
/// tag page gets rendered. To use a default implementation,
/// use `TagHTMLConfiguration.default`.
public struct TagHTMLConfiguration {
    /// The based path of all of the site's tag HTML.
    public var basePath: Path
    /// Any content that should be added to the site's tag list page.
    public var listContent: Content?
    /// Any closure used to resolve content for each tag details page.
    public var detailsContentResolver: (Tag) -> Content?

    /// Initialize a new configuration instance.
    /// - Parameter basePath: The based path of all of the site's tag HTML.
    /// - Parameter listContent: The site's tag list page content.
    /// - Parameter detailsContentResolver: Any closure used to resolve
    ///   content for each tag details page.
    public init(
        basePath: Path = .defaultForTagHTML,
        listContent: Content? = nil,
        detailsContentResolver: @escaping (Tag) -> Content? = { _ in nil }
    ) {
        self.basePath = basePath
        self.listContent = listContent
        self.detailsContentResolver = detailsContentResolver
    }
}

public extension TagHTMLConfiguration {
    /// Create a default tag HTML configuration implementation.
    static var `default`: Self { .init() }
}
