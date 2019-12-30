/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

struct AnyError: LocalizedError {
    var errorDescription: String?

    init(_ string: String) {
        errorDescription = string
    }
}
