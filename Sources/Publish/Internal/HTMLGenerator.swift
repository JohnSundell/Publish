/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Plot
import Files

internal struct HTMLGenerator<Site: Website> {
    let theme: Theme<Site>
    let indentation: Indentation.Kind?
    let fileMode: HTMLFileMode
    let context: PublishingContext<Site>

    func generate() throws {
        try copyThemeResources()
        try generateIndexHTML()
        try generateSectionHTML()
        try generatePageHTML()
        try generateTagHTMLIfNeeded()
    }
}

private extension HTMLGenerator {
    func copyThemeResources() throws {
        guard !theme.resourcePaths.isEmpty else {
            return
        }

        let creationFile = try File(path: theme.creationPath.string)
        let packageFolder = try creationFile.resolveSwiftPackageFolder()

        for path in theme.resourcePaths {
            do {
                let file = try packageFolder.file(at: path.string)
                try context.copyFileToOutput(file, targetFolderPath: nil)
            } catch {
                throw PublishingError(
                    path: path,
                    infoMessage: "Failed to copy theme resource",
                    underlyingError: error
                )
            }
        }
    }

    func generateIndexHTML() throws {
        let html = try theme.makeIndexHTML(context.index, context)
        let indexFile = try context.createOutputFile(at: "index.html")
        var renderedHtml = html.render(indentedBy: indentation)
        renderedHtml = try context.htmlMutations.mutateHtml(context: context, renderedHtml: renderedHtml)
        try indexFile.write(renderedHtml)
    }

    func generateSectionHTML() throws {
        for section in context.sections {
            try outputHTML(
                for: section,
                indentedBy: indentation,
                using: theme.makeSectionHTML,
                fileMode: .foldersAndIndexFiles
            )

            for item in section.items {
                try outputHTML(
                    for: item,
                    indentedBy: indentation,
                    using: theme.makeItemHTML,
                    fileMode: fileMode
                )
            }
        }
    }

    func generatePageHTML() throws {
        for page in context.pages.values {
            try outputHTML(
                for: page,
                indentedBy: indentation,
                using: theme.makePageHTML,
                fileMode: fileMode
            )
        }
    }

    func generateTagHTMLIfNeeded() throws {
        guard let config = context.site.tagHTMLConfig else {
            return
        }

        let listPage = TagListPage(
            tags: context.allTags,
            path: config.basePath,
            content: config.listContent ?? .init()
        )

        if let listHTML = try theme.makeTagListHTML(listPage, context) {
            let listPath = Path("\(config.basePath)/index.html")
            let listFile = try context.createOutputFile(at: listPath)
            try listFile.write(listHTML.render(indentedBy: indentation))
        }

        for tag in context.allTags {
            let detailsPath = context.site.path(for: tag)
            let detailsContent = config.detailsContentResolver(tag)

            let detailsPage = TagDetailsPage(
                tag: tag,
                path: detailsPath,
                content: detailsContent ?? .init()
            )

            guard let detailsHTML = try theme.makeTagDetailsHTML(detailsPage, context) else {
                continue
            }

            try outputHTML(
                for: detailsPage,
                indentedBy: indentation,
                using: { _, _ in detailsHTML },
                fileMode: fileMode
            )
        }
    }

    func renderHTML<T: Location>(
        for location: T,
        indentedBy indentation: Indentation.Kind?,
        using generator: (T, PublishingContext<Site>) throws -> HTML
    ) throws -> String {
        let html = try generator(location, context)
        return html.render(indentedBy: indentation)
    }

    func outputHTML<T: Location>(
        for location: T,
        indentedBy indentation: Indentation.Kind?,
        using generator: (T, PublishingContext<Site>) throws -> HTML,
        fileMode: HTMLFileMode
    ) throws {
        var renderedHtml = try renderHTML(for: location, indentedBy: indentation, using: generator)
        if let section = location as? Section<Site> {
            renderedHtml = try context.htmlMutations.mutateHtml(context: context, section: section, renderedHtml: renderedHtml)
        } else if let item = location as? Item<Site> {
            renderedHtml = try context.htmlMutations.mutateHtml(context: context, item: item, renderedHtml: renderedHtml)
        } else if let page = location as? Page {
            renderedHtml = try context.htmlMutations.mutateHtml(context: context, page: page, renderedHtml: renderedHtml)
        } else {
            renderedHtml = try context.htmlMutations.mutateHtml(context: context, location: location, renderedHtml: renderedHtml)
        }
        let path = filePath(for: location, fileMode: fileMode)
        let file = try context.createOutputFile(at: path)
        try file.write(renderedHtml)
    }

    func filePath(for location: Location, fileMode: HTMLFileMode) -> Path {
        switch fileMode {
        case .foldersAndIndexFiles:
            return "\(location.path)/index.html"
        case .standAloneFiles:
            return "\(location.path).html"
        }
    }
}

