/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Type used to describe the author of a podcast.
public struct PodcastAuthor: Codable, Equatable {
    /// The author's full name.
    public var name: String
    /// The author's email address.
    public var emailAddress: String

    /// Initialize a new instance of this type
    /// - Parameter name: The author's full name.
    /// - Parameter emailAddress: The author's email address.
    public init(name: String, emailAddress: String) {
        self.name = name
        self.emailAddress = emailAddress
    }
}
