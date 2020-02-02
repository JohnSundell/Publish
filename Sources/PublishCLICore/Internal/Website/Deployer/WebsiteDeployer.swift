/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Files
import ShellOut
import Codextended

internal struct WebsiteDeployer {
    let folder: Folder

    func deploy() throws {
        let name = try resolvePackageName()

        try shellOut(
            to: "swift run \(name) --deploy",
            at: folder.path,
            outputHandle: FileHandle.standardOutput,
            errorHandle: FileHandle.standardError
        )
    }
}

private extension WebsiteDeployer {
    struct PackageDescription: Decodable {
        var name: String
    }

    func resolvePackageName() throws -> String {
        try folder.verifyAsSwiftPackage()

        do {
            let string = try shellOut(to: "swift package describe --type json")
            let data = Data(string.utf8)
            let description = try data.decoded() as PackageDescription
            return description.name
        } catch {
            throw CLIError.failedToResolveSwiftPackageName
        }
    }
}
