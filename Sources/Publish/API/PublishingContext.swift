/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot
import Files
import Codextended
import MarkdownParser
import Synchronization

/// Type that represents the context in which a website is being published.
/// It can be used to manipulate the state of the website in various ways,
/// including mutating and adding new content, creating new files and folders,
/// and so on. Each `PublishingStep` gets access to the current context.
public final class PublishingContext<Site: Website>: Sendable {
    /// The website that this context is for.
    public let site: Site
    /// The Markdown parser that this publishing session is using. You can
    /// add modifiers to it to customize how each Markdown string is rendered.
    public var markdownParser: MarkdownParser {
        state.withLock(\.markdownParser)
    }
    /// The date formatter that this publishing session is using when parsing
    /// dates from Markdown files.
    public let dateFormatter: DateFormatter

    /// Mutable State in PublishingContext
    public struct State {
        public var markdownParser: MarkdownParser = .init()

        /// A representation of the website's main index page.
        public var index = Index()
        /// The sections that the website contains.
        public var sections = SectionMap<Site>() {
            didSet { tagCache = nil }
        }

        /// The free-form pages that the website contains.
        public fileprivate(set) var pages = [Path : Page]()

        /// Any date when the website was last generated.
        public fileprivate(set) var lastGenerationDate: Date?

        fileprivate var tagCache: Set<Tag>?
        fileprivate var stepName: String
    }

    public var index: Index { state.withLock(\.index) }

    public var sections: SectionMap<Site> { state.withLock(\.sections) }

    public var pages: [Path: Page] { state.withLock(\.pages) }

    public var lastGenerationDate: Date? { state.withLock(\.lastGenerationDate) }

    /// A set containing all tags that are currently being used website-wide.
    public var allTags: Set<Tag> { state.withLock(\.tagCache) ?? gatherAllTags() }

    public let state: Mutex<State>

    private let folders: Folder.Group

    internal init(site: Site,
                  folders: Folder.Group,
                  firstStepName: String,
                  dateFormat: String = "yyyy-MM-dd HH:mm"
    ) {
        self.site = site
        self.folders = folders
        self.state = .init(.init(stepName: firstStepName))

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.timeZone = .current
        self.dateFormatter = dateFormatter
    }
}

public extension PublishingContext {
    func addModifier(
        for target: Modifier.Target,
        modifier: @escaping Modifier.Closure,
        file: StaticString = #file,
        line: Int = #line
    ) {
        state.withLock {
            $0.markdownParser.addModifier(for: target, modifier: modifier, file: file, line: line)
        }
    }

    func index(content: Content) {
        state.withLock { $0.index.content = content }
    }

    /// Retrieve a folder at a given path, starting from the website's root folder.
    /// - parameter path: The path to retrieve a folder for.
    /// - throws: An error in case the folder couldn't be found.
    func folder(at path: Path) throws -> Folder {
        do { return try folders.root.subfolder(at: path.string) }
        catch { throw FileIOError(path: path, reason: .folderNotFound) }
    }

    /// Retrieve a file at a given path, starting from the website's root folder.
    /// - parameter path: The path to retrieve a file for.
    /// - throws: An error in case the file couldn't be found.
    func file(at path: Path) throws -> File {
        do { return try folders.root.file(at: path.string) }
        catch { throw FileIOError(path: path, reason: .fileNotFound) }
    }

    /// Retrieve a folder within the website's output folder.
    /// - parameter path: The path to retrieve a folder for.
    /// - throws: An error in case the folder couldn't be found.
    func outputFolder(at path: Path) throws -> Folder {
        do { return try folders.output.subfolder(at: path.string) }
        catch { throw FileIOError(path: path, reason: .folderNotFound) }
    }

    /// Retrieve a file within the website's output folder.
    /// - parameter path: The path to retrieve a file for.
    /// - throws: An error in case the file couldn't be found.
    func outputFile(at path: Path) throws -> File {
        do { return try folders.output.file(at: path.string) }
        catch { throw FileIOError(path: path, reason: .fileNotFound) }
    }

    /// Create a folder at a given path, starting from the website's root folder.
    /// - parameter path: The path to create a folder at.
    /// - throws: An error in case the folder couldn't be created.
    func createFolder(at path: Path) throws -> Folder {
        try createFolder(at: path, in: folders.root)
    }

