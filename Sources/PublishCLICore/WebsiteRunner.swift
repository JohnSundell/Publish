/**
 *  Publish
 *  Copyright (c) John Sundell 2019
 *  MIT license, see LICENSE file for details
 */

import Files
import Foundation
import ShellOut
import StaticServer

internal struct WebsiteRunner {
    let folder: Folder
    var portNumber: Int

    func run() throws {
        let generator = WebsiteGenerator(folder: folder)
        try generator.generate()

        let outputFolder = try resolveOutputFolder()

        do {
            let server = try StaticServer(host: "localhost", port: portNumber, root: outputFolder.path, silent: true)

            print("""
            🌍 Starting web server at http://localhost:\(portNumber)

            Press Ctrl+C to stop the server and exit
            """)

            try server.start()
        } catch {
            outputServerError(error)
        }
    }
}

private extension WebsiteRunner {
    func resolveOutputFolder() throws -> Folder {
        do { return try folder.subfolder(named: "Output") }
        catch { throw CLIError.outputFolderNotFound }
    }

    func outputServerError(_ error: ServerError) {
        var message = error.localizedDescription

        if error == .AddressAlreadyInUse {
            message = """
            A localhost server is already running on port number \(portNumber).
            - Perhaps another 'publish run' session is running?
            - Publish uses simple SwiftNIO server to serve files.
              You can use following command to find the process using the port
              we wanted to use:

              lsof -i tcp:\(portNumber)

              You can also use either Activity Monitor or the 'ps' command
              to search for 'publish'. You can then terminate any previous
              process in order to start a new one.
            """
        } else if error == .ServerRootDoesNotExist {
            message = """
            Can't create StaticServer instance, because Output folder
            can't be found.
            """
        }

        fputs("\n❌ Failed to start local web server:\n\(message)\n", stderr)
    }

    func outputServerError(_ error: Error) {
        fputs("\n❌ Failed to start local web server:\n\(error.localizedDescription)\n", stderr)
    }
}
