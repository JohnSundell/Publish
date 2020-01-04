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
    private let siteName: String

    init(folder: Folder,
         publishRepositoryURL: URL,
         publishVersion: String) {
        self.folder = folder
        self.publishRepositoryURL = publishRepositoryURL
        self.publishVersion = publishVersion
        self.siteName = folder.name.asSiteName()
    }

    func generate() throws {
        guard folder.files.first == nil, folder.subfolders.first == nil else {
            throw CLIError.newProjectFolderNotEmpty
        }

        try generateGitIgnore()
        try generateResourcesFolder()
        try generateContentFolder()
        try generatePackageFile()
        try generateMainFile()

        print("""
        ✅ Generated website project for '\(siteName)'
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
        try folder.createIndexFile(withMarkdown: "# Welcome to \(siteName)!")

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
        // swift-tools-version:5.1

        import PackageDescription

        let package = Package(
            name: "\(siteName)",
            products: [
                .executable(name: "\(siteName)", targets: ["\(siteName)"])
            ],
            dependencies: [
                .package(\(dependencyString))
            ],
            targets: [
                .target(
                    name: "\(siteName)",
                    dependencies: ["Publish"]
                )
            ]
        )
        """)
    }

    func generateMainFile() throws {
        let path = "Sources/\(siteName)/main.swift"

        try folder.createFileIfNeeded(at: path).write("""
        import Foundation
        import Publish
        import Plot

        // This type acts as the configuration for your website.
        struct \(siteName): Website {
            enum SectionID: String, WebsiteSectionID {
                // Add the sections that you want your website to contain here:
                case posts
            }

            struct ItemMetadata: WebsiteItemMetadata {
                // Add any site-specific metadata that you want to use here.
            }

            // Update these properties to configure your website:
            var url = URL(string: "https://your-website-url.com")!
            var name = "\(siteName)"
            var description = "A description of \(siteName)"
            var language: Language { .english }
            var imagePath: Path? { nil }
        }

        // This will generate your website using the built-in Foundation theme:
        try \(siteName)().publish(withTheme: .foundation)
        """)
    }
}

private extension Folder {
    func createIndexFile(withMarkdown markdown: String) throws {
        try createFile(named: "index.md").write(markdown)
    }
}

private extension String {
    func asSiteName() -> Self {
        let letters = filter { $0.isLetter }
        guard !letters.isEmpty else {
            return "SiteName"
        }
        return String(letters).capitalizingFirstLetter()
    }
    
    private func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}