    /// Create a file at a given path, starting from the website's root folder.
    /// - parameter path: The path to create a file at.
    /// - throws: An error in case the file couldn't be created.
    func createFile(at path: Path) throws -> File {
        try createFile(at: path, in: folders.root)
    }

    /// Create a folder at a given path within the website's output folder.
    /// - parameter path: The path to create a folder at.
    /// - throws: An error in case the folder couldn't be created.
    func createOutputFolder(at path: Path) throws -> Folder {
        try createFolder(at: path, in: folders.output)
    }

    /// Create a file at a given path within the website's output folder.
    /// - parameter path: The path to create a file at.
    /// - throws: An error in case the file couldn't be created.
    func createOutputFile(at path: Path) throws -> File {
        try createFile(at: path, in: folders.output)
    }

    /// Copy a folder at a given path into the website's output folder.
    /// - parameter originPath: The path of the folder to copy.
    /// - parameter targetFolderPath: Any specific path to copy the folder to.
    ///   If `nil`, then the folder will be copied to the output folder itself.
    func copyFolderToOutput(from originPath: Path,
                            to targetFolderPath: Path? = nil) throws {
        let folder = try self.folder(at: originPath)
        try copyFolderToOutput(folder, targetFolderPath: targetFolderPath)
    }

    /// Copy a file at a given path into the website's output folder.
    /// - parameter originPath: The path of the file to copy.
    /// - parameter targetFolderPath: Any specific folder path to copy the file to.
    ///   If `nil`, then the file will be copied to the output folder itself.
    func copyFileToOutput(from originPath: Path,
                          to targetFolderPath: Path? = nil) throws {
        let file = try self.file(at: originPath)
        try copyFileToOutput(file, targetFolderPath: targetFolderPath)
    }

    /// Create a folder suitable for deployment. Any existing folder will be emptied
    /// (apart from hidden files) before being passed to the given configure closure.
    /// After that, all output files and folders will be copied into the new folder.
    /// - Parameter prefix: What prefix to apply to the folder, typically
    ///   the name of the current deployment method.
    /// - parameter outputFolderPath: Any specific subfolder path to copy the output to.
    ///   If `nil`, then the output will be copied to the deployment folder itself.
    /// - Parameter configure: A closure used to configure the folder.
    func createDeploymentFolder(
        withPrefix prefix: String,
        outputFolderPath: Path? = nil,
        configure: (Folder) throws -> Void
    ) throws -> Folder {
        let path = Path(prefix + "Deploy")

        let folder = try createFolder(at: path, in: folders.internal)
        try folder.empty()

        do {
            try configure(folder)
        } catch {
            throw FileIOError(
                path: path,
                reason: .deploymentFolderSetupFailed(error)
            )
        }

        var outputFolder = folder

        if let outputFolderPath = outputFolderPath {
            outputFolder = try folder.createSubfolder(at: outputFolderPath.string)
        }

        do {
            try folders.output.subfolders.forEach { try $0.copy(to: outputFolder) }
            try folders.output.files.includingHidden.forEach { try $0.copy(to: outputFolder) }
            return folder
        } catch {
            throw FileIOError(path: path, reason: .folderCreationFailed)
        }
    }

    /// Return either an existing or newly created cache file for the
    /// current publishing step. Cache files are scoped to the step
    /// that they're created within, and can't be shared among steps.
    /// Cache files aren't deleted in between publishing processes.
    /// - parameter name: The name of the cache file to return.
    /// - throws: An error in case a new file couldn't be created.
    func cacheFile(named name: String) throws -> File {
        let folderName = state.withLock(\.stepName).normalized()
        let folder = try folders.caches.createSubfolderIfNeeded(withName: folderName)
        return try folder.createFileIfNeeded(withName: name.normalized())
    }

    /// Return all items within this website, sorted by a given key path.
    /// - parameter sortingKeyPath: The key path to sort the items by.
    /// - parameter order: The order to use when sorting the items.
    func allItems<T: Comparable>(
        sortedBy sortingKeyPath: KeyPath<Item<Site>, T> & Sendable,
        order: SortOrder = .ascending
    ) -> [Item<Site>] {
        let items = state.withLock { $0.sections.flatMap { $0.items } }

        return items.sorted(
            by: order.makeSorter(forKeyPath: sortingKeyPath)
        )
    }

