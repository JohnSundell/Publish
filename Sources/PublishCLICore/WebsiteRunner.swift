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
    
    func handleUpdate() {
        print("\n\nChange Detected\n\n")
        let generator = WebsiteGenerator(folder: folder)
        try? generator.generate()
    }
    
    
    func run() throws {
        let generator = WebsiteGenerator(folder: folder)
        try generator.generate()

        let outputFolder = try resolveOutputFolder()

        let serverQueue = DispatchQueue(label: "Publish.WebServer")
        let serverProcess = Process()

        print("""
        🌍 Starting web server at http://localhost:\(portNumber)

        Press ENTER or CONTROL+C to stop the server and exit
        """)
        #if !os(Linux)
        // Start observing for changes to the `Resources` or `Content` folders.
        let observer = FolderObserver(rootFolders: [try? folder.subfolder(named: "Resources"), try? folder.subfolder(named: "Content")].compactMap()) {
            self.handleUpdate()
        }
        
        observer.start()
        #endif


        // Handle Ctrl+C shutdown
        let signalsQueue = DispatchQueue(label: "Publish.signals")

        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: signalsQueue)
        sigintSrc.setEventHandler {
            print("Shutting down.")
            serverProcess.terminate()
            #if !os(Linux)
            observer.stop()
            #endif
            exit(0)
        }
        
        sigintSrc.resume()
                
        signal(SIGINT, SIG_IGN) // Make sure the signal does not terminate the application.
        
        serverQueue.async {
            do {
                _ = try shellOut(
                    to: "python -m \(self.resolvePythonHTTPServerCommand()) \(self.portNumber)",
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
        sigintSrc.cancel()
        serverProcess.terminate()
        #if !os(Linux)
        observer.stop()
        #endif
    }
}

private extension WebsiteRunner {
    func resolveOutputFolder() throws -> Folder {
        do { return try folder.subfolder(named: "Output") }
        catch { throw CLIError.outputFolderNotFound }
    }

    func resolvePythonHTTPServerCommand() -> String {
        if resolveSystemPythonMajorVersionNumber() >= 3 {
            return "http.server"
        } else {
            return "SimpleHTTPServer"
        }
    }

    func resolveSystemPythonMajorVersionNumber() -> Int {
        // Expected output: `Python X.X.X`
        let pythonVersionString = try? shellOut(to: "python --version")
        let fullVersionNumber = pythonVersionString?.split(separator: " ").last
        let majorVersionNumber = fullVersionNumber?.first
        return majorVersionNumber?.wholeNumberValue ?? 2
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

#if !os(Linux)

class FolderObserver {
    internal init(rootFolders: [Folder], block: @escaping () -> Void) {
        self.rootFolders = rootFolders
        self.block = block
    }
    
    let rootFolders: [Folder]
    
    var block: () -> Void
    
    
    private var eventSources: [(DispatchSourceFileSystemObject, Int32)] = []
    private let autoUpdateQueue = DispatchQueue(label: "Publish.updater")

    func start() {
        for folder in rootFolders {
            self.subscribe(folder)
        }
    }
    
    private func subscribe(_ folder: Folder) {
        // Linux does not support O_EVTONLY and does not have makeFileSystemObjectSource yet

        let fileDescriptor = open(folder.url.path, O_EVTONLY)

        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .all, queue: autoUpdateQueue)
        
        source.setEventHandler {
            self.handleUpdate()
        }
        
        source.resume()
        
        self.eventSources.append((source, fileDescriptor))
        
        for subfolder in folder.subfolders {
            self.subscribe(subfolder)
        }
    }
    
    private func unsubscribe() {
        for (source, file) in self.eventSources {
            source.cancel()
            close(file)
        }
        self.eventSources = []
    }
    
    private func handleUpdate() {
        // stop all subscribtions
        self.unsubscribe()
        
        self.block()
                
        self.start()
    }
    
    func stop() {
        self.unsubscribe()
    }
}
#endif


extension Array {
    func compactMap<T>() -> [T] where Element == Optional<T> {
        return self.compactMap { element in
            return element
        }
    }
}
