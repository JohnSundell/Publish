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
    /// - parameter branch: The branch to deploy to.
    /// - parameter targetFolderPath: Any specific subfolder path to deploy the output to.
    ///   If `nil`, then the output will replace all content in the branch.
    static func git(_ remote: String, branch: String = "master", targetFolderPath: Path? = nil) -> Self {
        DeploymentMethod(name: "Git (\(remote))") { context in
            let folder = try context.createDeploymentFolder(withPrefix: "Git", targetFolderPath: targetFolderPath) { folder in
                try folder.empty(includingHidden: true)

                try shellOut(to: .gitInit(), at: folder.path)

                try shellOut(to: "git remote add origin \(remote)", at: folder.path)

                try shellOut(to: "git fetch", at: folder.path)

                if targetFolderPath != nil {
                    try shellOut(
                        to: "git checkout \(branch) || git checkout -b \(branch)",
                        at: folder.path
                    )
                } else {
                    try shellOut(
                        to: "git symbolic-ref HEAD refs/remotes/origin/\(branch)",
                        at: folder.path
                    )
                }
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

                if targetFolderPath == nil {
                    try shellOut(to: "git checkout -b \(branch)", at: folder.path)
                }

                try shellOut(to: "git push origin \(branch)", at: folder.path)
            } catch let error as ShellOutError {
                throw PublishingError(infoMessage: error.message)
            } catch {
                throw error
            }
        }
    }

    /// Deploy a website to a given GitHub repository.
    /// - parameter repository: The full name of the repository (including its username).
    /// - parameter branch: The branch to deploy to.
    /// - parameter targetFolderPath: Any specific subfolder path to deploy the output to.
    ///   If `nil`, then the output will replace all content in the branch.
    /// - parameter useSSH: Whether an SSH connection should be used (preferred).
    static func gitHub(_ repository: String, branch: String = "master", targetFolderPath: Path? = nil, useSSH: Bool = true) -> Self {
        git(gitHubRemote(repository: repository, useSSH: useSSH),
            branch: branch, targetFolderPath: targetFolderPath)
    }

    /// Deploy a website using GitHub Pages.
    /// - parameter repository: The full name of the repository (including its username).
    /// - parameter source: The publishing source for your GitHub Pages site.
    ///   This should be set in your repository settings.
    /// - parameter useSSH: Whether an SSH connection should be used (preferred).
    static func gitHubPages(_ repository: String,
                            source: GitHubPagesDeploymentMode = .master,
                            useSSH: Bool = true)
        -> Self
    {
        let remote = gitHubRemote(repository: repository, useSSH: useSSH)
        
        return DeploymentMethod(name: "GitHub Pages (\(remote))") { context in
            let jekyllDisablingFile = try context.createOutputFile(at: Path(".nojekyll"))
            
            let branchName : String
            var targetFolderPath: Path? = nil
            
            switch source {
            case .ghPages :
                branchName = "gh-pages"
            case .masterDocs :
                targetFolderPath = Path("docs")
                fallthrough
            case .master :
                branchName = "master"
            }
            
            try gitHub(repository,
                       branch: branchName,
                       targetFolderPath: targetFolderPath,
                       useSSH: useSSH)
                .body(context)
            
            try jekyllDisablingFile.delete()
            
            let ghPagesModeName : String
            switch source {
            case .master : ghPagesModeName = "master branch"
            case .masterDocs : ghPagesModeName = "master branch /docs folder"
            case .ghPages : ghPagesModeName = "gh-pages branch"
            }
            
            let settingsURL = "\(gitHubRemote(repository: repository, useSSH: false, useStandardRepoURL: false))/settings"
            
            CommandLine.output("Remember to set your GitHub Pages source to \"\(ghPagesModeName)\" at \(settingsURL)",
                as: .info)
        }
    }
    
    private static func gitHubRemote(repository: String, useSSH: Bool, useStandardRepoURL: Bool = true) -> String {
        let prefix = useSSH ? "git@github.com:" : "https://github.com/"
        let suffix = useStandardRepoURL ? ".git" : ""
        return "\(prefix)\(repository)\(suffix)"
    }
    
    enum GitHubPagesDeploymentMode {
        case master, ghPages, masterDocs
    }
}
