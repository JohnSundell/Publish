/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

extension String {
    static func unique() -> String {
        UUID().uuidString
    }
}
