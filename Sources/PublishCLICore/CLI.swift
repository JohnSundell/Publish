/**
 *  Publish
 *  Copyright (c) John Sundell 2019
 *  MIT license, see LICENSE file for details
 */

import Files
import Foundation
import ShellOut

public struct CLI {
    private static let defaultPortNumber = 8000
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
                publishVersion: publishVersion,
                kind: resolveProjectKind(from: arguments)
            )

            try generator.generate()
        case "generate":
            let generator = WebsiteGenerator(folder: folder)
            try generator.generate()
        case "deploy":
            let deployer = WebsiteDeployer(folder: folder)
            try deployer.deploy()
        case "run":
            let portNumber = extractPortNumber(from: arguments)
            let shouldWatch = extractShouldWatch(from: arguments)
            let runner = WebsiteRunner(folder: folder, portNumber: portNumber, shouldWatch: shouldWatch)
            try runner.run()
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
               for the website in the current folder. Use the "-p"
               or "--port" option for customizing the default port.
               Use the "-w" or "--watch" option to watch for file changes.
        - deploy: Generate and deploy the website in the current
               folder, according to its deployment method.
        """)
    }

    private func extractPortNumber(from arguments: [String]) -> Int {
        guard let index = arguments.firstIndex(of: "-p") ?? arguments.firstIndex(of: "--port") else {
            return Self.defaultPortNumber
        }

        guard arguments.count > index + 1 else {
            return Self.defaultPortNumber
        }

        guard let portNumber = Int(arguments[index + 1]) else {
            return Self.defaultPortNumber
        }

        return portNumber
    }

    private func extractShouldWatch(from arguments: [String]) -> Bool {
        arguments.contains("-w") || arguments.contains("--watch")
    }

    private func resolveProjectKind(from arguments: [String]) -> ProjectKind {
        guard arguments.count > 2 else {
            return .website
        }

        return ProjectKind(rawValue: arguments[2]) ?? .website
    }
}
