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
            let target = extractTarget(from: arguments)
            let generator = WebsiteGenerator(folder: folder, target: target)
            try generator.generate()
        case "deploy":
            let deployer = WebsiteDeployer(folder: folder)
            try deployer.deploy()
        case "run":
            let target = extractTarget(from: arguments)
            let portNumber = extractPortNumber(from: arguments, didSpecifyTarget: target != nil)
            let runner = WebsiteRunner(folder: folder, portNumber: portNumber, target: target)
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
               for the website in the current folder. If you have multiple targets,
               you can specify the target name as the argument after "run".
               Use the "-p" or "--port" option for customizing the default port.
               Example: publish run <target> -p 5555
        - deploy: Generate and deploy the website in the current
               folder, according to its deployment method.
        """)
    }

    private func extractTarget(from arguments: [String]) -> String? {
        if arguments.count > 2, (arguments[2] != "-p" || arguments[2] != "--port") {
            return arguments[2]
        }
        return nil // don't specify a target
    }

    private func extractPortNumber(from arguments: [String], didSpecifyTarget: Bool) -> Int {
        if arguments.count > (didSpecifyTarget ? 4 : 3) {
            switch arguments[didSpecifyTarget ? 3 : 2] {
            case "-p", "--port":
                guard let portNumber = Int(arguments[didSpecifyTarget ? 4 : 3]) else {
                    break
                }
                return portNumber
            default:
                return 8000 // default portNumber
            }
        }
        return 8000 // default portNumber
    }

    private func resolveProjectKind(from arguments: [String]) -> ProjectKind {
        guard arguments.count > 2 else {
            return .website
        }

        return ProjectKind(rawValue: arguments[2]) ?? .website
    }
}
