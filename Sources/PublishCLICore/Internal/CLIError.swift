/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

internal enum CLIError: Error {
    case newProjectFolderNotEmpty
    case notASwiftPackage
    case failedToResolveSwiftPackageName
    case outputFolderNotFound
    case failedToStartLocalhostServer(Error)
}

extension CLIError: CustomStringConvertible {
    var description: String {
        switch self {
        case .newProjectFolderNotEmpty:
            return "New projects can only be generated in empty folders."
        case .notASwiftPackage:
            return "The current folder is not a Swift package."
        case .failedToResolveSwiftPackageName:
            return "Failed to resolve the Swift package's name."
        case .outputFolderNotFound:
            return "The website's Output folder couldn't be found."
        case .failedToStartLocalhostServer(let error):
            return "Failed to start localhost server (\(error))"
        }
    }
}
