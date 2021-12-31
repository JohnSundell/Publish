import Plot

internal struct HTMLMutations<Site: Website> {
    var indexMutations: [HTMLIndexMutation<Site>] = []
    var sectionMutations: [HTMLSectionMutation<Site>] = []
    var itemMutations: [HTMLItemMutation<Site>] = []
    var pageMutations: [HTMLPageMutation<Site>] = []
    var allMutations: [HTMLAllMutation<Site>] = []

    public init() {
    }

    func mutateHtml(context: PublishingContext<Site>, renderedHtml: String) throws -> String {
        var mutatedHtml = renderedHtml
        for mutation in indexMutations {
            mutatedHtml = try mutation(context, mutatedHtml)
        }
        mutatedHtml = try mutateHtml(context: context, location: context.index, renderedHtml: mutatedHtml)
        return mutatedHtml
    }

    func mutateHtml(context: PublishingContext<Site>, section: Section<Site>, renderedHtml: String) throws -> String {
        var mutatedHtml = renderedHtml
        for mutation in sectionMutations {
            mutatedHtml = try mutation(context, section, mutatedHtml)
        }
        mutatedHtml = try mutateHtml(context: context, location: section, renderedHtml: mutatedHtml)
        return mutatedHtml
    }

    func mutateHtml(context: PublishingContext<Site>, item: Item<Site>, renderedHtml: String) throws -> String {
        var mutatedHtml = renderedHtml
        for mutation in itemMutations {
            mutatedHtml = try mutation(context, item, mutatedHtml)
        }
        mutatedHtml = try mutateHtml(context: context, location: item, renderedHtml: mutatedHtml)
        return mutatedHtml
    }

    func mutateHtml(context: PublishingContext<Site>, page: Page, renderedHtml: String) throws -> String {
        var mutatedHtml = renderedHtml
        for mutation in pageMutations {
            mutatedHtml = try mutation(context, page, mutatedHtml)
        }
        mutatedHtml = try mutateHtml(context: context, location: page, renderedHtml: mutatedHtml)
        return mutatedHtml
    }

    func mutateHtml(context: PublishingContext<Site>, location: Location, renderedHtml: String) throws -> String {
        var mutatedHtml = renderedHtml
        for mutation in allMutations {
            mutatedHtml = try mutation(context, location, mutatedHtml)
        }
        return mutatedHtml
    }

}

