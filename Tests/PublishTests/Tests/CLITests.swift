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
    func testProjectGeneration() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary()
        try makeCLI(in: folder, command: "init").run(in: folder)
		try makeCLI(in: folder, command: "new ATestContent").run(in: folder)
        try makeCLI(in: folder, command: "generate").run(in: folder)
        #endif
    }
}

extension CLITests {
    static var allTests: Linux.TestList<CLITests> {
        [
            ("testProjectGeneration", testProjectGeneration)
        ]
    }
}

private extension CLITests {
    func makeCLI(in folder: Folder, command: String) throws -> CLI {
        let thisFile = try File(path: "\(#file)")
        let pathSuffix = "/Tests/PublishTests/Tests/CLITests.swift"

        let repositoryFolder = try Folder(
            path: String(thisFile.path.dropLast(pathSuffix.count))
        )

        return CLI(
            arguments: [folder.path, command],
            publishRepositoryURL: URL(
                fileURLWithPath: repositoryFolder.path
            ),
            publishVersion: "0.1.0"
        )
    }
}
