/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Files

extension Folder {
    static func createTemporary() throws -> Self {
        let parent = try createTestsFolder()
        return try parent.createSubfolder(named: .unique())
    }
}

private extension Folder {
    static func createTestsFolder() throws -> Self {
        try Folder.temporary.createSubfolderIfNeeded(at: "PublishTests")
    }
}