    /// Return all items that were tagged with a given tag.
    /// - parameter tag: The tag to return all items for.
    func items(taggedWith tag: Tag) -> [Item<Site>] {
        state.withLock {
            let sections = $0.sections
            let items = sections.flatMap {
                $0.items(taggedWith: tag)
            }

            return items
        }
    }

    /// Return all items that were tagged with a given tag, sorted by
    /// a given key path.
    /// - parameter tag: The tag to return all items for.
    /// - parameter sortingKeyPath: The key path to sort the items by.
    /// - parameter order: The order to use when sorting the items.
    func items<T: Comparable>(
        taggedWith tag: Tag,
        sortedBy sortingKeyPath: KeyPath<Item<Site>, T> & Sendable,
        order: SortOrder = .ascending
    ) -> [Item<Site>] {
        items(taggedWith: tag).sorted(
            by: order.makeSorter(forKeyPath: sortingKeyPath)
        )
    }

    /// Add an item to the website programmatically.
    /// - parameter item: The item to add.
    func addItem(_ item: Item<Site>) {
        state.withLock { $0.sections[item.sectionID].addItem(item) }
    }

    /// Add an item to this section.
    /// - parameter path: The relative path to add an item at.
    /// - parameter metadata: The item's site-specific metadata.
    /// - parameter configure: A closure used to configure the new item.
    func addItem(
        to sectionId: Site.SectionID,
        at path: Path,
        withMetadata metadata: Site.ItemMetadata,
        configure: (inout Item<Site>) throws -> Void
    ) rethrows {
        try state.withLock {
            try $0.sections[sectionId].addItem(at: path, withMetadata: metadata, configure: configure)
        }
    }


    /// Add a page to the website programmatically.
    /// - parameter page: The page to add.
    func addPage(_ page: Page) {
        state.withLock {
            $0.pages[page.path] = page
        }
    }

    /// Mutate a section
    /// - parameter id: The section that will be mutated
    /// - parameter mutations: The mutations to apply to the section
    func mutateSection(id: Site.SectionID, using mutations: Mutations<Section<Site>>) rethrows {
        try state.withLock {
            try mutations(&$0.sections[id])
        }
    }
    /// Mutate an item at a given path within a section.
    /// - parameter path: The relative path of the item to mutate.
    /// - parameter section: The section that the item belongs to.
    /// - parameter mutations: The mutations to apply to the item.
    func mutateItem(at path: Path, in section: Site.SectionID, using mutations: Mutations<Item<Site>>) throws {
        try state.withLock {
            try $0.sections[section].mutateItem(at: path, using: mutations)
        }
    }

    /// Mutate all of the website's sections using a closure.
    /// - parameter mutations: The mutations to apply to each section.
    func mutateAllSections(using mutations: Mutations<Section<Site>>) rethrows {
        try state.withLock {
            for id in $0.sections.ids {
                try mutations(&$0.sections[id])
            }
        }
    }
    /// Mutate all of the website's sections using an asynchronous closure.
    /// - parameter mutations: The mutations to apply to each section.
    func mutateAllSections(using mutations: AsyncMutations<Section<Site>>) async rethrows {
        // TODO: Probably want to do something to ensure that `sections` hasn't been mutated.
        var sections = state.withLock(\.sections)

        for id in sections.ids {
            try await mutations(&sections[id])
        }

        state.withLock { $0.sections = sections }
    }

    /// Mutate one of the website's existing pages.
    /// - parameter path: The path of the page to mutate.
    /// - parameter predicate: Any predicate to match against before mutating the page.
    /// - parameter mutations: The mutations to apply to the page.
    /// - throws: An error in case the page couldn't be found, or
    ///   if the mutation close itself threw an error.
    func mutatePage(at path: Path,
                    matching predicate: Predicate<Page> = .any,
                    using mutations: Mutations<Page>) throws {
        try state.withLock {
            guard var page = $0.pages[path] else {
                throw ContentError(path: path, reason: .pageNotFound)
            }

            guard predicate.matches(page) else {
                return
            }

            do {
                try mutations(&page)
                $0.pages[page.path] = page

                if page.path != path {
                    $0.pages[path] = nil
                }
            } catch {
                throw ContentError(
                    path: page.path,
                    reason: .pageMutationFailed(error)
                )
            }
        }
    }

