/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Files

internal extension Folder {
    func verifyAsSwiftPackage() throws {
        guard containsFile(named: "Package.swift") else {
            throw CLIError.notASwiftPackage
        }
    }
}
