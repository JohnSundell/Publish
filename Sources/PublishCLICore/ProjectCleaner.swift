/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Files
import Foundation
import ShellOut

internal struct ProjectCleaner {

    private let folder: Folder

    init(folder: Folder) {
        self.folder = folder
    }

    func clean() throws {
        try shellOut(
            to: "rm -rf .build/",
            at: folder.path,
            outputHandle: FileHandle.standardOutput,
            errorHandle: FileHandle.standardError
        )
    }
}
