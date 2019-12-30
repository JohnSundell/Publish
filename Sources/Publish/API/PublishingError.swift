/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Error type thrown as part of the website publishing process.
public struct PublishingError: Equatable {
    /// Any step that the error was encountered during.
    public var stepName: String?
    /// Any path that the error was encountered at.
    public var path: Path?
    /// An info message that gives more context about the error.
    public let infoMessage: String
    /// Any underlying error message that this error is based on.
    public var underlyingErrorMessage: String?

    /// Initialize a new error instance.
    /// - Parameter stepName: Any step that the error was encountered during.
    /// - Parameter path: Any path that the error was encountered at.
    /// - Parameter infoMessage: An info message that gives more context about the error.
    /// - Parameter underlyingError: Any underlying error message that this error is based on.
    public init(stepName: String? = nil,
                path: Path? = nil,
                infoMessage: String,
                underlyingError: Error? = nil) {
        self.stepName = stepName
        self.path = path
        self.infoMessage = infoMessage
        self.underlyingErrorMessage = underlyingError?.localizedDescription
    }
}

extension PublishingError: LocalizedError, CustomStringConvertible {
    public var description: String {
        var message = "Publish encountered an error:"

        stepName.map { message.append("\n[step] \($0)") }
        path.map { message.append("\n[path] \($0)") }

        message.append("\n[info] \(infoMessage)")

        underlyingErrorMessage.map { message.append("\n[error] \($0)") }

        return message
    }

    public var errorDescription: String? { description }
}

internal protocol PublishingErrorConvertible {
    func publishingError(forStepNamed stepName: String?) -> PublishingError
}

extension PublishingError: PublishingErrorConvertible {
    func publishingError(forStepNamed stepName: String?) -> PublishingError {
        var error = self
        error.stepName = stepName
        return error
    }
}
