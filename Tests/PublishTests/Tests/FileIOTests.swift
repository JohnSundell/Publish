/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
@testable import Publish
import Files
import Plot

final class FileIOTests: PublishTestCase {
    func testCopyingFile() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(named: "File").write("Hello, world!")

        try publishWebsite(in: folder, using: [
            .copyFile(at: "File")
        ])

        let intermediateFolder = try folder.subfolder(at: ".intermediate")
        let file = try intermediateFolder.file(at: "Output/File")
        XCTAssertEqual(try file.readAsString(), "Hello, world!")
    }

    func testCopyingFileToSpecificFolder() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(named: "File").write("Hello, world!")

        try publishWebsite(in: folder, using: [
            .copyFile(at: "File", to: "Custom/Path")
        ])

        let intermediateFolder = try folder.subfolder(at: ".intermediate")
        let file = try intermediateFolder.file(at: "Output/Custom/Path/File")
        XCTAssertEqual(try file.readAsString(), "Hello, world!")
    }

    func testCopyingFolder() throws {
        let folder = try Folder.createTemporary()
        try folder.createSubfolder(named: "Subfolder")

        try publishWebsite(in: folder, using: [
            .step(named: "Copy custom folder") { context in
                try context.copyFolderToOutput(from: "Subfolder")
            }
        ])

        let intermediateFolder = try folder.subfolder(at: ".intermediate")
        XCTAssertNotNil(try? intermediateFolder.subfolder(at: "Output/Subfolder"))
    }

    func testCopyingResourcesWithFolder() throws {
        let folder = try Folder.createTemporary()

        try publishWebsite(in: folder, using: [
            .run { context in
                let resourcesFolder = try folder.createSubfolder(named: ".intermediate/Resources")
                try resourcesFolder.createFile(named: "File").write("Hello")
                let nestedFolder = try resourcesFolder.createSubfolder(named: "Subfolder")
                try nestedFolder.createFile(named: "Nested").write("World!")
            },
            .copyResources(includingFolder: true)
        ])

        let intermediateFolder = try folder.subfolder(at: ".intermediate")
        let rootFile = try intermediateFolder.file(at: "Output/Resources/File")
        let nestedFile = try intermediateFolder.file(at: "Output/Resources/Subfolder/Nested")
        XCTAssertEqual(try rootFile.readAsString(), "Hello")
        XCTAssertEqual(try nestedFile.readAsString(), "World!")
    }

    func testCopyingResourcesWithoutFolder() throws {
        let folder = try Folder.createTemporary()

        try publishWebsite(in: folder, using: [
            .run { context in
                let resourcesFolder = try folder.createSubfolder(named: ".intermediate/Resources")
                try resourcesFolder.createFile(named: "File").write("Hello")
                let nestedFolder = try resourcesFolder.createSubfolder(named: "Subfolder")
                try nestedFolder.createFile(named: "Nested").write("World!")

            },
            .copyResources()
        ])

        let intermediateFolder = try folder.subfolder(at: ".intermediate")
        let rootFile = try intermediateFolder.file(at: "Output/File")
        let nestedFile = try intermediateFolder.file(at: "Output/Subfolder/Nested")
        XCTAssertEqual(try rootFile.readAsString(), "Hello")
        XCTAssertEqual(try nestedFile.readAsString(), "World!")
    }

    func testCreatingRootLevelFolder() throws {
        let folder = try Folder.createTemporary()

        try publishWebsite(in: folder, using: [
            .step(named: "Create folder") { context in
                _ = try context.createFolder(at: "A")
                _ = try context.createFile(at: "B/file")
            }
        ])

        let intermediateFolder = try folder.subfolder(at: ".intermediate")
        XCTAssertNotNil(try? intermediateFolder.subfolder(named: "A"))
        XCTAssertNotNil(try? intermediateFolder.file(at: "B/file"))
    }

    func testRetrievingOutputFolder() throws {
        let folder = try Folder.createTemporary()
        var firstSectionFolder: Folder?

        try publishWebsite(in: folder, using: [
            .generateHTML(withTheme: .foundation),
            .step(named: "Get output folder") { context in
                firstSectionFolder = try context.outputFolder(at: "one")
            }
        ])

        XCTAssertEqual(firstSectionFolder?.name, "one")
    }

    func testRetrievingOutputFile() throws {
        let folder = try Folder.createTemporary()
        var itemFile: File?

        try publishWebsite(in: folder, using: [
            .addItem(.stub(withPath: "item")),
            .generateHTML(withTheme: .foundation),
            .step(named: "Get output file") { context in
                itemFile = try context.outputFile(at: "one/item/index.html")
            }
        ])

        XCTAssertEqual(itemFile?.name, "index.html")
    }

    func testCopyingContentAndResourceFilesToIntermediateFolder() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(named: "not-copied-file").write("💥")
        let resourcesFolder = try folder.createSubfolder(named: "Resources")
        try resourcesFolder.createFile(named: "resource").write("I'm resource!")
        let contentFolder = try folder.createSubfolder(named: "Content")
        try contentFolder.createFile(named: "index.md").write("I'm index.md!")
        try contentFolder.createSubfolder(named: "nested").createFile(at: "nested.md").write("I'm nested.md!")

        try publishWebsite(in: folder, using: [
            .copyContentAndResourceFilesToIntermediateFolder()
        ])

        let intermediateFolder = try folder.subfolder(at: ".intermediate")
        XCTAssertNil(try? intermediateFolder.file(at: "not-copied-file"))
        XCTAssertEqual(try intermediateFolder.file(at: "Resources/resource").readAsString(), "I'm resource!")
        XCTAssertEqual(try intermediateFolder.file(at: "Content/index.md").readAsString(), "I'm index.md!")
        XCTAssertEqual(try intermediateFolder.file(at: "Content/nested/nested.md").readAsString(), "I'm nested.md!")
    }

    func testCopyingCustomThemeFilesToIntermediateFolder() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(named: "Package.swift")

        let customThemeFolder = try folder.createSubfolder(at: "theme-subfolder")
        let customThemeFile = try customThemeFolder.createFile(named: "MockTheme.swift")
        try customThemeFolder.createFile(named: "resource1").write("🎨")
        try customThemeFolder.createSubfolder(named: "subfolder").createFile(named: "nested-resource").write("🎨🎨")

        let customThemeResources = ThemeResources(
            paths: [
                "theme-subfolder/resource1",
                "theme-subfolder/subfolder/nested-resource"
            ],
            themeCreationPath: Path(customThemeFile.path)
        )

        try publishWebsite(in: folder, using: [
            .copyThemeResourcesToIntermediateFolder(resources: customThemeResources)
        ])

        let intermediateOutputFolder = try folder.subfolder(at: ".intermediate/Output")
        XCTAssertEqual(try intermediateOutputFolder.file(at: "resource1").readAsString(), "🎨")
        XCTAssertEqual(try intermediateOutputFolder.file(at: "nested-resource").readAsString(), "🎨🎨")
    }

    func testCopyingIntermediateOutputToFinalDestination() throws {
        let destinationFolder = try Folder.createTemporary()

        try publishWebsite(in: destinationFolder, using: [
            .run { context in
                let intermediateOutputFolder = try destinationFolder.subfolder(at: ".intermediate/Output")
                try intermediateOutputFolder.createFile(named: "File").write("Hello, world!")
                let subfolder = try intermediateOutputFolder.createSubfolder(named: "Subfolder")
                try subfolder.createFile(named: "Nested").write("World!")
            },
            .copyIntermediateOutputToFinalDestination()
        ])

        let destinationOutput = try destinationFolder.subfolder(at: "Output")
        let file = try destinationOutput.file(at: "File")
        let nestedFile = try destinationOutput.file(at: "Subfolder/Nested")
        XCTAssertEqual(try file.readAsString(), "Hello, world!")
        XCTAssertEqual(try nestedFile.readAsString(), "World!")
    }
}

extension FileIOTests {
    static var allTests: Linux.TestList<FileIOTests> {
        [
            ("testCopyingFile", testCopyingFile),
            ("testCopyingFileToSpecificFolder", testCopyingFileToSpecificFolder),
            ("testCopyingFolder", testCopyingFolder),
            ("testCopyingResourcesWithFolder", testCopyingResourcesWithFolder),
            ("testCopyingResourcesWithoutFolder", testCopyingResourcesWithoutFolder),
            ("testCreatingRootLevelFolder", testCreatingRootLevelFolder),
            ("testRetrievingOutputFolder", testRetrievingOutputFolder),
            ("testRetrievingOutputFile", testRetrievingOutputFile),
            ("testCopyingIntermediateOutputToFinalDestination", testCopyingIntermediateOutputToFinalDestination),
            ("testCopyingCustomThemeFilesToIntermediateFolder", testCopyingCustomThemeFilesToIntermediateFolder),
            ("testCopyingContentAndResourceFilesToIntermediateFolder", testCopyingContentAndResourceFilesToIntermediateFolder)
        ]
    }
}
