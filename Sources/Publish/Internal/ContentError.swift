/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

internal struct ContentError: Error {
    var path: Path
    var reason: Reason
}

extension ContentError {
    enum Reason {
        case itemNotFound
        case itemMutationFailed(Error)
        case pageNotFound
        case pageMutationFailed(Error)
        case markdownMetadataDecodingFailed(
            context: DecodingError.Context?,
            valueFound: Bool
        )
    }
}

extension ContentError: PublishingErrorConvertible {
    func publishingError(forStepNamed stepName: String?) -> PublishingError {
        PublishingError(
            stepName: stepName,
            path: path,
            infoMessage: infoMessage,
            underlyingError: underlyingError
        )
    }
}

private extension ContentError {
    var infoMessage: String {
        switch reason {
        case .itemNotFound:
            return "No item found at '\(path)'."
        case .itemMutationFailed:
            return "Item mutation failed"
        case .pageNotFound:
            return "Page not found"
        case .pageMutationFailed:
            return "Page mutation failed"
        case .markdownMetadataDecodingFailed(let context, let valueFound):
            let key = context?.codingPath.map({ $0.stringValue }).joined(separator: ".")
            let keyString = key.map { "key '\($0)'" } ?? "unknown key"
            let adjective = valueFound ? "Invalid" : "Missing"
            return "\(adjective) metadata value for \(keyString)"
        }
    }

    var underlyingError: Error? {
        switch reason {
        case .itemNotFound, .pageNotFound, .markdownMetadataDecodingFailed:
            return nil
        case .itemMutationFailed(let error), .pageMutationFailed(let error):
            return error
        }
    }
}
