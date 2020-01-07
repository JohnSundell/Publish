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
    var portNumber: Int

    func run() throws {
        let generator = WebsiteGenerator(folder: folder)
        try generator.generate()

        let outputFolder = try resolveOutputFolder()

        print("""
        🌍 Starting web server at http://localhost:\(portNumber)

        Press any key to stop the server and exit
        """)

        DispatchQueue.global().async {
            do {
                _ = try shellOut(
                    to: "python -m SimpleHTTPServer \(self.portNumber)",
                    at: outputFolder.path
                )
            } catch let error {
                let message = (error as? ShellOutError)?.message ?? error.localizedDescription
                print("Encountered error: \(message)")
            }
        }

        _ = readLine()
        
        print("""
        🔌 Shutting down...
        """)
        _ = try shellOut(
            to: "kill -9 `ps -ef | grep SimpleHTTPServer | grep \(self.portNumber) | awk '{print $2}'`",
            at: outputFolder.path
        )
    }
}

private extension WebsiteRunner {
    func resolveOutputFolder() throws -> Folder {
        do { return try folder.subfolder(named: "Output") }
        catch { throw CLIError.outputFolderNotFound }
    }
}
