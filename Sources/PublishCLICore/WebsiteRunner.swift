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

        let serverQueue = DispatchQueue(label: "Publish.WebServer")
        let serverProcess = Process()

        print("""
        🌍 Starting web server at http://localhost:\(portNumber)

        Press ENTER to stop the server and exit
        """)

        serverQueue.async {

            // If the system's Python version is Python 3, use the new `http.server` command.
            // Otherwise, default to the `SimpleHTTPServer` command that Python 2 uses.
            var pythonHTTPServerCommand: String
            if self.systemPythonMajorVersionNumber == 3 {
                pythonHTTPServerCommand = "http.server"
            } else {
                pythonHTTPServerCommand = "SimpleHTTPServer"
            }

            do {
                _ = try shellOut(
                    to: "python -m \(pythonHTTPServerCommand) \(self.portNumber)",
                    at: outputFolder.path,
                    process: serverProcess
                )
            } catch let error as ShellOutError {
                self.outputServerErrorMessage(error.message)
            } catch {
                self.outputServerErrorMessage(error.localizedDescription)
            }

            serverProcess.terminate()
            exit(1)
        }

        _ = readLine()
        serverProcess.terminate()
    }
}

private extension WebsiteRunner {
    func resolveOutputFolder() throws -> Folder {
        do { return try folder.subfolder(named: "Output") }
        catch { throw CLIError.outputFolderNotFound }
    }

    /// The major version number of the current system's Python install (whatever Python responds to the `python` command)
    var systemPythonMajorVersionNumber: Int? {
        let pythonVersionString = try? shellOut(to: "python --version")
        let majorVersionNumberCharacter = pythonVersionString?.dropFirst(7).first
        return majorVersionNumberCharacter?.wholeNumberValue
    }

    func outputServerErrorMessage(_ message: String) {
        var message = message

        if message.hasPrefix("Traceback"),
           message.contains("Address already in use") {
            message = """
            A localhost server is already running on port number \(portNumber).
            - Perhaps another 'publish run' session is running?
            - Publish uses Python's simple HTTP server, so to find any
              running processes, you can use either Activity Monitor
              or the 'ps' command and search for 'python'. You can then
              terminate any previous process in order to start a new one.
            """
        }

        fputs("\n❌ Failed to start local web server:\n\(message)\n", stderr)
    }
}
