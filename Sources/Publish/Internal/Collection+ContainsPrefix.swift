//
//  Collection+ContainsPrefix.swift
//  
//
//  Created by Ben Syverson on 2020/01/28.
//

import Foundation

internal extension Collection where Element: StringWrapper {
    func containsPrefixFor(_ string: String) -> Bool {
        reduce(false){ $0 || string.hasPrefix($1.string) }
    }
}
