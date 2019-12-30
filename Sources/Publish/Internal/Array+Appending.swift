/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

internal extension Array {
    func appending(_ element: Element) -> Self {
        var array = self
        array.append(element)
        return array
    }
}
