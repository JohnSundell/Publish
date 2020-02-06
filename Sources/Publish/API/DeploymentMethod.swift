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
    /// - parameter useSSH: Whether an SSH connection should be used (preferred).
    static func gitHub(_ repository: String, branch: String = "master", useSSH: Bool = true) -> Self {
        git(gitHubRemote(repository: repository, useSSH: useSSH),
            branch: branch)
    }
    
    static func gitHubPages(_ repository: String,
                            on branch: GitHubPagesDeploymentMode = .master,
                            useSSH: Bool = true)
        -> Self
    {
        let remote = gitHubRemote(repository: repository, useSSH: useSSH)
        
        return DeploymentMethod(name: "GitHub Pages (\(remote)") { context in
            let jekyllDisablingFile = try context.createOutputFile(at: Path(".nojekyll"))
            
            let branchName : String
            var docsModeFolders : (Folder, Folder)?
            
            switch branch {
            case .ghPages :
                branchName = "gh-master"
            case .masterDocs :
                let docs = try context.createOutputFolder(at: Path("docs"))
                
                guard let docsParent = docs.parent else {
                    try jekyllDisablingFile.delete()
                    try docs.delete()
                    return
                }
                
                try docsParent.moveContents(to: docs)
                
                docsModeFolders = (docs, docsParent)
                fallthrough
            case .master :
                branchName = "master"
            }
            
            try gitHub(repository,
                       branch: branchName,
                       useSSH: useSSH)
                .body(context)
            
            if let (docs, docsParent) = docsModeFolders {
                try docs.moveContents(to: docsParent)
                try docs.delete()
            }
            
            try jekyllDisablingFile.delete()
            
            let ghPagesModeName : String
            switch branch {
            case .master : ghPagesModeName = "master branch"
            case .masterDocs : ghPagesModeName = "master branch /docs folder"
            case .ghPages : ghPagesModeName = "gh-pages branch"
            }
            
            let settingsURL = "\(gitHubRemote(repository: repository, useSSH: false))/settings"
            
            CommandLine.output("Remember to set your GitHub Pages source to \"\(ghPagesModeName)\" at \(settingsURL)",
                as: .info)
        }
    }
    
    private static func gitHubRemote(repository:String, useSSH: Bool) -> String {
        let prefix = useSSH ? "git@github.com:" : "https://github.com/"
        return "\(prefix)\(repository).git"
    }
    
    enum GitHubPagesDeploymentMode {
        case master, ghPages, masterDocs
    }
}
