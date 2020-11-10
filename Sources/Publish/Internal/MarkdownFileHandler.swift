/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Files

internal struct MarkdownFileHandler<Site: Website> {
    func addMarkdownFiles(
        in folder: Folder,
        to context: inout PublishingContext<Site>
    ) throws {
        let factory = context.makeMarkdownContentFactory()

        if let indexFile = try? folder.file(named: "index.md") {
            do {
                context.index.content = try factory.makeContent(fromFile: indexFile)
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
                    factory: factory
                )

                continue
            }

            for file in subfolder.files.recursive {
                guard file.isMarkdown else { continue }

                if file.nameExcludingExtension == "index", file.parent == subfolder {
                    let content = try factory.makeContent(fromFile: file)
                    context.sections[sectionID].content = content
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

                    let item = try factory.makeItem(
                        fromFile: file,
                        at: path,
                        sectionID: sectionID
                    )

                    context.addItem(item)
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
            factory: factory
        )
    }
}

private extension MarkdownFileHandler {
    func addPagesForMarkdownFiles(
        inFolder folder: Folder,
        to context: inout PublishingContext<Site>,
        recursively: Bool,
        parentPath: Path,
        factory: MarkdownContentFactory<Site>
    ) throws {
        for file in folder.files {
            guard file.isMarkdown else { continue }

            if file.nameExcludingExtension == "index", !recursively {
                continue
            }

            let pagePath = parentPath.appendingComponent(file.nameExcludingExtension)
            let page = try factory.makePage(fromFile: file, at: pagePath)
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
