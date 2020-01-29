/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish
import Files

final class FileIOTests: PublishTestCase {
    func testCopyingFile() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(named: "File").write("Hello, world!")

        try publishWebsite(in: folder, using: [
            .copyFile(at: "File")
        ])

        let file = try folder.file(at: "Output/File")
        XCTAssertEqual(try file.readAsString(), "Hello, world!")
    }

    func testCopyingFileToSpecificFolder() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(named: "File").write("Hello, world!")

        try publishWebsite(in: folder, using: [
            .copyFile(at: "File", to: "Custom/Path")
        ])

        let file = try folder.file(at: "Output/Custom/Path/File")
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

        XCTAssertNotNil(try? folder.subfolder(at: "Output/Subfolder"))
    }

    func testCopyingResourcesWithFolder() throws {
        let folder = try Folder.createTemporary()
        let resourcesFolder = try folder.createSubfolder(named: "Resources")
        try resourcesFolder.createFile(named: "File").write("Hello")
        let nestedFolder = try resourcesFolder.createSubfolder(named: "Subfolder")
        try nestedFolder.createFile(named: "Nested").write("World!")

        try publishWebsite(in: folder, using: [
            .copyResources(includingFolder: true)
        ])

        let rootFile = try folder.file(at: "Output/Resources/File")
        let nestedFile = try folder.file(at: "Output/Resources/Subfolder/Nested")
        XCTAssertEqual(try rootFile.readAsString(), "Hello")
        XCTAssertEqual(try nestedFile.readAsString(), "World!")
    }

    func testCopyingResourcesWithoutFolder() throws {
        let folder = try Folder.createTemporary()
        let resourcesFolder = try folder.createSubfolder(named: "Resources")
        try resourcesFolder.createFile(named: "File").write("Hello")
        let nestedFolder = try resourcesFolder.createSubfolder(named: "Subfolder")
        try nestedFolder.createFile(named: "Nested").write("World!")

        try publishWebsite(in: folder, using: [
            .copyResources()
        ])

        let rootFile = try folder.file(at: "Output/File")
        let nestedFile = try folder.file(at: "Output/Subfolder/Nested")
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

        XCTAssertNotNil(try? folder.subfolder(named: "A"))
        XCTAssertNotNil(try? folder.file(at: "B/file"))
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

    func testCleaningHiddenFilesInOutputFolder() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(at: "Output/.hidden")

        try publishWebsite(in: folder, using: [
            .step(named: "Do nothing") { _ in }
        ])

        XCTAssertFalse(folder.containsFile(named: "Output/.hidden"))
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
            ("testCleaningHiddenFilesInOutputFolder", testCleaningHiddenFilesInOutputFolder)
        ]
    }
}
