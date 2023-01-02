/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Plot
import Files
import CollectionConcurrencyKit

internal struct HTMLGenerator<Site: Website> {
    let theme: Theme<Site>
    let indentation: Indentation.Kind?
    let fileMode: HTMLFileMode
    let context: PublishingContext<Site>

    func generate() async throws {
        try await withThrowingTaskGroup(of: (substep: String, paths: [Path]).self) { group in
            group.addTask { (substep: "Copy theme resources", paths: try await copyThemeResources()) }
            group.addTask { (substep: "Generate index", paths: try generateIndexHTML()) }
            group.addTask { (substep: "Generate sections", paths: try await generateSectionHTML()) }
            group.addTask { (substep: "Generate pages", paths: try await generatePageHTML()) }
            group.addTask { (substep: "Generate tags", paths: try await generateTagHTMLIfNeeded()) }

            var substepsByPath = [Path: [String]]()
            for try await (substep, paths) in group {
                for path in paths {
                    if let previousSubsteps = substepsByPath[path] {
                        let substeps = previousSubsteps.appending(substep)
                        throw PublishingError(
                            path: path,
                            infoMessage: "Path conflict in substeps: \(substeps)"
                        )
                    }
                    substepsByPath[path, default: []].append(substep)
                }
            }
        }
    }
}

private extension HTMLGenerator {
    func copyThemeResources() async throws -> [Path] {
        guard !theme.resourcePaths.isEmpty else {
            return []
        }

        let creationFile = try File(path: theme.creationPath.string)
        let packageFolder = try creationFile.resolveSwiftPackageFolder()

        return try await theme.resourcePaths.concurrentMap { path -> Path in
            do {
                let file = try packageFolder.file(at: path.string)
                try context.copyFileToOutput(file, targetFolderPath: nil)
                return path
            } catch {
                throw PublishingError(
                    path: path,
                    infoMessage: "Failed to copy theme resource",
                    underlyingError: error
                )
            }
        }
    }

    func generateIndexHTML() throws -> [Path] {
        let html = try theme.makeIndexHTML(context.index, context)
        let path = Path("index.html")
        let indexFile = try context.createOutputFile(at: path)
        try indexFile.write(html.render(indentedBy: indentation))
        return [path]
    }

    func generateSectionHTML() async throws -> [Path] {
        try await context.sections.concurrentFlatMap { section -> [Path] in
            var allPaths = [Path]()

            let sectionPath = try outputHTML(
                for: section,
                indentedBy: indentation,
                using: theme.makeSectionHTML,
                fileMode: .foldersAndIndexFiles
            )
            allPaths.append(sectionPath)

            let sectionItemPaths = try await section.items.concurrentMap { item -> Path in
                try outputHTML(
                    for: item,
                    indentedBy: indentation,
                    using: theme.makeItemHTML,
                    fileMode: fileMode
                )
            }

            allPaths.append(contentsOf: sectionItemPaths)
            return allPaths
        }
    }

    func generatePageHTML() async throws -> [Path] {
        try await context.pages.values.concurrentMap { page -> Path in
            try outputHTML(
                for: page,
                indentedBy: indentation,
                using: theme.makePageHTML,
                fileMode: fileMode
            )
        }
    }

    func generateTagHTMLIfNeeded() async throws -> [Path] {
        guard let config = context.site.tagHTMLConfig else {
            return []
        }

        let listPage = TagListPage(
            tags: context.allTags,
            path: config.basePath,
            content: config.listContent ?? .init()
        )

        var allPaths = [Path]()
        if let listHTML = try theme.makeTagListHTML(listPage, context) {
            let listPath = Path("\(config.basePath)/index.html")
            let listFile = try context.createOutputFile(at: listPath)
            try listFile.write(listHTML.render(indentedBy: indentation))
            allPaths.append(listPath)
        }

        let tagPaths: [Path] = try await context.allTags.concurrentCompactMap { tag -> Path? in
            let detailsPath = context.site.path(for: tag)
            let detailsContent = config.detailsContentResolver(tag)

            let detailsPage = TagDetailsPage(
                tag: tag,
                path: detailsPath,
                content: detailsContent ?? .init()
            )

            guard let detailsHTML = try theme.makeTagDetailsHTML(detailsPage, context) else {
                return nil
            }

            return try outputHTML(
                for: detailsPage,
                indentedBy: indentation,
                using: { _, _ in detailsHTML },
                fileMode: fileMode
            )
        }

        allPaths.append(contentsOf: tagPaths)
        return allPaths
    }

    func outputHTML<T: Location>(
        for location: T,
        indentedBy indentation: Indentation.Kind?,
        using generator: (T, PublishingContext<Site>) throws -> HTML,
        fileMode: HTMLFileMode
    ) throws -> Path {
        let html = try generator(location, context)
        let path = filePath(for: location, fileMode: fileMode)
        let file = try context.createOutputFile(at: path)
        try file.write(html.render(indentedBy: indentation))
        return path
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
