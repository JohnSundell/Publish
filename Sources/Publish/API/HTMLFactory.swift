/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Plot

/// Protocol used to implement a website theme's underlying factory,
/// that creates HTML for a site's various locations using the Plot DSL.
public protocol HTMLFactory {
    /// The website that the factory is for. Generic constraints may be
    /// applied to this type to require that a website fulfills certain
    /// requirements in order to use this factory.
    associatedtype Site: Website

    /// Create the HTML to use for the website's main index page.
    /// - parameter index: The index page to generate HTML for.
    /// - parameter context: The current publishing context.
    func makeIndexHTML(for index: Index,
                       context: PublishingContext<Site>) throws -> HTML

    /// Create the HTML to use for the index page of a section.
    /// - parameter section: The section to generate HTML for.
    /// - parameter context: The current publishing context.
    func makeSectionHTML(for section: Section<Site>,
                         context: PublishingContext<Site>) throws -> HTML

    /// Create the HTML to use for an item.
    /// - parameter item: The item to generate HTML for.
    /// - parameter context: The current publishing context.
    func makeItemHTML(for item: Item<Site>,
                      context: PublishingContext<Site>) throws -> HTML

    /// Create the HTML to use for a page.
    /// - parameter page: The page to generate HTML for.
    /// - parameter context: The current publishing context.
    func makePageHTML(for page: Page,
                      context: PublishingContext<Site>) throws -> HTML

    /// Create the HTML to use for the website's list of tags, if supported.
    /// Return `nil` if the theme that this factory is for doesn't support tags.
    /// - parameter page: The tag list page to generate HTML for.
    /// - parameter context: The current publishing context.
    func makeTagListHTML(for page: TagListPage,
                         context: PublishingContext<Site>) throws -> HTML?

    /// Create the HTML to use for a tag details page, used to represent a single
    /// tag. Return `nil` if the theme that this factory is for doesn't support tags.
    /// - parameter page: The tag details page to generate HTML for.
    /// - parameter context: The current publishing context.
    func makeTagDetailsHTML(for page: TagDetailsPage,
                            context: PublishingContext<Site>) throws -> HTML?
}
