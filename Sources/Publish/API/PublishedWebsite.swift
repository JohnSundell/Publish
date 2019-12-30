/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Type representing a fully published website. An instance of this type
/// is returned from every call to `Website.publish()`, and can be used
/// to implement additional tooling on top of Publish.
public struct PublishedWebsite<Base: Website> {
    /// The main website index that was published.
    public let index: Index
    /// The sections that were published.
    public let sections: SectionMap<Base>
    /// The free-form pages that were published.
    public let pages: [Path : Page]
}
