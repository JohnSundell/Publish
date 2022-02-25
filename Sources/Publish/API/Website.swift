/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot
import Files

/// Protocol that all `Website.SectionID` implementations must conform to.
public protocol WebsiteSectionID: Decodable, Hashable, CaseIterable, RawRepresentable where RawValue == String {}
/// Protocol that all `Website.ItemMetadata` implementations must conform to.
public typealias WebsiteItemMetadata = Decodable & Hashable

/// Protocol used to define a Publish-based website.
/// You conform to this protocol using a custom type, which is then used to
/// infer various information about your website when generating its various
/// HTML pages and resources. A website is then published using a pipeline made
/// up of `PublishingStep` values, which is constructed using the `publish` method.
/// To generate the necessary bootstrapping for conforming to this protocol, use
/// the `publish new` command line tool.
public protocol Website {
    /// The enum type used to represent the website's section IDs.
    associatedtype SectionID: WebsiteSectionID
    /// The type that defines any custom metadata for the website.
    associatedtype ItemMetadata: WebsiteItemMetadata

    /// The absolute URL that the website will be hosted at.
    var url: URL { get }
    /// The name of the website.
    var name: String { get }
    /// A description of the website.
    var description: String { get }
    /// The website's primary language.
    var language: Language { get }
    /// Any path to an image that represents the website.
    var imagePath: Path? { get }
    /// The website's favicon, if any.
    var favicon: Favicon? { get }
    /// The configuration to use when generating tag HTML for the website.
    /// If this is `nil`, then no tag HTML will be generated.
    var tagHTMLConfig: TagHTMLConfiguration? { get }
    /// File or folder names to exclude when publishing the site. Regular expressions may be used.
    /// - Bare strings with no regexp-related characters will be matched exactly. For example `"templates"` will ignore anything named `templates` but not something named `templates1` or `my templates`, etc.
    /// - Wildcards are allowed and follow usual regular expression meanings. For example, `templates.*` means to ignore anything that starts with `templates` and includes zero or more characters after `templates`.
    /// - It's not necessary to use `^` or `$` to indicate the start or end of a regular expression, but it's not harmful either.
    /// If a folder is ignored, everything in that folder will be ignored, regardless of whether the folder contents match anything in `ignoredPaths`.
    var ignoredPaths: [String]? { get }
}

// MARK: - Defaults

public extension Website {
    var favicon: Favicon? { .init() }
    var tagHTMLConfig: TagHTMLConfiguration? { .default }
}

// MARK: - Publishing

public extension Website {
    /// Publish this website using a default pipeline. To build a completely
    /// custom pipeline, use the `publish(using:)` method.
    /// - parameter theme: The HTML theme to generate the website using.
    /// - parameter indentation: How to indent the generated files.
    /// - parameter path: Any specific path to generate the website at.
    /// - parameter rssFeedSections: What sections to include in the site's RSS feed.
    /// - parameter rssFeedConfig: The configuration to use for the site's RSS feed.
    /// - parameter deploymentMethod: How to deploy the website.
    /// - parameter additionalSteps: Any additional steps to add to the publishing
    ///   pipeline. Will be executed right before the HTML generation process begins.
    /// - parameter plugins: Plugins to be installed at the start of the publishing process.
    /// - parameter file: The file that this method is called from (auto-inserted).
    /// - parameter line: The line that this method is called from (auto-inserted).
    @discardableResult
    func publish(withTheme theme: Theme<Self>,
                 indentation: Indentation.Kind? = nil,
                 at path: Path? = nil,
                 rssFeedSections: Set<SectionID> = Set(SectionID.allCases),
                 rssFeedConfig: RSSFeedConfiguration? = .default,
                 deployedUsing deploymentMethod: DeploymentMethod<Self>? = nil,
                 additionalSteps: [PublishingStep<Self>] = [],
                 plugins: [Plugin<Self>] = [],
                 file: StaticString = #file) throws -> PublishedWebsite<Self> {
        try publish(
            at: path,
            using: [
                .group(plugins.map(PublishingStep.installPlugin)),
                .optional(.copyResources()),
                .addMarkdownFiles(),
                .sortItems(by: \.date, order: .descending),
                .group(additionalSteps),
                .generateHTML(withTheme: theme, indentation: indentation),
                .unwrap(rssFeedConfig) { config in
                    .generateRSSFeed(
                        including: rssFeedSections,
                        config: config
                    )
                },
                .generateSiteMap(indentedBy: indentation),
                .unwrap(deploymentMethod, PublishingStep.deploy)
            ],
            file: file
        )
    }

