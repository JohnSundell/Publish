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
            let runner = WebsiteRunner(folder: folder)
            try runner.run()
		case "update":
			let tmpDir = "$TMPDIR/Publish"
			print("updating")
			try shellOut(to: "echo `\(tmpDir)`")
//			try shellOut(to: .removeFile(from: tmpDir,arguments: ["-rf"]))
			if let _ = try? shellOut(to: .gitClone(url: URL(string: "https://github.com/JohnSundell/Publish.git")!, to:  tmpDir)) {

			}
			else {
				let tmpGit = "git --git-dir=\(tmpDir)/.git  --work-tree=\(tmpDir)"
				let thisVersion = try shellOut(to: " git --git-dir $TMPDIR/Publish/.git describe --abbrev=0 --tags")
				let remoteLatestVersion = try shellOut(to: #"\#(tmpGit) ls-remote --tags --refs --sort="v:refname" origin  | tail -n1 | sed 's/.*\///'"#)
				guard thisVersion < remoteLatestVersion else {
					return print("current publish is up to date")
				}
				try shellOut(to: "\(tmpGit) pull")
				print("install to \(remoteLatestVersion)")
			}
			try	shellOut(to: [
				"make -f \(tmpDir)/Makefile"
			])
			print("✅ update complete")
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
        - run: Generate and run a localhost server on port 8000
               for the website in the current folder.
        - deploy: Generate and deploy the website in the current
               folder, according to its deployment method.
        - update: update to newest version and install
        	   from https://github.com/JohnSundell/Publish
        """)
    }
}
