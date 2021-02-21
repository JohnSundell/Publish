/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Files
import ShellOut

/// Type used to implement deployment functionality for a website.
/// When implementing reusable deployment methods that are vended as
/// frameworks or APIs, it's recommended to create them using static
/// factory methods, just like how the built-in `git` and `gitHub`
/// deployment methods are implemented.
public struct DeploymentMethod<Site: Website> {
    /// Closure type used to implement the deployment method's main
    /// body. It's passed the `PublishingContext` of the current
    /// session, and can use that to create a dedicated deployment folder.
    public typealias Body = (PublishingContext<Site>) throws -> Void

    /// The human-readable name of the deployment method.
    public var name: String
    /// The deployment method's main body. See `Body` for more info.
    public var body: Body

    /// Initialize a new deployment method.
    /// - parameter name: The method's human-readable name.
    /// - parameter body: The method's main body.
    public init(name: String, body: @escaping Body) {
        self.name = name
        self.body = body
    }
}

public extension DeploymentMethod {
    /// Deploy a website to a given remote using Git.
    /// - parameter remote: The full address of the remote to deploy to.
    /// - parameter branch: The branch to push to and pull from (default is master).
    static func git(_ remote: String, branch: String = "master") -> Self {
        DeploymentMethod(name: "Git (\(remote))") { context in
            let folder = try context.createDeploymentFolder(withPrefix: "Git") { folder in
                if !folder.containsSubfolder(named: ".git") {
                    try shellOut(to: .gitInit(), at: folder.path)

                    try shellOut(
                        to: "git remote add origin \(remote)",
                        at: folder.path
                    )
                }

                try shellOut(
                    to: "git remote set-url origin \(remote)",
                    at: folder.path
                )

                _ = try? shellOut(
                    to: .gitPull(remote: "origin", branch: branch),
                    at: folder.path
                )

                try folder.empty()
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString = dateFormatter.string(from: Date())

            do {
                try shellOut(
                    to: """
                    git add . && git commit -a -m \"Publish deploy \(dateString)\" --allow-empty
                    """,
                    at: folder.path
                )

                try shellOut(
                    to: .gitPush(remote: "origin", branch: branch),
                    at: folder.path
                )
            } catch let error as ShellOutError {
                throw PublishingError(infoMessage: error.message)
            } catch {
                throw error
            }
        }
    }

    /// Deploy a website to a given GitHub repository.
    /// - parameter repository: The full name of the repository (including its username).
    /// - parameter branch: The branch to push to and pull from (default is master).
    /// - parameter useSSH: Whether an SSH connection should be used (preferred).
    static func gitHub(_ repository: String, branch: String = "master", useSSH: Bool = true) -> Self {
        let prefix = useSSH ? "git@github.com:" : "https://github.com/"
        return git("\(prefix)\(repository).git", branch: branch)
    }
}
