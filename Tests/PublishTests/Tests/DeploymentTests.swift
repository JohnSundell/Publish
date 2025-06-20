/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Foundation
import Publish
import Files
import ShellOut
import Synchronization

@Suite("Deployment", .serialized) struct DeploymentTests: PublishTestCase {
    @Test func testDeploymentSkippedByDefault() throws {
        let deployed = Mutex(false)

        try publishWebsite(using: [
            .step(named: "Custom") { _ in },
            .deploy(using: DeploymentMethod(name: "Deploy") { _ in
                deployed.withLock { $0 = true }
            })
        ])

        let isDeployed = deployed.withLock(\.self)
        #expect(!isDeployed)
    }

    @Test func testGenerationStepsAndPluginsSkippedWhenDeploying() throws {

        let generationPerformed = Mutex(false)
        let pluginInstalled = Mutex(false)

        try publishWebsite(
            using: [
                .step(named: "Skipped") { _ in
                    generationPerformed.withLock { $0 = true }
                },
                .installPlugin(Plugin(name: "Skipped") { _ in
                    pluginInstalled.withLock { $0 = true }
                }),
                .deploy(using: DeploymentMethod(name: "Deploy") { _ in })
            ],
            deploy: true
        )

        let isGenerationPerformed = generationPerformed.withLock(\.self)
        #expect(isGenerationPerformed == false)

        let isPluginInstalled = pluginInstalled.withLock(\.self)
        #expect(isPluginInstalled == false)
    }

    @Test func testGitDeploymentMethod() throws {
        let container = try Folder.createTemporary()
        let remote = try container.createSubfolder(named: "Remote.git")
        let repo = try container.createSubfolder(named: "Repo")

        try shellOut(to: [
            "git init",
            // Not all git installations init with a master branch.
            "git checkout master || git checkout -b master",
            "git config --local receive.denyCurrentBranch updateInstead"
        ], at: remote.path)

        // First generate
        try publishWebsite(in: repo, using: [
            .generateHTML(withTheme: .foundation)
        ])

        // Then deploy
        try publishWebsite(
            in: repo,
            using: [
                .deploy(using: .git(remote.path))
            ],
            deploy: true
        )

        let indexFile = try remote.file(named: "index.html")
        #expect(try !indexFile.readAsString().isEmpty)
    }

	@Test func testGitDeploymentMethodWithError() throws {
        let container = try Folder.createTemporary()
        let remote = try container.createSubfolder(named: "Remote.git")
        let repo = try container.createSubfolder(named: "Repo")

        try shellOut(
          to: [
            "git init",
            // Not all git installations init with a master branch.
            "git checkout master || git checkout -b master"
          ],
          at: remote.path
        )
        
        // First generate
        try publishWebsite(in: repo, using: [
            .generateHTML(withTheme: .foundation)
        ])

        // Then deploy
        var thrownError: PublishingError?

        do {
            try publishWebsite(
                in: repo,
                using: [.deploy(using: .git(remote.path))],
                deploy: true
            )
        } catch {
            thrownError = error as? PublishingError
        }

        // We don't want to make too many assumptions about the way
        // Git phrases its error messages here, so we just perform
        // a few basic checks to make sure we have some form of output:
        let infoMessage = try require(thrownError?.infoMessage)
        #expect(infoMessage.contains("receive.denyCurrentBranch"))
        #expect(infoMessage.contains("[remote rejected]"))
    }

    @Test func testDeployingUsingCustomOutputFolder() throws {
        let container = try Folder.createTemporary()

        // First generate
        try publishWebsite(in: container, using: [
            .addMarkdownFiles(),
            .generateHTML(withTheme: .foundation)
        ], content: [
            "one/a.md": "Text"
        ])

        // Then deploy
        let outputFolder = Mutex<Folder?>(nil)

        try publishWebsite(
            in: container,
            using: [
                .deploy(using: DeploymentMethod(name: "Test") { context in
                    try outputFolder.withLock {
                        $0 = try context.createDeploymentFolder(
                            withPrefix: "Test",
                            outputFolderPath: "CustomOutput",
                            configure: { _ in }
                        )
                    }
                })
            ],
            deploy: true
        )

        let folder = try require(outputFolder.withLock(\.self))
        let subfolder = try folder.subfolder(named: "CustomOutput")
        #expect(subfolder.containsSubfolder(at: "one/a"))
    }
}
