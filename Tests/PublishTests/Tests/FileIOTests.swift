/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Foundation
import Publish
import Files
import Synchronization

@Suite("FileIO", .serialized) struct FileIOTests: PublishTestCase {
    @Test func testCopyingFile() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(named: "File").write("Hello, world!")

        try publishWebsite(in: folder, using: [
            .copyFile(at: "File")
        ])

        let file = try folder.file(at: "Output/File")
        #expect(try file.readAsString() ==  "Hello, world!")
    }

    @Test func testCopyingFileToSpecificFolder() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(named: "File").write("Hello, world!")

        try publishWebsite(in: folder, using: [
            .copyFile(at: "File", to: "Custom/Path")
        ])

        let file = try folder.file(at: "Output/Custom/Path/File")
        #expect(try file.readAsString() ==  "Hello, world!")
    }

    @Test func testCopyingFolder() throws {
        let folder = try Folder.createTemporary()
        try folder.createSubfolder(named: "Subfolder")

        try publishWebsite(in: folder, using: [
            .step(named: "Copy custom folder") { context in
                try context.copyFolderToOutput(from: "Subfolder")
            }
        ])

        _ = try folder.subfolder(at: "Output/Subfolder")
    }

    @Test func testCopyingResourcesWithFolder() throws {
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
        #expect(try rootFile.readAsString() ==  "Hello")
        #expect(try nestedFile.readAsString() ==  "World!")
    }

    @Test func testCopyingResourcesWithoutFolder() throws {
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
        #expect(try rootFile.readAsString() ==  "Hello")
        #expect(try nestedFile.readAsString() ==  "World!")
    }

    @Test func testCreatingRootLevelFolder() throws {
        let folder = try Folder.createTemporary()

        try publishWebsite(in: folder, using: [
            .step(named: "Create folder") { context in
                _ = try context.createFolder(at: "A")
                _ = try context.createFile(at: "B/file")
            }
        ])

        _ = try folder.subfolder(named: "A")
        _ = try folder.file(at: "B/file")
    }

    @Test func testRetrievingOutputFolder() throws {
        let folder = try Folder.createTemporary()
        let firstSectionFolder = Mutex<Folder?>(nil as Folder?)

        try publishWebsite(in: folder, using: [
            .generateHTML(withTheme: .foundation),
            .step(named: "Get output folder") { context in
                try firstSectionFolder.withLock { $0 = try context.outputFolder(at: "one") }
            }
        ])

        let firstSectionFolderName = firstSectionFolder.withLock(\.?.name)
        #expect(firstSectionFolderName ==  "one")
    }

    @Test func testRetrievingOutputFile() throws {
        let folder = try Folder.createTemporary()
        let itemFile = Mutex<File?>(nil)

        try publishWebsite(in: folder, using: [
            .addItem(.stub(withPath: "item")),
            .generateHTML(withTheme: .foundation),
            .step(named: "Get output file") { context in
                try itemFile.withLock { $0 = try context.outputFile(at: "one/item/index.html") }
            }
        ])

        let itemFileName = itemFile.withLock(\.?.name)
        #expect(itemFileName ==  "index.html")
    }

    @Test func testCleaningHiddenFilesInOutputFolder() throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(at: "Output/.hidden")

        try publishWebsite(in: folder, using: [
            .step(named: "Do nothing") { _ in }
        ])

        #expect(folder.containsFile(named: "Output/.hidden") == false)
    }
}
