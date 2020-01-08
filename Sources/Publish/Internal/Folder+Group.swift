/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Files

internal extension Folder {
    struct Group {
        /// Folder containing original contents to process (including `Contant/` and `Resources/` subfolders).
        let source: Folder
        /// `.intermediate` subfolder within `source`.
        let intermediate: Folder
        /// `Output` subfolder within `.intermediate`.
        let intermediateOutput: Folder
        /// `.internal` subfolder within `source`.
        let `internal`: Folder
        /// `Caches` subfolder within `source`.
        let caches: Folder
    }
}
