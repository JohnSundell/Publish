/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Files

internal extension Folder {
    struct Group {
        let root: Folder
        let output: Folder
        let `internal`: Folder
        let caches: Folder
    }
}
