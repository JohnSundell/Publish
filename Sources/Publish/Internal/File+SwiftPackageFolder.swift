/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Files

internal extension File {
    func resolveSwiftPackageFolder() throws -> Folder {
        var nextFolder = parent

        while let currentFolder = nextFolder {
            if currentFolder.containsFile(named: "Package.swift") {
                return currentFolder
            }

            nextFolder = currentFolder.parent
        }

        throw PublishingError(
            path: Path(path),
            infoMessage: "Could not resolve Swift package folder"
        )
    }
}
