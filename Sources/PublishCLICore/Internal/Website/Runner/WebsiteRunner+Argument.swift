//
//  File.swift
//  
//
//  Created by Dorian Grolaux on 02/02/2020.
//

import Foundation

internal extension WebsiteRunner {
    enum Argument: CLIArgument {
        case port(Int)
        
        private static var defaultPort: Int { 8000 }
        
        static func parse(_ arguments: [String]) -> Set<Self> {
            guard arguments.count > 3  else {
                return []
            }
            
            var set: Set<Self> = [.port(defaultPort)]
            
            switch arguments[2] {
            case "-p", "--port":
                guard let portString = arguments[safe: 3], let port = Int(portString) else {
                    break
                }
                
                set.update(with: .port(port))
                
            default:
                break
            }
            
            return set
        }
    }
}
