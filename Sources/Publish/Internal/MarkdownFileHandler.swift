/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Files
import CollectionConcurrencyKit

internal struct MarkdownFileHandler<Site: Website> {
    func addMarkdownFiles(
        in folder: Folder,
        to context: inout PublishingContext<Site>
    ) async throws {
        let factory = context.makeMarkdownContentFactory()

        if let indexFile = try? folder.file(named: "index.md") {
            do {
                context.index.content = try factory.makeContent(fromFile: indexFile)
            } catch {
                throw wrap(error, forPath: "\(folder.path)index.md")
            }
        }

        let folderResults: [FolderResult] = try await folder.subfolders.concurrentMap { subfolder in
            guard let sectionID = Site.SectionID(rawValue: subfolder.name.lowercased()) else {
                return try await .pages(makePagesForMarkdownFiles(
                    inFolder: subfolder,
                    recursively: true,
                    parentPath: Path(subfolder.name),
                    factory: factory
                ))
            }

            var sectionContent: Content?
            
            let items: [Item<Site>] = try await subfolder.files.recursive.concurrentCompactMap { file in
                guard file.isMarkdown else { return nil }

                if file.nameExcludingExtension == "index", file.parent == subfolder {
                    sectionContent = try factory.makeContent(fromFile: file)
                    return nil
                }

                do {
                    let fileName = file.nameExcludingExtension
                    let path: Path

                    if let parentPath = file.parent?.path(relativeTo: subfolder) {
                        path = Path(parentPath).appendingComponent(fileName)
                    } else {
                        path = Path(fileName)
                    }

                    return try factory.makeItem(
                        fromFile: file,
                        at: path,
                        sectionID: sectionID
                    )
                } catch {
                    let path = Path(file.path(relativeTo: folder))
                    throw wrap(error, forPath: path)
                }
            }

            return .section(id: sectionID, content: sectionContent, items: items)
        }

        for result in folderResults {
            switch result {
            case .pages(let pages):
                for page in pages {
                    context.addPage(page)
                }
            case .section(let id, let content, let items):
                if let content = content {
                    context.sections[id].content = content
                }

                for item in items {
                    context.addItem(item)
                }
            }
        }

        let rootPages = try await makePagesForMarkdownFiles(
            inFolder: folder,
            recursively: false,
            parentPath: "",
            factory: factory
        )

        for page in rootPages {
            context.addPage(page)
        }
    }
}

private extension MarkdownFileHandler {
    enum FolderResult {
        case pages([Page])
        case section(id: Site.SectionID, content: Content?, items: [Item<Site>])
    }

    func makePagesForMarkdownFiles(
        inFolder folder: Folder,
        recursively: Bool,
        parentPath: Path,
        factory: MarkdownContentFactory<Site>
    ) async throws -> [Page] {
        let pages: [Page] = try await folder.files.concurrentCompactMap { file in
            guard file.isMarkdown else { return nil }

            if file.nameExcludingExtension == "index", !recursively {
                return nil
            }

            let pagePath = parentPath.appendingComponent(file.nameExcludingExtension)
            return try factory.makePage(fromFile: file, at: pagePath)
        }

        guard recursively else {
            return pages
        }

        return try await pages + folder.subfolders.concurrentFlatMap { subfolder -> [Page] in
            let parentPath = parentPath.appendingComponent(subfolder.name)

            return try await makePagesForMarkdownFiles(
                inFolder: subfolder,
                recursively: true,
                parentPath: parentPath,
                factory: factory
            )
        }
    }

    func wrap(_ error: Error, forPath path: Path) -> Error {
        if error is FilesError<ReadErrorReason> {
            return FileIOError(path: path, reason: .fileCouldNotBeRead)
        } else if let error = error as? DecodingError {
            switch error {
            case .keyNotFound(_, let context),
                 .valueNotFound(_, let context):
                return ContentError(
                    path: path,
                    reason: .markdownMetadataDecodingFailed(
                        context: context,
                        valueFound: false
                    )
                )
            case .typeMismatch(_, let context),
                 .dataCorrupted(let context):
                return ContentError(
                    path: path,
                    reason: .markdownMetadataDecodingFailed(
                        context: context,
                        valueFound: true
                    )
                )
            @unknown default:
                return ContentError(
                    path: path,
                    reason: .markdownMetadataDecodingFailed(
                        context: nil,
                        valueFound: true
                    )
                )
            }
        } else {
            return error
        }
    }
}

