/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Publish
import Plot

struct HTMLFactoryMock<Site: Website>: HTMLFactory {
    typealias Closure<T> = @Sendable (T, PublishingContext<Site>) throws -> HTML

    init(
        makeIndexHTML: @escaping Closure<Index> = { _, _ in HTML(.body()) },
        makeSectionHTML: @escaping Closure<Section<Site>> = { _, _ in HTML(.body()) },
        makeItemHTML: @escaping Closure<Item<Site>> = { _, _ in HTML(.body()) },
        makePageHTML: @escaping Closure<Page> = { _, _ in HTML(.body()) },
        makeTagListHTML: Closure<TagListPage>? = { _, _ in HTML(.body()) },
        makeTagDetailsHTML: Closure<TagDetailsPage>? = { _, _ in HTML(.body()) },
    ) {
        self.makeIndexHTML = makeIndexHTML
        self.makeSectionHTML = makeSectionHTML
        self.makeItemHTML = makeItemHTML
        self.makePageHTML = makePageHTML
        self.makeTagListHTML = makeTagListHTML
        self.makeTagDetailsHTML = makeTagDetailsHTML
    }

    let makeIndexHTML: Closure<Index>
    let makeSectionHTML: Closure<Section<Site>>
    let makeItemHTML: Closure<Item<Site>>
    let makePageHTML: Closure<Page>
    let makeTagListHTML: Closure<TagListPage>?
    let makeTagDetailsHTML: Closure<TagDetailsPage>?

    func makeIndexHTML(for index: Index,
                       context: PublishingContext<Site>) throws -> HTML {
        try makeIndexHTML(index, context)
    }

    func makeSectionHTML(for section: Section<Site>,
                         context: PublishingContext<Site>) throws -> HTML {
        try makeSectionHTML(section, context)
    }

    func makeItemHTML(for item: Item<Site>,
                      context: PublishingContext<Site>) throws -> HTML {
        try makeItemHTML(item, context)
    }

    func makePageHTML(for page: Page,
                      context: PublishingContext<Site>) throws -> HTML {
        try makePageHTML(page, context)
    }

    func makeTagListHTML(for page: TagListPage,
                         context: PublishingContext<Site>) throws -> HTML? {
        try makeTagListHTML?(page, context)
    }

    func makeTagDetailsHTML(for page: TagDetailsPage,
                            context: PublishingContext<Site>) throws -> HTML? {
        try makeTagDetailsHTML?(page, context)
    }
}
