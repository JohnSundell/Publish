/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Type used to represent a content tag. Items may be tagged, and then
/// retrieved based on any tag that they were associated with.
public struct Tag: StringWrapper {
    public var string: String

    public init(_ string: String) {
        self.string = string
    }
}

public extension Tag {
    /// Return a normalized string representation of this tag, which can
    /// be used to form URLs or identifiers.
    func normalizedString() -> String {
        string.normalized()
    }
}
