/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Files

internal struct ProjectGenerator {
    private let folder: Folder
    private let publishRepositoryURL: URL
    private let publishVersion: String
    private let kind: ProjectKind
    private let name: String

    init(folder: Folder,
         publishRepositoryURL: URL,
         publishVersion: String,
         kind: ProjectKind) {
        self.folder = folder
        self.publishRepositoryURL = publishRepositoryURL
        self.publishVersion = publishVersion
        self.kind = kind
        self.name = folder.name.asProjectName()
    }

    func generate() throws {
        guard folder.files.first == nil, folder.subfolders.first == nil else {
            throw CLIError.newProjectFolderNotEmpty
        }

        try generateGitIgnore()
        try generatePackageFile()

        switch kind {
        case .website:
            try generateResourcesFolder()
            try generateContentFolder()
            try generateMainFile()
        case .plugin:
            try generatePluginBoilerplate()
        }

        print("""
        ✅ Generated \(kind.rawValue) project for '\(name)'
        Run 'open Package.swift' to open it and start building
        """)
    }
}

private extension ProjectGenerator {
    func generateGitIgnore() throws {
        try folder.createFile(named: ".gitignore").write("""
        .DS_Store
        /build
        /.build
        /.swiftpm
        /*.xcodeproj
        .publish
        """)
    }

    func generateResourcesFolder() throws {
        try folder.createSubfolder(named: "Resources")
    }

    func generateContentFolder() throws {
        let folder = try self.folder.createSubfolder(named: "Content")
        try folder.createIndexFile(withMarkdown: "# Welcome to \(name)!")

        let postsFolder = try folder.createSubfolder(named: "posts")
        try postsFolder.createIndexFile(withMarkdown: "# My posts")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = .current

        try postsFolder.createFile(named: "first-post.md").write("""
        ---
        date: \(dateFormatter.string(from: Date()))
        description: A description of my first post.
        tags: first, article
        ---
        # My first post

        My first post's text.
        """)
    }

    func generatePackageFile() throws {
        let dependencyString: String
        let repositoryURL = publishRepositoryURL.absoluteString

        if repositoryURL.hasPrefix("http") || repositoryURL.hasPrefix("git@") {
            dependencyString = """
            url: "\(repositoryURL)", from: "\(publishVersion)"
            """
        } else {
            dependencyString = "path: \"\(publishRepositoryURL.path)\""
        }

        try folder.createFile(named: "Package.swift").write("""
        // swift-tools-version:5.2

        import PackageDescription

        let package = Package(
            name: "\(name)",
            products: [
                .\(kind.buildProduct)(
                    name: "\(name)",
                    targets: ["\(name)"]
                )
            ],
            dependencies: [
                .package(name: "Publish", \(dependencyString))
            ],
            targets: [
                .target(
                    name: "\(name)",
                    dependencies: ["Publish"]
                )
            ]
        )
        """)
    }

    func generateMainFile() throws {
        let path = "Sources/\(name)/main.swift"

        try folder.createFileIfNeeded(at: path).write("""
        import Foundation
        import Publish
        import Plot

        // This type acts as the configuration for your website.
        struct \(name): Website {
            enum SectionID: String, WebsiteSectionID {
                // Add the sections that you want your website to contain here:
                case posts
            }

            struct ItemMetadata: WebsiteItemMetadata {
                // Add any site-specific metadata that you want to use here.
            }

            // Update these properties to configure your website:
            var url = URL(string: "https://your-website-url.com")!
            var name = "\(name)"
            var description = "A description of \(name)"
            var language: Language { .english }
            var imagePath: Path? { nil }
        }

        // This will generate your website using the built-in Foundation theme:
        try \(name)().publish(withTheme: .foundation)
        """)
    }

    func generatePluginBoilerplate() throws {
        let path = "Sources/\(name)/\(name).swift"
        let methodName = name[name.startIndex].lowercased() + name.dropFirst()

        try folder.createFileIfNeeded(at: path).write("""
        import Publish

        public extension Plugin {
            /// Documentation for your plugin
            static func \(methodName)() -> Self {
                Plugin(name: "\(name)") { context in
                    // Perform your plugin's work
                }
            }
        }
        """)
    }
}

private extension ProjectKind {
    var buildProduct: String {
        switch self {
        case .website:
            return "executable"
        case .plugin:
            return "library"
        }
    }
}

private extension Folder {
    func createIndexFile(withMarkdown markdown: String) throws {
        try createFile(named: "index.md").write(markdown)
    }
}

private extension String {
    func asProjectName() -> Self {
        let validCharacters = CharacterSet.alphanumerics
        let validEdgeCharacters = CharacterSet.letters
        let validSegments = trimmingCharacters(in: validEdgeCharacters.inverted)
            .components(separatedBy: validCharacters.inverted)

        guard
            let firstSegment = validSegments.first,
            !firstSegment.isEmpty else {
            return "SiteName"
        }

        return validSegments
            .map { $0.capitalizingFirstLetter() }
            .joined()
    }
    
    private func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}
