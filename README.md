<p align="center">
    <img src="Logo.png" width="400" max-width="90%" alt="Publish" />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/Swift-5.2-orange.svg" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/swiftpm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
     <img src="https://img.shields.io/badge/platforms-mac+linux-brightgreen.svg?style=flat" alt="Mac + Linux" />
    <a href="https://twitter.com/johnsundell">
        <img src="https://img.shields.io/badge/twitter-@johnsundell-blue.svg?style=flat" alt="Twitter: @johnsundell" />
    </a>
</p>

Welcome to **Publish**, a static site generator built specifically for Swift developers. It enables entire websites to be built using Swift, and supports themes, plugins and tons of other powerful customization options.

Publish is used to build all of [swiftbysundell.com](https://swiftbysundell.com).

## Websites as Swift packages

When using Publish, each website is defined as a Swift package, which acts as the configuration as to how the website should be generated and deployed — all using native, type-safe Swift code. For example, here’s what the configuration for a food recipe website might look like:

```swift
struct DeliciousRecipes: Website {
    enum SectionID: String, WebsiteSectionID {
        case recipes
        case links
        case about
    }

    struct ItemMetadata: WebsiteItemMetadata {
        var ingredients: [String]
        var preparationTime: TimeInterval
    }

    var url = URL(string: "https://cooking-with-john.com")!
    var name = "Delicious Recipes"
    var description = "Many very delicious recipes."
    var language: Language { .english }
    var imagePath: Path? { "images/logo.png" }
}
```

Each website built using Publish can freely decide what kind of sections and metadata that it wants to support. Above, we’ve added three sections — *Recipes*, *Links*, and *About* — which can then contain any number of items. We’ve also added support for our own, site-specific item metadata through the `ItemMetadata` type, which we’ll be able to use in a fully type-safe manner all throughout our publishing process.

## Start out simple, and customize when needed

While Publish offers a really powerful API that enables almost every aspect of the website generation process to be customized and tweaked, it also ships with a suite of convenience APIs that aims to make it as quick and easy as possible to get started.

To start generating the *Delicious Recipes* website we defined above, all we need is a single line of code, that tells Publish which theme to use to generate our website’s HTML:

```swift
try DeliciousRecipes().publish(withTheme: .foundation)
```

*Not only does the above call render our website’s HTML, it also generates an RSS feed, a site map, and more.*

Above we’re using Publish’s built-in Foundation theme, which is a very basic theme mostly provided as a starting point, and as an example of how Publish themes may be built. We can of course at any time replace that theme with our own, custom one, which can include any sort of HTML and resources that we’d like.

By default, Publish will generate a website’s content based on Markdown files placed within that project’s `Content` folder, but any number of content items and custom pages can also be added programmatically.

**Publish supports three types of content:**

**Sections**, which are created based on the members of each website’s `SectionID` enum. Each section both has its own HTML page, and can also act as a container for a list of **Items**, which represent the nested HTML pages within that section. Finally, **Pages** provide a way to build custom free-form pages that can be placed into any kind of folder hierarchy.

Each `Section`, `Item`, and `Page` can define its own set of Content — which can range from text (like titles and descriptions), to HTML, audio, video and various kinds of metadata.

Here’s how we could extend our basic `publish()` call from before to inject our own custom publishing pipeline — which enables us to define new items, modify sections, and much more:

```swift
try DeliciousRecipes().publish(
    withTheme: .foundation,
    additionalSteps: [
        // Add an item programmatically
        .addItem(Item(
            path: "my-favorite-recipe",
            sectionID: .recipes,
            metadata: DeliciousRecipes.ItemMetadata(
                ingredients: ["Chocolate", "Coffee", "Flour"],
                preparationTime: 10 * 60
            ),
            tags: ["favorite", "featured"],
            content: Content(
                title: "Check out my favorite recipe!"
            )
        )),
        // Add default titles to all sections
        .step(named: "Default section titles") { context in
            context.mutateAllSections { section in
                guard section.title.isEmpty else { return }
                
                switch section.id {
                case .recipes:
                    section.title = "My recipes"
                case .links:
                    section.title = "External links"
                case .about:
                    section.title = "About this site"
                }
            }
        }
    ]
)
```

Of course, defining all of a program’s code in one single place is rarely a good idea, so it’s recommended to split up a website’s various generation operations into clearly separated steps — which can be defined by extending the `PublishingStep` type with static properties or methods, like this:

```swift
extension PublishingStep where Site == DeliciousRecipes {
    static func addDefaultSectionTitles() -> Self {
        .step(named: "Default section titles") { context in
            context.mutateAllSections { section in
                guard section.title.isEmpty else { return }

                switch section.id {
                case .recipes:
                    section.title = "My recipes"
                case .links:
                    section.title = "External links"
                case .about:
                    section.title = "About this site"
                }
            }
        }
    }
}
```

*Each publishing step is passed an instance of `PublishingContext`, which it can use to mutate the current context in which the website is being published — including its files, folders, and content.*

Using the above pattern, we can implement any number of custom publishing steps that’ll fit right in alongside all of the default steps that Publish ships with. This enables us to construct really powerful pipelines in which each step performs a single part of the generation process:

```swift
try DeliciousRecipes().publish(using: [
    .addMarkdownFiles(),
    .copyResources(),
    .addFavoriteItems(),
    .addDefaultSectionTitles(),
    .generateHTML(withTheme: .delicious),
    .generateRSSFeed(including: [.recipes]),
    .generateSiteMap()
])
```

*Above we’re constructing a completely custom publishing pipeline by calling the `publish(using:)` API.*

To learn more about Publish’s built-in publishing steps, [check out this file](https://github.com/JohnSundell/Publish/blob/master/Sources/Publish/API/PublishingStep.swift).

## Building an HTML theme

Publish uses [Plot](https://github.com/johnsundell/plot) as its HTML theming engine, which enables entire HTML pages to be defined using Swift. When using Publish, it’s recommended that you build your own website-specific theme — that can make full use of your own custom metadata, and be completely tailored to fit your website’s design.

Themes are defined using the `Theme` type, which uses an `HTMLFactory` implementation to create all of a website’s HTML pages. Here’s an excerpt of what the implementation for the custom `.delicious` theme used above may look like:

```swift
extension Theme where Site == DeliciousRecipes {
    static var delicious: Self {
        Theme(htmlFactory: DeliciousHTMLFactory())
    }

    private struct DeliciousHTMLFactory: HTMLFactory {
        ...
        func makeItemHTML(for item: Item<DeliciousRecipes>,
                          context: PublishingContext<DeliciousRecipes>) throws -> HTML {
            HTML(
                .head(for: item, on: context.site),
                .body(
                    .ul(
                        .class("ingredients"),
                        .forEach(item.metadata.ingredients) {
                            .li(.text($0))
                        }
                    ),
                    .p(
                        "This will take around ",
                        "\(Int(item.metadata.preparationTime / 60)) ",
                        "minutes to prepare"
                    ),
                    .contentBody(item.body)
                )
            )
        }
        ...
    }
}
```

Above we’re able to access both built-in item properties, and the custom metadata properties that we defined earlier as part of our website’s `ItemMetadata` struct, all in a way that retains full type safety.

*More thorough documentation on how to build Publish themes, and some of the recommended best practices for doing so, will be added shortly.*

## Building plugins

Publish also supports plugins, which can be used to share setup code between various projects, or to extend Publish’s built-in functionality in various ways. Just like publishing steps, plugins perform their work by modifying the current `PublishingContext` — for example by adding files or folders, by mutating the website’s existing content, or by adding Markdown parsing modifiers.

Here’s an example of a plugin that ensures that all of a website’s items have tags:

```swift
extension Plugin {
    static var ensureAllItemsAreTagged: Self {
        Plugin(name: "Ensure that all items are tagged") { context in
            let allItems = context.sections.flatMap { $0.items }

            for item in allItems {
                guard !item.tags.isEmpty else {
                    throw PublishingError(
                        path: item.path,
                        infoMessage: "Item has no tags"
                    )
                }
            }
        }
    }
}
```

Plugins are then installed by adding the `installPlugin` step to any publishing pipeline:

```swift
try DeliciousRecipes().publish(using: [
    ...
    .installPlugin(.ensureAllItemsAreTagged)
])
```

*If your plugin is hosted on GitHub you can use the `publish-plugin` [topic](https://help.github.com/en/github/administering-a-repository/classifying-your-repository-with-topics#adding-topics-to-your-repository) so it can be found with the rest of [community plugins](https://github.com/topics/publish-plugin?l=swift).*

For a real-world example of a Publish plugin, check out the [official Splash plugin](https://github.com/johnsundell/splashpublishplugin), which makes it really easy to integrate the [Splash syntax highlighter](https://github.com/johnsundell/splash) with Publish.

## System requirements

To be able to successfully use Publish, make sure that your system has Swift version 5.2 (or later) installed. If you’re using a Mac, also make sure that `xcode-select` is pointed at an Xcode installation that includes the required version of Swift, and that you’re running macOS Catalina (10.15) or later. 

Please note that Publish **does not** officially support any form of beta software, including beta versions of Xcode and macOS, or unreleased versions of Swift.

## Installation

Publish is distributed using the [Swift Package Manager](https://swift.org/package-manager). To install it into a project, add it as a dependency within your `Package.swift` manifest:

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.1.0")
    ],
    ...
)
```

Then import Publish wherever you’d like to use it:

```swift
import Publish
```

For more information on how to use the Swift Package Manager, check out [this article](https://www.swiftbysundell.com/articles/managing-dependencies-using-the-swift-package-manager), or [its official documentation](https://swift.org/package-manager).

Publish also ships with a command line tool that makes it easy to set up new website projects, and to generate and deploy existing ones. To install that command line tool, simply run `make` within a local copy of the Publish repo:

```
$ git clone https://github.com/JohnSundell/Publish.git
$ cd Publish
$ make
```

Then run `publish help` for instructions on how to use it.

## Running and deploying

Since all Publish websites are implemented as Swift packages, they can be generated simply by opening up a website’s package in Xcode (by opening its `Package.swift` file), and then running it using the `Product > Run` command (or `⌘+R`).

Publish can also facilitate the deployment of websites to external servers through its `DeploymentMethod` API, and ships with built-in implementations for Git and GitHub-based deployments. To define a deployment method for a website, add the `deploy` step to your publishing pipeline:

```swift
try DeliciousRecipes().publish(using: [
    ...
    .deploy(using: .gitHub("johnsundell/delicious-recipes"))
])
```

Even when added to a pipeline, deployment steps are disabled by default, and are only executed when the `--deploy` command line flag was passed (which can be added through Xcode’s `Product > Scheme > Edit Scheme...` menu), or by running the command line tool using `publish deploy`.

Publish can also start a `localhost` web server for local testing and development, by using the `publish run` command. To regenerate site content with the server running, use Product > Run on your site's package in Xcode.

## Quick start

To quickly get started with Publish, install the command line tool by first cloning this repository, and then run `make` within the cloned folder:

```
$ git clone https://github.com/JohnSundell/Publish.git
$ cd Publish
$ make
```

_**Note**: If you encounter an error while running `make`, ensure that you have your Command Line Tools location set from Xcode's preferences. It's in Preferences > Locations > Locations > Command Line Tools. The dropdown will be blank if it hasn't been set yet._

Then, create a new folder for your new website project and simply run `publish new` within it to get started:

```
$ mkdir MyWebsite
$ cd MyWebsite
$ publish new
```

Finally, run `open Package.swift` to open up the project in Xcode to start building your new website.

## Additional documentation

You can find a growing collection of additional documentation about Publish’s various features and capabilities within the [Documentation folder](Documentation).

## Design and goals

Publish was first and foremost designed to be a powerful and heavily customizable tool for building static websites in Swift — starting with [Swift by Sundell](https://swiftbysundell.com), a website which has over 300 individual pages and a pipeline consisting of over 25 publishing steps.

While the goal is definitely also to make Publish as accessible and easy to use as possible, it will most likely keep being a quite low-level tool that favors code-level control over file system configuration files, and customizability over strongly held conventions.

The main trade-off of that design is that Publish will likely have a steeper learning curve than most other static site generators, but hopefully it’ll also offer a much greater degree of power, flexibility and type safety as a result. Over time, and with the community’s help, we should be able to make that learning curve much less steep though — through much more thorough documentation and examples, and through shared tools and convenience APIs.

Publish was also designed with code reuse in mind, and hopefully a much larger selection of themes, tools, plugins and other extensions will be developed by the community over time.

## Contributions and support

Publish is developed completely in the open, and your contributions are more than welcome.

Before you start using Publish in any of your projects, it’s highly recommended that you spend a few minutes familiarizing yourself with its documentation and internal implementation, so that you’ll be ready to tackle any issues or edge cases that you might encounter.

Since this is a very young project, it’s likely to have many limitations and missing features, which is something that can really only be discovered and addressed as more people start using it. While Publish is used in production to build all of [Swift by Sundell](https://swiftbysundell.com), it’s recommended that you first try it out for your specific use case, to make sure it supports the features that you need.

This project does not come with GitHub Issues-based support, and users are instead encouraged to become active participants in its continued development — by fixing any bugs that they encounter, or by improving the documentation wherever it’s found to be lacking.

If you wish to make a change, [open a Pull Request](https://github.com/JohnSundell/Publish/pull/new) — even if it just contains a draft of the changes you’re planning, or a test that reproduces an issue — and we can discuss it further from there.

Hope you’ll enjoy using Publish!
