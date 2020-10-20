/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Files
import Plot

/// Type used to implement a publishing pipeline step.
/// Each Publish website is generated and deployed using steps, which can also
/// be combined into groups, and conditionally executed. Publish ships with many
/// built-in steps, and new ones can easily be defined using `step(named:body:)`.
/// Steps are added when calling `Website.publish`.
public struct PublishingStep<Site: Website> {
    /// Closure type used to define the main body of a publishing step.
    public typealias Closure = (inout PublishingContext<Site>) throws -> Void

    internal let kind: Kind
    internal let body: Body
}

// MARK: - Core

public extension PublishingStep {
    /// An empty step that does nothing. Can be used as a conditional fallback.
    static var empty: Self {
        PublishingStep(kind: .system, body: .empty)
    }

    /// Group an array of steps into one.
    /// - parameter steps: The steps to use to form a group.
    static func group(_ steps: [Self]) -> Self {
        PublishingStep(kind: .system, body: .group(steps))
    }

    /// Conditionally run a step if an expression evaluates to `true`.
    /// - parameter condition: The condition that determines whether the
    ///   step should be run or not.
    /// - parameter step: The step to run if the condition is `true`.
    static func `if`(_ condition: Bool, _ step: Self) -> Self {
        condition ? step : .empty
    }

    /// Conditionally run a step if an optional isn't `nil`.
    /// - parameter optional: The optional to unwrap.
    /// - parameter transform: A closure that transforms any unwrapped
    ///   value into a `PublishingStep` instance.
    static func unwrap<T>(_ optional: T?, _ transform: (T) -> Self) -> Self {
        optional.map(transform) ?? .empty
    }

    /// Convert a step into an optional one, making it silently fail in
    /// case it encountered an error.
    /// - parameter step: The step to turn into an optional one.
    static func optional(_ step: Self) -> Self {
        switch step.body {
        case .empty, .group:
            return step
        case .operation(let name, let closure):
            return .step(named: name, kind: step.kind) { context in
                do { try closure(&context) }
                catch {}
            }
        }
    }

    /// Install a plugin into this publishing process.
    /// - parameter plugin: The plugin to install.
    static func installPlugin(_ plugin: Plugin<Site>) -> Self {
        step(
            named: "Install plugin '\(plugin.name)'",
            kind: .generation,
            body: plugin.installer
        )
    }

    /// Create a custom step.
    /// - parameter name: A human-readable name for the step.
    /// - parameter body: The step's closure body, which is used to
    ///   to mutate the current `PublishingContext`.
    static func step(named name: String, body: @escaping Closure) -> Self {
        step(named: name, kind: .generation, body: body)
    }
}

// MARK: - Content

public extension PublishingStep {
    /// Add an item to website programmatically.
    /// - parameter item: The item to add.
    static func addItem(_ item: Item<Site>) -> Self {
        step(named: "Add item '\(item.path)'") { context in
            context.addItem(item)
        }
    }

    /// Add a sequence of items to website programmatically.
    /// - parameter sequence: The items to add.
    static func addItems<S: Sequence>(
        in sequence: S
    ) -> Self where S.Element == Item<Site> {
        step(named: "Add items in sequence") { context in
            sequence.forEach { context.addItem($0) }
        }
    }

    /// Add a page to website programmatically.
    /// - parameter page: The page to add.
    static func addPage(_ page: Page) -> Self {
        step(named: "Add page '\(page.path)'") { context in
            context.addPage(page)
        }
    }

    /// Add a sequence of pages to website programmatically.
    /// - parameter sequence: The pages to add.
    static func addPages<S: Sequence>(
        in sequence: S
    ) -> Self where S.Element == Page {
        step(named: "Add pages in sequence") { context in
            sequence.forEach { context.addPage($0) }
        }
    }

    /// Parse a folder of Markdown files and use them to add content to
    /// the website. The root folders will be parsed as sections, and the
    /// files within them as items, while root files will be parsed as pages.
    /// - parameter path: The path of the Markdown folder to add (default: `Content`).
    static func addMarkdownFiles(at path: Path = "Content") -> Self {
        step(named: "Add Markdown files from '\(path)' folder") { context in
            let folder = try context.folder(at: path)
            try MarkdownFileHandler().addMarkdownFiles(in: folder, to: &context)
        }
    }
    
    /// Remove all items matching a predicate, optionally within a specific section.
    /// - parameter section: Any specific section to remove all items within.
    /// - parameter predicate: Any predicate to filter the items using.
    static func removeAllItems(
        in section: Site.SectionID? = nil,
        matching predicate: Predicate<Item<Site>> = .any
    ) -> Self {
        let nameSuffix = section.map { " in '\($0)'" } ?? ""

        return step(named: "Remove items" + nameSuffix) { context in
            if let section = section {
                context.sections[section].removeItems(matching: predicate)
            } else {
                for section in context.sections.ids {
                    context.sections[section].removeItems(matching: predicate)
                }
            }
        }
    }

