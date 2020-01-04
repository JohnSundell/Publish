/**
*  Publish
*  Copyright (c) John Sundell 2020
*  MIT license, see LICENSE file for details
*/

internal extension String {
    func normalized() -> String {
        String(lowercased().compactMap { character in
            if character.isWhitespace {
                return "-"
            }

            if character.isLetter || character.isNumber {
                return character
            }

            return nil
        })
    }
}
