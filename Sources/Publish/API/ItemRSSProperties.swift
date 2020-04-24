/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Properties that can be used to customize an item's RSS representation.
public struct ItemRSSProperties: Codable, Hashable {
    /// Any specific GUID that should be added for the item. When `nil`,
    /// the item's URL will be used and the `isPermaLink` attribute will
    /// be set to `true`. If not `nil`, a non-permalink will be assumed.
    public var guid: String?
    /// Any prefix that should be added to the item's title within an RSS feed.
    public var titlePrefix: String?
    /// Any suffix that should be added to the item's title within an RSS feed.
    public var titleSuffix: String?
    /// Any prefix that should be added to the item's body HTML within an RSS feed.
    public var bodyPrefix: String?
    /// Any suffix that should be added to the item's body HTML within an RSS feed.
    public var bodySuffix: String?

    /// Initialize an instance of this type
    /// - parameter guid: Any specific GUID that should be added for the item.
    /// - parameter titlePrefix: Any prefix that should be added to the item's title.
    /// - parameter titleSuffix: Any suffix that should be added to the item's title.
    /// - parameter bodyPrefix: Any prefix that should be added to the item's body HTML.
    /// - parameter bodySuffix: Any suffix that should be added to the item's body HTML.
    public init(guid: String? = nil,
                titlePrefix: String? = nil,
                titleSuffix: String? = nil,
                bodyPrefix: String? = nil,
                bodySuffix: String? = nil) {
        self.guid = guid
        self.titlePrefix = titlePrefix
        self.titleSuffix = titleSuffix
        self.bodyPrefix = bodyPrefix
        self.bodySuffix = bodySuffix
    }
}
