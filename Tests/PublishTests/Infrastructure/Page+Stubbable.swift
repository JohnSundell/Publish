/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Publish

extension Page: Stubbable where Site == WebsiteStub.WithoutMetadata {
    private static let defaultDate = Date()

    static func stub(withPath path: Path) -> Self {
        Page(
            path: path,
            metadata: Site.PageMetadata(),
            content: Content(
                date: defaultDate,
                lastModified: defaultDate
            )
        )
    }
}
