/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Enum describing various ways that HTML files may be generated.
public enum HTMLFileMode {
    /// Stand-alone HTML files should be generated, so that `section/item`
    /// becomes `section/item.html`.
    case standAloneFiles
    /// HTML index files wrapped in folders should be generated, so that
    /// `section/item` becomes `section/item/index.html`.
    case foldersAndIndexFiles
}
