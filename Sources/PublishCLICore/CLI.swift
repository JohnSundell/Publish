/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Files
import ShellOut

public struct CLI {
    private let arguments: [String]
    private let publishRepositoryURL: URL
    private let publishVersion: String

    public init(arguments: [String] = CommandLine.arguments,
                publishRepositoryURL: URL,
                publishVersion: String) {
        self.arguments = arguments
        self.publishRepositoryURL = publishRepositoryURL
        self.publishVersion = publishVersion
    }

    public func run(in folder: Folder = .current) throws {
        guard arguments.count > 1 else {
            return outputHelpText()
        }

        switch arguments[1] {
        case "new":
            let generator = ProjectGenerator(
                folder: folder,
                publishRepositoryURL: publishRepositoryURL,
                publishVersion: publishVersion
            )

            try generator.generate()
        case "generate":
            let generator = WebsiteGenerator(folder: folder)
            try generator.generate()
        case "deploy":
            let deployer = WebsiteDeployer(folder: folder)
            try deployer.deploy()
        case "run":
            if arguments.count > 2, arguments[2].contains("-p=") || arguments[2].contains("--port="), let portNumber = extractPortNumber(from: arguments[2]) {
                let runner = WebsiteRunner(folder: folder, portNumber: portNumber)
                try runner.run()
            } else {
                let runner = WebsiteRunner(folder: folder)
                try runner.run()
            }
        default:
            outputHelpText()
        }
    }
}

private extension CLI {
    func outputHelpText() {
        print("""
        Publish Command Line Interface
        ------------------------------
        Interact with the Publish static site generator from
        the command line, to create new websites, or to generate
        and deploy existing ones.

        Available commands:

        - new: Set up a new website in the current folder.
        - generate: Generate the website in the current folder.
        - run: Generate and run a localhost server on default port 8000
               for the website in the current folder. Use the
               "-p=" or "--port=" option for customizing the default port.
        - deploy: Generate and deploy the website in the current
               folder, according to its deployment method.
        """)
    }
    
    private func extractPortNumber(from argument: String) -> Int? {
        let equalSignIndex = argument.firstIndex(of: "=")!
        let portNumberString = String(argument.suffix(from: argument.index(after: equalSignIndex)))
        return Int(portNumberString)
    }
}
