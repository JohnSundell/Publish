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

        Press CTRL+C to stop the server and exit
        """)


      signal(SIGINT, SIG_IGN)
      let interruptSignalSource = DispatchSource.makeSignalSource(signal: SIGINT)
      interruptSignalSource.setEventHandler {
        // cancel the trap?
        interruptSignalSource.cancel()

        // terminate the server process
        serverProcess.terminate()

        // Install the default signal handler.
        var action = sigaction()
#if canImport(Darwin) || os(OpenBSD)
        action.__sigaction_u.__sa_handler = SIG_DFL
#elseif canImport(Musl)
        action.__sa_handler.sa_handler = SIG_DFL
#elseif os(Android)
        action.sa_handler = SIG_DFL
#else
        action.__sigaction_handler = unsafeBitCast(
          SIG_DFL,
          to: sigaction.__Unnamed_union___sigaction_handler.self
        )
#endif
        sigaction(SIGINT, &action, nil)
        kill(getpid(), SIGINT)
      }

      interruptSignalSource.resume()

        serverQueue.async {
            do {
                _ = try shellOut(
                    to: "python3 -m http.server \(self.portNumber)",
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
