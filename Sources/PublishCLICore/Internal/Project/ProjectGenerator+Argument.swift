//
//  File.swift
//  
//
//  Created by Dorian Grolaux on 02/02/2020.
//

import Foundation

internal extension ProjectGenerator {
    /**
     Supported arguments
     */
    enum Argument: CLIArgument {
        case name(String)
        
        static func parse(_ arguments: [String]) -> Set<Self> {
            guard let name = arguments[safe: 1] else {
                return []
            }
            
            return [.name(name)]
        }
    }
}
