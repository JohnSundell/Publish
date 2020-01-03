/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish
import Files
import ShellOut

final class DeploymentTests: PublishTestCase {
    private var defaultCommandLineArguments: [String]!

    override func setUp() {
        super.setUp()
        defaultCommandLineArguments = CommandLine.arguments
    }

    override func tearDown() {
        CommandLine.arguments = defaultCommandLineArguments
        super.tearDown()
    }

    func testDeploymentSkippedByDefault() throws {
        var deployed = false

        try publishWebsite(using: [
            .step(named: "Custom") { _ in },
            .deploy(using: DeploymentMethod(name: "Deploy") { _ in
                deployed = true
            })
        ])

        XCTAssertFalse(deployed)
    }

    func testGenerationStepsAndPluginsSkippedWhenDeploying() throws {
        CommandLine.arguments.append("--deploy")

        var generationPerformed = false
        var pluginInstalled = false

        try publishWebsite(using: [
            .step(named: "Skipped") { _ in
                generationPerformed = true
            },
            .installPlugin(Plugin(name: "Skipped") { _ in
                pluginInstalled = true
            }),
            .deploy(using: DeploymentMethod(name: "Deploy") { _ in })
        ])

        XCTAssertFalse(generationPerformed)
        XCTAssertFalse(pluginInstalled)
    }

    func testGitDeploymentMethod() throws {
        let container = try Folder.createTemporary()
        let remote = try container.createSubfolder(named: "Remote.git")
        let repo = try container.createSubfolder(named: "Repo")

        try shellOut(to: [
            "git init",
            "git config --local receive.denyCurrentBranch updateInstead"
        ], at: remote.path)

        // First generate
        try publishWebsite(in: repo, using: [
            .generateHTML(withTheme: .foundation)
        ])

        // Then deploy
        CommandLine.arguments.append("--deploy")

        try publishWebsite(in: repo, using: [
            .deploy(using: .git(remote.path))
        ])

        let indexFile = try remote.file(named: "index.html")
        XCTAssertFalse(try indexFile.readAsString().isEmpty)
    }
}

extension DeploymentTests {
    static var allTests: Linux.TestList<DeploymentTests> {
        [
            ("testDeploymentSkippedByDefault", testDeploymentSkippedByDefault),
            ("testGenerationStepsAndPluginsSkippedWhenDeploying", testGenerationStepsAndPluginsSkippedWhenDeploying),
            ("testGitDeploymentMethod", testGitDeploymentMethod)
        ]
    }
}
