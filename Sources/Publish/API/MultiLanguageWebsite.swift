import Foundation
import Plot

/// Protocol that all `MultiLanguageWebsite.ItemMetadata` implementations must conform to.
public protocol MultiLanguageWebsiteItemMetadata : WebsiteItemMetadata {
    /// A unique identifier for the same items in different languages to correlate the items.
    var alternateLinkIdentifier: String? { get set }
}

/// Protocol used to define a Publish-based multi-language website.
/// You conform to this protocol using a custom type, which is then used to
/// infer various information about your website when generating its various
/// HTML pages and resources. A website is then published using a pipeline made
/// up of `PublishingStep` values, which is constructed using the `publish` method.
/*/// To generate the necessary bootstrapping for conforming to this protocol, use
/// the `publish new` command line tool.*/
//todo: make cli, write document
public protocol MultiLanguageWebsite: Website where ItemMetadata: MultiLanguageWebsiteItemMetadata {
    /// Languages of the website to generate. The first language becomes default language.
    /// Can't be empty.
    var languages: [Language] { get }
    /// The folder name of the markdown files of each language.
    /// Default implementation returns language code defined in ISO 639.
    /// - Parameter language: The language of the files in returned folder.
    func contentFolder(for language: Language) -> String
    /// The prefix of the path of items in different languages.
    /// Default implementation returns language code defined in ISO 639.
    /// e.g. the `en ` in `https://example.com/en/index` for English.
    /// - Parameter language: The language of the prefix.
    func pathPrefix(for language: Language) -> String
}

// MARK: - Default implementations

public extension MultiLanguageWebsite {
    /// Default language of the website.
    var language: Language { languages.first! }
    
    func contentFolder(for language: Language) -> String {
        language.rawValue
    }
    
    func pathPrefix(for language: Language) -> String {
        language.rawValue
    }
    
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
                .copyDefaultIndexHtml(),
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

public extension MultiLanguageWebsite {
    /// The path for the location, in specified language.
    /// - Parameter language: Specified Language.
    func path(for location: Location) -> Path {
        if let index = location as? Index {
            return self.path(for: index)
        }
        if let section = location as? Section<Self> {
            return self.path(for: section)
        }
        if let item = location as? Item<Self> {
            return self.path(for: item)
        }
        if let page = location as? Page {
            return self.path(for: page)
        }
        if location is TagListPage {
            return self.tagListPath(in: location.language!)
        }
        if let tag = location as? TagDetailsPage {
            return self.path(for: tag.tag, in: tag.language!)
        }
        return location.path
    }
    
    /// The path for the website's tag list page in the specified language.
    /// - Parameter language: Specified Language.
    func tagListPath(in language: Language) -> Path {
        Path(pathPrefix(for: language)).appendingComponent(tagListPath.string+"/")
    }
    
    /// Return the relative path for a given section ID in the specified language.
    /// - parameter sectionID: The section ID to return a path for.
    /// - Parameter language: Specified Language.
    func path(for sectionID: SectionID, in language: Language) -> Path {
        Path(pathPrefix(for: language)).appendingComponent(path(for: sectionID).string+"/")
    }
    
    /// Return the relative path for a given tag in specified language.
    /// - parameter tag: The tag to return a path for.
    /// - Parameter language: Specified Language.
    func path(for tag: Tag, in language: Language) -> Path {
        let basePath = Path(pathPrefix(for: language))
            .appendingComponent((tagHTMLConfig?.basePath ?? .defaultForTagHTML).string)
        // decomposedStringWithCanonicalMapping is used to fix encoding incompatibility of Japanese url.
        // e.g. が => か゛
        return language == .japanese ? basePath.appendingComponent(tag.normalizedString().decomposedStringWithCanonicalMapping + "/") : basePath.appendingComponent(tag.normalizedString() + "/")
    }
    
    /// Return the absolute URL for a given tag in specified language.
    /// - parameter tag: The tag to return a URL for.
    /// - Parameter language: Specified Language.
    func url(for tag: Tag, in language: Language) -> URL {
        url(for: path(for: tag), in: language)
    }
    
    /// Return the absolute URL for a given path.
    /// - parameter path: The path to return a URL for.
    func url(for path: Path, in language: Language) -> URL {
        guard !path.string.isEmpty else { return url }
        if language == .japanese {
            return url.appendingPathComponent("\(pathPrefix(for: language))/\(path.string.decomposedStringWithCanonicalMapping)/")
        }
        return url.appendingPathComponent("\(pathPrefix(for: language))/\(path.string)/")
    }
    
    /// Return the absolute URL for a given location.
    /// - parameter location: The location to return a URL for.
    func url(for location: Location) -> URL {
        if let index = location as? Index {
            return url(for: index, in: location.language!)
        }
        return url(for: location.path, in: location.language!)
    }
    
    /// Return the relative path for a given item.
    /// - parameter item: The item to return a path for.
    /// - Parameter language: Specified Language.
    func path(for item: Item<Self>) -> Path {
        let language = item.language ?? self.language
        if language == .japanese {
            return Path(pathPrefix(for: language)).appendingComponent("\(item.sectionID.rawValue)/\(item.relativePath.string.decomposedStringWithCanonicalMapping)/")
        } else {
            return Path(pathPrefix(for: language)).appendingComponent("\(item.sectionID.rawValue)/\(item.relativePath)/")
        }
    }
    
    /// Return the relative path for a given section.
    /// - parameter section: The section to return a path for.
    /// - Parameter language: Specified Language.
    func path(for section: Section<Self>) -> Path {
        Path("\(pathPrefix(for: section.language!))/\(section.id.rawValue)/")
    }
    
    /// Return the relative path for a given index.
    /// - parameter section: The section to return a path for.
    func path(for index: Index) -> Path {
        Path("\(pathPrefix(for: index.language!))/index.html")
    }
    
    /// Return the relative path for a given page.
    /// - parameter page: The page to return a path for.
    func path(for page: Page) -> Path {
        Path("\(pathPrefix(for: page.language!))/\(page.path)/")
    }
    
    /// Return the absolute URL for a given path.
    /// - parameter path: The path to return a URL for.
    func url(for index: Index, in language: Language) -> URL {
        url.appendingPathComponent(pathPrefix(for: language)+"/")
    }
}