    /// Remove all items matching a predicate, optionally within a specific section.
    /// - parameter section: Any specific section to remove all items within.
    /// - parameter predicate: Any predicate to filter the items using.
    func removeAllItems(
        in section: Site.SectionID? = nil,
        matching predicate: Predicate<Item<Site>> = .any
    ) {
        if let section {
            state.withLock { state in
                state.sections[section].removeItems(matching: predicate)
            }
        } else {
            mutateAllSections { $0.removeItems(matching: predicate) }
        }
    }

    /// Sort all items, using a keypath, optionally within a specific section.
    /// - parameter section: Any specific section to sort all items within.
    /// - parameter keyPath: The key path to use when sorting.
    /// - parameter order: The order to use when sorting.
    func sortItems<T: Comparable>(
        in section: Site.SectionID? = nil,
        by keyPath: _SendableKeyPath<Item<Site>, T>,
        order: SortOrder = .ascending
    ) {
        let sorter = order.makeSorter(forKeyPath: keyPath)

        if let section {
            state.withLock { state in
                state.sections[section].sortItems(by: sorter)
            }
        } else {
            mutateAllSections { $0.sortItems(by: sorter) }
        }
    }
}

internal extension PublishingContext {
    func generationWillBegin() {
        try? updateLastGenerationDate()
    }

    func prepareForStep(named name: String) {
        state.withLock { $0.stepName = name }
    }

    func makeMarkdownContentFactory() -> MarkdownContentFactory<Site> {
        MarkdownContentFactory(
            parser: markdownParser,
            dateFormatter: dateFormatter
        )
    }

    func copyFileToOutput(_ file: File,
                          targetFolderPath: Path?) throws {
        try copyLocationToOutput(
            file,
            targetFolderPath: targetFolderPath,
            errorReason: .fileCopyingFailed
        )
    }

    func copyFolderToOutput(_ folder: Folder,
                            targetFolderPath: Path?) throws {
        try copyLocationToOutput(
            folder,
            targetFolderPath: targetFolderPath,
            errorReason: .folderCopyingFailed
        )
    }
}

private extension PublishingContext {
    func updateLastGenerationDate() throws {
        let fileName = "lastGenerationDate"
        let newString = String(Date().timeIntervalSince1970)

        if let file = try? folders.internal.file(named: fileName) {
            let oldInterval = try TimeInterval(file.readAsString())

            state.withLock {
                $0.lastGenerationDate = oldInterval.map {
                    Date(timeIntervalSince1970: $0)
                }
            }

            try file.write(newString)
        } else {
            let file = try folders.internal.createFile(named: fileName)
            try file.write(newString)
        }
    }

    func gatherAllTags() -> Set<Tag> {
        state.withLock {
            var tags = Set<Tag>()

            for section in $0.sections {
                tags.formUnion(section.allTags)
            }

            $0.tagCache = tags
            return tags
        }
    }

    func copyLocationToOutput<T: Files.Location>(
        _ location: T,
        targetFolderPath: Path?,
        errorReason: FileIOError.Reason
    ) throws {
        let targetFolder = try targetFolderPath.map {
            try createOutputFolder(at: $0)
        }

        do {
            try location.copy(to: targetFolder ?? folders.output)
        } catch {
            let path = Path(location.path(relativeTo: folders.root))
            throw FileIOError(path: path, reason: errorReason)
        }
    }

    func createFolder(at path: Path, in folder: Folder) throws -> Folder {
        do {
            return try folder.createSubfolderIfNeeded(at: path.string)
        } catch {
            let path = Path(folder.path + path.string)
            throw FileIOError(path: path, reason: .folderCreationFailed)
        }
    }

    func createFile(at path: Path, in folder: Folder) throws -> File {
        do {
            return try folder.createFileIfNeeded(at: path.string)
        } catch {
            let path = Path(folder.path + path.string)
            throw FileIOError(path: path, reason: .fileCreationFailed)
        }
    }
}
