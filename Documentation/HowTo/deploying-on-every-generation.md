# How to deploy the site on every generation

Let's say you live on the wild side, and you don't develop locally for some reason. Maybe you work with a team. Maybe all of your assets are stored on your server, and you have a love for relative links. Maybe you develop on the server.

Currently, the only official way to deploy is:

1. Generating your site with `publish generate` or by running the Package with no command line flags
2. Deploying by running `publish deploy` or by running the Package with the command line flag `-d` or `--deploy`

This is so that when you like what you've generated, you deploy it. You don't want to run the risk of regenerating the site, only to realize you changed something and broke it all.

**But what if you're the kind of person mentioned above?**

Well, don't fret. There is a way to deploy on every generation, as part of the generation process.

*Be warned, this dangerously ignores the risk of a regeneration breaking something then immediately deploying that broken site. It is recommended that you don't do this unless you're sure you really want to. **Make backups frequently.***

### Create a new publishing step for the deployment

To do this, you'll need to extend `PublishingStep` and add a new function that takes in a `DeploymentMethod<Site>` and returns a `step()`.

Here's an example:
```swift
public extension PublishingStep {
    /// Deploy the website using a given method.
    /// - warning: This will run on every generation, regardless of command line flags.
    /// - parameter method: The method to use when deploying the website.
    static func deployWhileGenerating(using method: DeploymentMethod<Site>) -> Self {
        step(named: "Deploy using \(method.name)") { context in
            try method.body(context)
        }
    }
}
```

### Use the new publishing step

Now you need to actually use this new step you just defined. Here's an example of the step defined above in use:
```swift
try MyWebsite().publish(using: [
    ...
    .deployWhileGenerating(using: .git("origin"))
])
```

The `deployWhileGenerating(using: )` step will take in any defined deployment method, including the built in `.git()` method and any others you've defined customly. 

*Again, anytime you use this step, it is deploying the site in whatever state it is after generation, which could be drastically different from what you want. **Use this with extreme caution***
