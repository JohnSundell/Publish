/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Files
import ShellOut

internal struct WebsiteRunner {
    let folder: Folder

    func run() throws {
        let portNumber = 8000
        
        try self.generate()

        print("""
        🌍 Starting web server at http://localhost:\(portNumber)
        """)

        var quit = false
        
        while !quit {
            try startServer(portNumber: portNumber)

            print("""

            Press ⮐  to regenerate the site.
            Type q⮐  or control-c to quit
            """)
            let input = readLine(strippingNewline: true)!
            switch input.uppercased() {
            case "Q":
                quit = true
            default:
                try self.generate()
            }
        }
    }

}

private extension WebsiteRunner {
    func generate() throws {
        let generator = WebsiteGenerator(folder: folder)
        try generator.generate()
    }
    
    func startServer(portNumber: Int = 8000) throws {
        let outputFolder = try resolveOutputFolder()

        DispatchQueue.global().async {
            _ = try? shellOut(
                to: "python -m SimpleHTTPServer \(portNumber)",
                at: outputFolder.path
            )
        }
    }

    func resolveOutputFolder() throws -> Folder {
        do { return try folder.subfolder(named: "Output") }
        catch { throw CLIError.outputfolderNotFound }
    }
}
