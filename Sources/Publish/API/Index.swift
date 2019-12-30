/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// A representation of a website's main index page
public struct Index: Location {
    public var path: Path { "" }
    public var content = Content()
}
