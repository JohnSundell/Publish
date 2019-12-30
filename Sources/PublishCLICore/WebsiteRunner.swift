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
        let generator = WebsiteGenerator(folder: folder)
        try generator.generate()

        let outputFolder = try resolveOutputFolder()
        let portNumber = 8000

        print("""
        🌍 Starting web server at localhost:\(portNumber)

        Press any key to stop the server and exit
        """)

        DispatchQueue.global().async {
            _ = try? shellOut(
                to: "python -m SimpleHTTPServer \(portNumber)",
                at: outputFolder.path
            )
        }

        _ = readLine()
    }
}

private extension WebsiteRunner {
    func resolveOutputFolder() throws -> Folder {
        do { return try folder.subfolder(named: "Output") }
        catch { throw CLIError.outputfolderNotFound }
    }
}
