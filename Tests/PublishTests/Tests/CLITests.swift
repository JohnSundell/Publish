/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import PublishCLICore
import Files
import ShellOut

final class CLITests: PublishTestCase {
    func testWebsiteProjectGeneration() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary()
        try makeCLI(in: folder, command: "new").run(in: folder)
        try makeCLI(in: folder, command: "generate").run(in: folder)
        #endif
    }

    func testPluginProjectGeneration() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "Name")
        try makeCLI(in: folder, command: "new", "plugin").run(in: folder)

        XCTAssertTrue(folder.containsFile(at: "Sources/Name/Name.swift"))
        XCTAssertEqual(try folder.getPackageName(), "Name")

        // Make sure that the project can build
        try shellOut(to: "swift build", at: folder.path)
        #endif
    }

    func testSiteName() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "Name")
        try makeCLI(in: folder, command: "new").run(in: folder)
        XCTAssertEqual(try folder.getPackageName(), "Name")
        #endif
    }
    
    func testSiteNameFromLowercasedFolderName() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "name")
        try makeCLI(in: folder, command: "new").run(in: folder)
        XCTAssertEqual(try folder.getPackageName(), "Name")
        #endif
    }
    
    func testSiteNameFromFolderNameStartingWithDigit() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "1-name")
        try makeCLI(in: folder, command: "new").run(in: folder)
        XCTAssertEqual(try folder.getPackageName(), "Name")
        #endif
    }
    
    func testSiteNameFromCamelCaseFolderName() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "CamelCaseName")
        try makeCLI(in: folder, command: "new").run(in: folder)
        XCTAssertEqual(try folder.getPackageName(), "CamelCaseName")
        #endif
    }

    func testSiteNameWithNonLetterValidCharactersFolderName() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "Blog.CamelCaseName2.com")
        try makeCLI(in: folder, command: "new").run(in: folder)
        XCTAssertEqual(try folder.getPackageName(), "BlogCamelCaseName2Com")
        #endif
    }
    
    func testSiteNameFromFolderNameWithNonLetters() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "My website 1")
        try makeCLI(in: folder, command: "new").run(in: folder)
        XCTAssertEqual(try folder.getPackageName(), "MyWebsite")
        #endif
    }
    
    func testSiteNameFromDigitsOnlyFolderName() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "1")
        try makeCLI(in: folder, command: "new").run(in: folder)
        let name = try folder.getPackageName()
        XCTAssertFalse(name.isEmpty)
        #endif
    }
}

extension CLITests {
    static var allTests: Linux.TestList<CLITests> {
        [
            ("testWebsiteProjectGeneration", testWebsiteProjectGeneration),
            ("testPluginProjectGeneration", testPluginProjectGeneration),
            ("testSiteName", testSiteName),
            ("testSiteNameFromLowercasedFolderName", testSiteNameFromLowercasedFolderName),
            ("testSiteNameFromFolderNameStartingWithDigit", testSiteNameFromFolderNameStartingWithDigit),
            ("testSiteNameFromCamelCaseFolderName", testSiteNameFromCamelCaseFolderName),
            ("testSiteNameWithNonLetterValidCharactersFolderName", testSiteNameWithNonLetterValidCharactersFolderName),
            ("testSiteNameFromFolderNameWithNonLetters", testSiteNameFromFolderNameWithNonLetters),
            ("testSiteNameFromDigitsOnlyFolderName", testSiteNameFromDigitsOnlyFolderName)
        ]
    }
}

private extension CLITests {
    func makeCLI(in folder: Folder, command: String...) throws -> CLI {
        let thisFile = try File(path: "\(#file)")
        let pathSuffix = "/Tests/PublishTests/Tests/CLITests.swift"

        let repositoryFolder = try Folder(
            path: String(thisFile.path.dropLast(pathSuffix.count))
        )

        return CLI(
            arguments: [folder.path] + command,
            publishRepositoryURL: URL(
                fileURLWithPath: repositoryFolder.path
            ),
            publishVersion: "0.1.0"
        )
    }
}

private extension Folder {
    static func createTemporary(named: String) throws -> Self {
        let folder = try Folder.createTemporary()
        return try folder.createSubfolder(named: named)
    }
    
    func getPackageName() throws -> String {
        let sourcesFolder = try subfolder(named: "Sources")
        return try require(sourcesFolder.subfolders.first?.name)
    }
}
