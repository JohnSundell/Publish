/**
 *  Publish
 *  Copyright (c) John Sundell 2019
 *  MIT license, see LICENSE file for details
 */

import Foundation
import Files
import ShellOut
import FileWatcher

internal struct WebsiteRunner {
    static let normalTerminationStatus = 15
    static let debounceDuration = 3 * NSEC_PER_SEC
    static let runLoopInterval: TimeInterval = 0.1
    static let exitMessage = "Press CTRL+C to stop the server and exit"
    let folder: Folder
    let portNumber: Int
    let shouldWatch: Bool

    var foldersToWatch: [Folder] {
        get throws {
            try ["Sources", "Resources", "Content"].map(folder.subfolder(named:))
        }
    }

    func run() throws {
        let serverProcess: Process = try generateAndRun()

        var watchTask: Task<Void, Error>?

        if shouldWatch {
            watchTask = Task.detached {
                for try await _ in changes(on: try foldersToWatch, debouncedBy: Self.debounceDuration) {
                    print("Changes detected, regenerating...")
                    let generator = WebsiteGenerator(folder: folder)
                    do {
                        try generator.generate()
                        print(Self.exitMessage)
                    } catch {
                        outputErrorMessage("Regeneration failed")
                    }
                }
            }
        }

        let interruptHandler = registerInterruptHandler {
            watchTask?.cancel()
            serverProcess.terminate()
            exit(0)
        }

        interruptHandler.resume()

        while true {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: Self.runLoopInterval))
        }
    }
}

private extension WebsiteRunner {
    func changes(on folders: [Folder], debouncedBy nanoseconds: UInt64?) -> AsyncThrowingStream<String, Error> {
        .init { continuation in
            let watcher = FileWatcher(folders.map(\.path))

            var deferredTask: Task<Void, Error>?

            watcher.callback = { event in
                guard event.isFileChanged || event.isDirectoryChanged else {
                    return
                }

                guard let nanoseconds = nanoseconds else {
                    continuation.yield(event.path)
                    return
                }

                deferredTask?.cancel()

                deferredTask = Task {
                    do {
                        try await Task.sleep(nanoseconds: nanoseconds)
                        continuation.yield(event.path)
                    } catch where !(error is CancellationError) {
                        continuation.finish()
                    }
                }
            }

            watcher.start()

            continuation.onTermination = { _ in
                watcher.stop()
            }
        }
    }


    func registerInterruptHandler(_ handler: @escaping () -> Void) -> DispatchSourceSignal {
        let interruptHandler = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)

        signal(SIGINT, SIG_IGN)

        interruptHandler.setEventHandler(handler: handler)
        return interruptHandler
    }

    func generate() throws {
        let generator = WebsiteGenerator(folder: folder)
        try generator.generate()
    }

    func generateAndRun() throws -> Process {
        try generate()

        let outputFolder = try resolveOutputFolder()

        let serverQueue = DispatchQueue(label: "Publish.WebServer")
        let serverProcess = Process()

        print("""
        🌍 Starting web server at http://localhost:\(portNumber)

        \(Self.exitMessage)
        """)

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

        return serverProcess
    }

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

        outputErrorMessage("Failed to start local web server:\n\(message)")
    }

    func outputErrorMessage(_ message: String) {
        fputs("\n❌ \(message)\n", stderr)
    }
}

private extension FileWatcherEvent {
    var isFileChanged: Bool {
        fileRenamed || fileRemoved || fileCreated || fileModified
    }

    var isDirectoryChanged: Bool {
        dirRenamed || dirRemoved || dirCreated || dirModified
    }
}