    /// Mutate all items matching a predicate, optionally within a specific section.
    /// - parameter section: Any specific section to mutate all items within.
    /// - parameter predicate: Any predicate to filter the items using.
    /// - parameter mutations: The mutations to apply to each item.
    static func mutateAllItems(
        in section: Site.SectionID? = nil,
        matching predicate: Predicate<Item<Site>> = .any,
        using mutations: @escaping Mutations<Item<Site>>
    ) -> Self {
        let nameSuffix = section.map { " in '\($0)'" } ?? ""

        return step(named: "Mutate items" + nameSuffix) { context in
            if let section = section {
                try context.sections[section].mutateItems(
                    matching: predicate,
                    using: mutations
                )
            } else {
                for section in context.sections.ids {
                    try context.sections[section].mutateItems(
                        matching: predicate,
                        using: mutations
                    )
                }
            }
        }
    }

    /// Mutate an item at a given path within a section.
    /// - parameter path: The relative path of the item to mutate.
    /// - parameter section: The section that the item belongs to.
    /// - parameter mutations: The mutations to apply to the item.
    static func mutateItem(
        at path: Path,
        in section: Site.SectionID,
        using mutations: @escaping Mutations<Item<Site>>
    ) -> Self {
        step(named: "Mutate item at '\(path)' in \(section)") { context in
            try context.sections[section].mutateItem(at: path, using: mutations)
        }
    }

    /// Mutate a page at a given path.
    /// - parameter path: The path of the page to mutate.
    /// - parameter mutations: The mutations to apply to the page.
    static func mutatePage(
        at path: Path,
        using mutations: @escaping Mutations<Page>
    ) -> Self {
        step(named: "Mutate page at '\(path)'") { context in
            try context.mutatePage(at: path, using: mutations)
        }
    }

    /// Mutate all pages, optionally matching a given predicate.
    /// - parameter predicate: Any predicate to filter the items using.
    /// - parameter mutations: The mutations to apply to the page.
    static func mutateAllPages(
        matching predicate: Predicate<Page> = .any,
        using mutations: @escaping Mutations<Page>
    ) -> Self {
        step(named: "Mutate all pages") { context in
            for path in context.pages.keys {
                try context.mutatePage(
                    at: path,
                    matching: predicate,
                    using: mutations
                )
            }
        }
    }

    /// Sort all items, optionally within a specific section, using a key path.
    /// - parameter section: Any specific section to sort all items within.
    /// - parameter keyPath: The key path to use when sorting.
    /// - parameter order: The order to use when sorting.
    static func sortItems<T: Comparable>(
        in section: Site.SectionID? = nil,
        by keyPath: KeyPath<Item<Site>, T>,
        order: SortOrder = .ascending
    ) -> Self {
        let nameSuffix = section.map { " in '\($0)'" } ?? ""

        return step(named: "Sort items" + nameSuffix) { context in
            let sorter = order.makeSorter(forKeyPath: keyPath)

            if let section = section {
                context.sections[section].sortItems(by: sorter)
            } else {
                for section in context.sections {
                    context.sections[section.id].sortItems(by: sorter)
                }
            }
        }
    }
}

// MARK: - Files and folders

public extension PublishingStep {
    /// Copy the website's main resources into its output folder
    /// - parameter originPath: The path that the resource folder is located at.
    /// - parameter targetFolderPath: Any specific path to copy the resources to.
    ///   If `nil`, then the resources will be copied to the output folder itself.
    /// - parameter includeFolder: Whether the resource folder itself, or just its
    ///   contents, should be copied. Default: `false`.
    static func copyResources(
        at originPath: Path = "Resources",
        to targetFolderPath: Path? = nil,
        includingFolder includeFolder: Bool = false
    ) -> Self {
        copyFiles(at: originPath,
                  to: targetFolderPath,
                  includingFolder: includeFolder)
    }

    /// Copy a file at a given path into the website's output folder.
    /// - parameter originPath: The path of the file to copy.
    /// - parameter targetFolderPath: Any specific folder path to copy the file to.
    ///   If `nil`, then the file will be copied to the output folder itself.
    static func copyFile(at originPath: Path,
                         to targetFolderPath: Path? = nil) -> Self {
        step(named: "Copy file '\(originPath)'") { context in
            try context.copyFileToOutput(
                from: originPath,
                to: targetFolderPath
            )
        }
    }

    /// Copy a folder at a given path into the website's output folder.
    /// - parameter originPath: The path of the folder to copy.
    /// - parameter targetFolderPath: Any specific path to copy the folder to.
    ///   If `nil`, then the folder will be copied to the output folder itself.
    /// - parameter includeFolder: Whether the origin folder itself, or just its
    ///   contents, should be copied. Default: `false`.
    static func copyFiles(
        at originPath: Path,
        to targetFolderPath: Path? = nil,
        includingFolder includeFolder: Bool = false
    ) -> Self {
        step(named: "Copy '\(originPath)' files") { context in
            let folder = try context.folder(at: originPath)

            if includeFolder {
                try context.copyFolderToOutput(
                    folder,
                    targetFolderPath: targetFolderPath
                )
            } else {
                for subfolder in folder.subfolders {
                    try context.copyFolderToOutput(
                        subfolder,
                        targetFolderPath: targetFolderPath
                    )
                }

                for file in folder.files {
                    try context.copyFileToOutput(
                        file,
                        targetFolderPath: targetFolderPath
                    )
                }
            }
        }
    }
}

