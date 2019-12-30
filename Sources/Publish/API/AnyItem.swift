/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Type-erased version of a website's item, which can be useful
/// when implementing general-purpose themes or utilities. It
/// doesn't contain site-specific information, such as the item's
/// metadata or section ID.
public protocol AnyItem: Location {
    /// The item's tags. Items tagged with the same tag can be
    /// queried using either `Section` or `PublishingContext`.
    var tags: [Tag] { get }
    /// Properties that can be used to customize how an item is
    /// presented within an RSS feed. See `ItemRSSProperties`.
    var rssProperties: ItemRSSProperties { get }
}
