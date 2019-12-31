/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Plot

/// Type used to implement an HTML theme.
/// When implementing reusable themes that are vended as frameworks or APIs,
/// it's recommended to create them using static factory methods, just like
/// how the built-in `foundation` theme is implemented.
public struct Theme<Site: Website> {
    internal let makeIndexHTML: (Index, PublishingContext<Site>) throws -> HTML
    internal let makeSectionHTML: (Section<Site>, PublishingContext<Site>) throws -> HTML
    internal let makeItemHTML: (Item<Site>, PublishingContext<Site>) throws -> HTML
    internal let makePageHTML: (Page, PublishingContext<Site>) throws -> HTML
    internal let makeTagListHTML: (TagListPage, PublishingContext<Site>) throws -> HTML?
    internal let makeTagDetailsHTML: (TagDetailsPage, PublishingContext<Site>) throws -> HTML?
    internal let resourcePaths: Set<Path>
    internal let creationPath: Path

    /// Create a new theme instance.
    /// - parameter factory: The HTML factory to use to create the theme's HTML.
    /// - parameter resources: A set of paths to any resources that the theme uses.
    ///   These resources will be copied into the website's output folder before
    ///   the theme is used, and should be relative to the root folder of the Swift
    ///   package that this theme is defined in.
    /// - parameter file: The file that this method is called from (auto-inserted).
    public init<T: HTMLFactory>(
        htmlFactory factory: T,
        resourcePaths resources: Set<Path> = [],
        file: StaticString = #file
    ) where T.Site == Site {
        makeIndexHTML = factory.makeIndexHTML
        makeSectionHTML = factory.makeSectionHTML
        makeItemHTML = factory.makeItemHTML
        makePageHTML = factory.makePageHTML
        makeTagListHTML = factory.makeTagListHTML
        makeTagDetailsHTML = factory.makeTagDetailsHTML
        resourcePaths = resources
        creationPath = Path("\(file)")
    }
}