private extension File {
    private static let markdownFileExtensions: Set<String> = [
        "md", "markdown", "txt", "text"
    ]

    var isMarkdown: Bool {
        self.extension.map(File.markdownFileExtensions.contains) ?? false
    }
}

import Plot

internal extension MarkdownFileHandler where Site: MultiLanguageWebsite {
    func addMarkdownFiles(
        in folder: Folder,
        to context: inout PublishingContext<Site>,
        in language: Language? = nil
    ) throws {
        let factory = context.makeMarkdownContentFactory()

        if let indexFile = try? folder.file(named: "index.md") {
            do {
                var content = try factory.makeContent(fromFile: indexFile)
                if content.language == nil {
                    content.language = language
                }
                context.add(Index(content: content))
            } catch {
                throw wrap(error, forPath: "\(folder.path)index.md")
            }
        }

        for subfolder in folder.subfolders {
            guard let sectionID = Site.SectionID(rawValue: subfolder.name.lowercased()) else {
                try addPagesForMarkdownFiles(
                    inFolder: subfolder,
                    to: &context,
                    recursively: true,
                    parentPath: Path(subfolder.name),
                    factory: factory,
                    in: language
                )
                continue
            }

            for file in subfolder.files.recursive {
                guard file.isMarkdown else { continue }

                if file.nameExcludingExtension == "index", file.parent == subfolder {
                    let content = try factory.makeContent(fromFile: file)

                    var localizedSection = Section<Site>(id: sectionID)
                    localizedSection.content = content
                    if localizedSection.language == nil {
                        localizedSection.language = language
                    }
                    context.add(localizedSection)
                    continue
                }

                do {
                    let fileName = file.nameExcludingExtension
                    let path: Path

                    if let parentPath = file.parent?.path(relativeTo: subfolder) {
                        path = Path(parentPath).appendingComponent(fileName)
                    } else {
                        path = Path(fileName)
                    }

                    var item = try factory.makeItem(
                        fromFile: file,
                        at: path,
                        sectionID: sectionID
                    )
                    if item.language == nil {
                        item.language = language
                    }
                    
                    context.addItem(item)
                    context.add(item)
                } catch {
                    let path = Path(file.path(relativeTo: folder))
                    throw wrap(error, forPath: path)
                }
            }
        }

        try addPagesForMarkdownFiles(
            inFolder: folder,
            to: &context,
            recursively: false,
            parentPath: "",
            factory: factory,
            in: language
        )
    }
}

private extension MarkdownFileHandler where Site: MultiLanguageWebsite {
    func addPagesForMarkdownFiles(
        inFolder folder: Folder,
        to context: inout PublishingContext<Site>,
        recursively: Bool,
        parentPath: Path,
        factory: MarkdownContentFactory<Site>,
        in language: Language? = nil
    ) throws {
        for file in folder.files {
            guard file.isMarkdown else { continue }

            if file.nameExcludingExtension == "index", !recursively {
                continue
            }

            let pagePath = parentPath.appendingComponent(file.nameExcludingExtension)
            var page = try factory.makePage(fromFile: file, at: pagePath)

            if page.language == nil {
                page.language = language
            }
            
            context.addPage(page)
            
        }

        guard recursively else {
            return
        }

        for subfolder in folder.subfolders {
            let parentPath = parentPath.appendingComponent(subfolder.name)

            try addPagesForMarkdownFiles(
                inFolder: subfolder,
                to: &context,
                recursively: true,
                parentPath: parentPath,
                factory: factory,
                in: language
            )
        }
    }
}