// MARK: - Generation

public extension PublishingStep {
    /// Generate the website's HTML using a given theme.
    /// - parameter theme: The theme to use to generate the website's HTML.
    /// - parameter indentation: How each HTML file should be indented.
    /// - parameter fileMode: The mode to use when generating each HTML file.
    static func generateHTML(
        withTheme theme: Theme<Site>,
        indentation: Indentation.Kind? = nil,
        fileMode: HTMLFileMode = .foldersAndIndexFiles
    ) -> Self {
        step(named: "Generate HTML") { context in
            let generator = HTMLGenerator(
                theme: theme,
                indentation: indentation,
                fileMode: fileMode,
                context: context
            )

            try generator.generate()
        }
    }

    /// Generate an RSS feed for the website.
    /// - parameter includedSectionIDs: The IDs of the sections which items
    ///   to include when generating the feed.
    /// - parameter itemPredicate: A predicate used to determine whether to
    ///   include a given item within the generated feed (default: include all).
    /// - parameter config: The configuration to use when generating the feed.
    /// - parameter date: The date that should act as the build and publishing
    ///   date for the generated feed (default: the current date).
    static func generateRSSFeed(
        including includedSectionIDs: Set<Site.SectionID>,
        itemPredicate: Predicate<Item<Site>>? = nil,
        config: RSSFeedConfiguration = .default,
        date: Date = Date()
    ) -> Self {
        guard !includedSectionIDs.isEmpty else { return .empty }

        return step(named: "Generate RSS feed") { context in
            let generator = RSSFeedGenerator(
                includedSectionIDs: includedSectionIDs,
                itemPredicate: itemPredicate,
                config: config,
                context: context,
                date: date
            )

            try generator.generate()
        }
    }

    /// Generate a site map for the website, which is an XML file used
    /// for search engine indexing.
    /// - parameter excludedPaths: Any paths to exclude from the site map.
    ///   Adding a section's path to the list removes the entire section, including all its items.
    /// - parameter indentation: How the site map should be indented.
    static func generateSiteMap(excluding excludedPaths: Set<Path> = [],
                                indentedBy indentation: Indentation.Kind? = nil) -> Self {
        step(named: "Generate site map") { context in
            let generator = SiteMapGenerator(
                excludedPaths: excludedPaths,
                indentation: indentation,
                context: context
            )

            try generator.generate()
        }
    }
}

public extension PublishingStep where Site.ItemMetadata: PodcastCompatibleWebsiteItemMetadata {
    /// Generate a podcast feed for one of the website's sections.
    /// Note that all of the items within the given section must define `podcast`
    /// and `audio` metadata, or an error will be thrown.
    /// - parameter section: The section to generate a podcast feed for.
    /// - parameter itemPredicate: A predicate used to determine whether to
    ///   include a given item within the generated feed (default: include all).
    /// - parameter config: The configuration to use when generating the feed.
    /// - parameter date: The date that should act as the build and publishing
    ///   date for the generated feed (default: the current date).
    static func generatePodcastFeed(
        for section: Site.SectionID,
        itemPredicate: Predicate<Item<Site>>? = nil,
        config: PodcastFeedConfiguration<Site>,
        date: Date = Date()
    ) -> Self {
        step(named: "Generate podcast feed") { context in
            let generator = PodcastFeedGenerator(
                sectionID: section,
                itemPredicate: itemPredicate,
                config: config,
                context: context,
                date: date
            )

            try generator.generate()
        }
    }
}

// MARK: - Deployment

public extension PublishingStep {
    /// Deploy the website using a given method.
    /// This step will only run in case either the `-d` or `--deploy
    /// flag was passed on the command line, for example by using the
    /// `publish deploy` command.
    /// - parameter method: The method to use when deploying the website.
    static func deploy(using method: DeploymentMethod<Site>) -> Self {
        step(named: "Deploy using \(method.name)", kind: .deployment) { context in
            try method.body(context)
        }
    }
}

// MARK: - Implementation details

internal extension PublishingStep {
    enum Kind: String {
        case system
        case generation
        case deployment
    }

    enum Body {
        case empty
        case operation(name: String, closure: Closure)
        case group([PublishingStep])
    }
}

private extension PublishingStep {
    static func step(named name: String,
                     kind: Kind,
                     body: @escaping Closure) -> Self {
        PublishingStep(
            kind: kind,
            body: .operation(name: name, closure: body)
        )
    }
}
