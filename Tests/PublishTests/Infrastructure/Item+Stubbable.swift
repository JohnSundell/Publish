/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Publish

extension Item: Stubbable where Site == WebsiteStub.WithoutItemMetadata {
    private static let defaultDate = Date()

    static func stub(withPath path: Path) -> Self {
        Item(
            path: path,
            sectionID: .one,
            metadata: Site.ItemMetadata(),
            tags: [],
            content: Content(
                date: defaultDate,
                lastModified: defaultDate
            )
        )
    }

    static func stub(withSectionID sectionID: WebsiteStub.SectionID) -> Self {
        stub(withPath: Path(.unique()), sectionID: sectionID)
    }

    static func stub(withPath path: Path, sectionID: WebsiteStub.SectionID) -> Self {
        Item(
            path: path,
            sectionID: sectionID,
            metadata: Site.ItemMetadata(),
            tags: [],
            content: Content(
                date: defaultDate,
                lastModified: defaultDate
            )
        )
    }
}
