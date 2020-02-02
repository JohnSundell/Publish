/**
 *  Publish
 *  Copyright (c) John Sundell 2019
 *  MIT license, see LICENSE file for details
 */

import Files
import Foundation
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
        guard let operation = CLIOperation(from: arguments) else {
            return outputHelpText()
        }

        switch operation {
        case .new(let arguments):
            let generator = ProjectGenerator(
                folder: folder,
                publishRepositoryURL: publishRepositoryURL,
                publishVersion: publishVersion
            )

            try generator.generate()
        case .generate:
            let generator = WebsiteGenerator(folder: folder)
            try generator.generate()
        case .deploy:
            let deployer = WebsiteDeployer(folder: folder)
            try deployer.deploy()
        case .run(let port, let arguments):
            let runner = WebsiteRunner(folder: folder, portNumber: port)
            try runner.run()
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
               for the website in the current folder. Use the "-p"
               or "--port" option for customizing the default port.
        - deploy: Generate and deploy the website in the current
               folder, according to its deployment method.
        """)
    }

    
}
