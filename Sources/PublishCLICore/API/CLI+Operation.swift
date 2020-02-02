//
//  CLI+Operation.swift
//
//
//  Created by Dorian Grolaux on 05/01/2020.
//

import Foundation

extension CLI {
    enum Operation {
        case new(withArguments: [NewProjectArgument])
        case generate
        case run
        case deploy
    }
    
    init(from arguments: [String])
}

extension CLI.Operation {
    enum NewProjectArgument {
        case name
    }
}
