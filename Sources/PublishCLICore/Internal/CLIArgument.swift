//
//  File.swift
//  
//
//  Created by Dorian Grolaux on 02/02/2020.
//

import Foundation

internal protocol CLIArgument: Hashable {
    static func parse(_ arguments: [String]) -> Set<Self>
}

internal extension Set where Element: CLIArgument {
    static func parse(_ arguments: [String]) -> Self {
        return Element.parse(arguments)
    }
}