    /// Publish this website using a custom pipeline.
    /// - parameter path: Any specific path to generate the website at.
    /// - parameter steps: The steps to use to form the website's publishing pipeline.
    /// - parameter file: The file that this method is called from (auto-inserted).
    /// - parameter line: The line that this method is called from (auto-inserted).
    @discardableResult
    func publish(at path: Path? = nil,
                 using steps: [PublishingStep<Self>],
                 file: StaticString = #file) throws -> PublishedWebsite<Self> {
        let pipeline = PublishingPipeline(
            steps: steps,
            originFilePath: Path("\(file)")
        )

        return try pipeline.execute(for: self, at: path)
    }
}

// MARK: - Paths and URLs

public extension Website {
    /// The path for the website's tag list page.
    var tagListPath: Path {
        tagHTMLConfig?.basePath ?? .defaultForTagHTML
    }

    /// Return the relative path for a given section ID.
    /// - parameter sectionID: The section ID to return a path for.
    func path(for sectionID: SectionID) -> Path {
        Path(sectionID.rawValue)
    }

    /// Return the relative path for a given tag.
    /// - parameter tag: The tag to return a path for.
    func path(for tag: Tag) -> Path {
        let basePath = tagHTMLConfig?.basePath ?? .defaultForTagHTML
        return basePath.appendingComponent(tag.normalizedString())
    }

    /// Return the absolute URL for a given tag.
    /// - parameter tag: The tag to return a URL for.
    func url(for tag: Tag) -> URL {
        url(for: path(for: tag))
    }

    /// Return the absolute URL for a given path.
    /// - parameter path: The path to return a URL for.
    func url(for path: Path) -> URL {
        guard !path.string.isEmpty else { return url }
        return url.appendingPathComponent(path.string)
    }

    /// Return the absolute URL for a given location.
    /// - parameter location: The location to return a URL for.
    func url(for location: Location) -> URL {
        url(for: location.path)
    }
    
    /// Make `ignoredPaths` optional.
    var ignoredPaths: [String]? { nil }
    
    /// Should the site ignore a file or folder with a specific name?
    /// - Parameter name: Name of a file or folder, commonly `file.name` or `folder.name`.
    /// - Returns: True if the web site should ignore the file/folder name
    ///
    /// Sites can indicate file/folder names to ignore using the `ignoredPaths` property. See that property for a discussion of how to use it.
    ///
    /// This function checks only strings and should be called with a file or folder name.
    func shouldIgnore(name: String) -> Bool {
        guard let ignoredPaths = ignoredPaths else { return false }
        return !ignoredPaths.filter({
            // Add `^` and `$` to the ends of the pattern to avoid unexpected matches. Matching something like "foo" anywhere in a filename requires wildcards, e.g. ".*foo.*". Extra line start/end markers don't affect matching, so there's no need to check for them before trying the pattern.
            name.range(of: "^\($0)$", options: .regularExpression) != nil
        }).isEmpty
    }
    
    /// Should the site ignore a `File` or `Folder`?
    /// - Returns: True if the site should ignore the `File`/`Folder`.
    ///
    /// Sites can indicate file/folder names to ignore using the `ignoredPaths` property. See that property for a discussion of how to use it.
    ///
    /// *This function checks all path components for the location.* A file or folder that doesn't match the ignore list could still be contained in a folder that does match. This function deals with this by checking all path components against the `ignoredPaths` list and returning true if any matches are found. If you want to check a file or folder's name without checking the entire path, use `shouldIgnore(name:)`
    func shouldIgnore<T: Files.Location>(_ location: T) -> Bool {
        location.pathComponents.reduce(false) { (_, component) in shouldIgnore(name: component) }
    }
}

extension Files.Location {
    // Used in `shouldIgnore<T: Files.Location>(_ location)`
    var pathComponents: [String] {
        path.split(separator: "/").map { String($0) }
    }
}
