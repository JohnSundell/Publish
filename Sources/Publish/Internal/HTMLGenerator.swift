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
        try indexFile.write(html.render(indentedBy: indentation))
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

    func outputHTML<T: Location>(
        for location: T,
        indentedBy indentation: Indentation.Kind?,
        using generator: (T, PublishingContext<Site>) throws -> HTML,
        fileMode: HTMLFileMode
    ) throws {
        let html = try generator(location, context)
        let path = filePath(for: location, fileMode: fileMode)
        let file = try context.createOutputFile(at: path)
        try file.write(html.render(indentedBy: indentation))
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

internal extension HTMLGenerator where Site: MultiLanguageWebsite {
    func generate() throws {
        try copyThemeResources()
        try generateIndexHTML()
        try generateSectionHTML()
        try generatePageHTML()
        try generateTagHTMLIfNeeded()
    }
}

private extension HTMLGenerator where Site: MultiLanguageWebsite {
    func generateIndexHTML() throws {
        try context.site.languages.forEach { (language) in
            let index = context.index(in: language)
            let html = try theme.makeIndexHTML(index, context)
            let indexFile = try context.createOutputFile(at: context.site.path(for: index))
            try indexFile.write(html.render(indentedBy: indentation))
        }
    }
    
    func generateSectionHTML() throws {
        for section in context.sections {
            try context.site.languages.forEach { language in
                let localizedSection = context.section(section.id, in: language)
                
                try outputHTML(
                    for: localizedSection,
                    indentedBy: indentation,
                    using: theme.makeSectionHTML,
                    fileMode: .foldersAndIndexFiles
                )
            }
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
        
        try context.site.languages.forEach { language in
            let pathPrefix = context.site.pathPrefix(for: language)
            let allTags = context.allTags(in: language)
            var listPage = TagListPage(
                tags: allTags,
                path: config.basePath,
                content: config.listContent ?? .init()
            )
            listPage.language = language
            
            if let listHTML = try theme.makeTagListHTML(listPage, context) {
                let listPath = Path("\(pathPrefix)/\(config.basePath)/index.html")
                let listFile = try context.createOutputFile(at: listPath)
                try listFile.write(listHTML.render(indentedBy: indentation))
            }
            for tag in allTags {
                let detailsPath = context.site.path(for: tag)
                let detailsContent = config.detailsContentResolver(tag)

                var detailsPage = TagDetailsPage(
                    tag: tag,
                    path: detailsPath,
                    content: detailsContent ?? .init()
                )
                detailsPage.language = language
                
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
    }
    
    func outputHTML<T: Location>(
        for location: T,
        indentedBy indentation: Indentation.Kind?,
        using generator: (T, PublishingContext<Site>) throws -> HTML,
        fileMode: HTMLFileMode
    ) throws {
        let html = try generator(location, context)
        let path = filePath(for: location, fileMode: fileMode)
        let file = try context.createOutputFile(at: path)
        try file.write(html.render(indentedBy: indentation))
    }

    func filePath(for location: Location, fileMode: HTMLFileMode) -> Path {
        let pathPrefix = context.site.pathPrefix(for: location.language!)
        switch fileMode {
        case .foldersAndIndexFiles:
            return "\(pathPrefix)/\(location.path)/index.html"
        case .standAloneFiles:
            return "\(pathPrefix)/\(location.path).html"
        }
    }
}
