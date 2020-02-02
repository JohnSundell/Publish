//
//  CLI+Operation.swift
//
//
//  Created by Dorian Grolaux on 05/01/2020.
//

import Foundation

internal enum CLIOperation {
    case new(args: Set<ProjectGenerator.Argument>)
    case generate
    case run(port: Int, args: Set<WebsiteRunner.Argument>)
    case deploy
    
    init?(from arguments: [String]) {
        guard let first = arguments[safe: 0] else {
            return nil
        }
        
        switch first {
        case "new":
            self = .new(args: .parse(arguments))
            
        case "generate":
            self = .generate
            
        case "deploy":
            self = .deploy
            
        case "run":
            let args: Set<WebsiteRunner.Argument> = .parse(arguments)
            guard let port: Int = args.compactMap({
                if case let WebsiteRunner.Argument.port(port) = $0 { return port }
                return nil
            }).first else {
                return nil
            }
            
            self = .run(port: port, args: args)
            
        default:
            return nil
        }
    }
}
