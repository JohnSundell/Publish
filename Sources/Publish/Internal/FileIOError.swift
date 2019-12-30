/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

internal struct FileIOError: Error {
    var path: Path
    var reason: Reason
}

extension FileIOError {
    enum Reason {
        case rootFolderNotFound
        case folderNotFound
        case folderCreationFailed
        case folderCopyingFailed
        case fileNotFound
        case fileCreationFailed
        case fileCouldNotBeRead
        case fileCopyingFailed
        case deploymentFolderSetupFailed(Error)
    }
}

extension FileIOError: PublishingErrorConvertible {
    func publishingError(forStepNamed stepName: String?) -> PublishingError {
        PublishingError(
            stepName: stepName,
            path: path,
            infoMessage: infoMessage,
            underlyingError: underlyingError
        )
    }
}

private extension FileIOError {
    var infoMessage: String {
        switch reason {
        case .rootFolderNotFound:
            return "The project's root folder could not be found"
        case .folderNotFound:
            return "Folder not found"
        case .folderCreationFailed:
            return "Failed to create folder"
        case .folderCopyingFailed:
            return "The folder could not be copied"
        case .fileNotFound:
            return "File not found"
        case .fileCreationFailed:
            return "Failed to create file"
        case .fileCouldNotBeRead:
            return "The file could not be read"
        case .fileCopyingFailed:
            return "The file could not be copied"
        case .deploymentFolderSetupFailed:
            return "Failed to setup deployment folder."
        }
    }

    var underlyingError: Error? {
        switch reason {
        case .rootFolderNotFound, .folderNotFound,
             .folderCreationFailed, .folderCopyingFailed,
             .fileNotFound, .fileCreationFailed,
             .fileCouldNotBeRead, .fileCopyingFailed:
            return nil
        case .deploymentFolderSetupFailed(let error):
            return error
        }
    }
}
