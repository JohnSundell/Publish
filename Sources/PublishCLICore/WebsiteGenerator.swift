/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Files
import ShellOut

internal struct WebsiteGenerator {
    let folder: Folder

    func generate() throws {
        try folder.verifyAsSwiftPackage()

        try shellOut(
            to: "swift run",
            at: folder.path,
            outputHandle: FileHandle.standardOutput,
            errorHandle: FileHandle.standardError
        )
    }
}
