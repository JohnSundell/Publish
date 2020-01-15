# How to add syntax highlighting with Pygments
[Splash](https://github.com/JohnSundell/Splash) and its [official plugin](https://github.com/JohnSundell/SplashPublishPlugin) are great tools for highlighting swift syntax in Publish. 

However, some people write not only in Swift, but also in many other languages. There comes the [SwiftPygmentsPublishPlugin](https://github.com/Ze0nC/SwiftPygmentsPublishPlugin) to help. 

## [SwiftPygmentsPublishPlugin](https://github.com/Ze0nC/SwiftPygmentsPublishPlugin)

It is a Pygments plugin for [Publish](https://github.com/johnsundell/publish) to highlight code. 
[Pygments](https://pygments.org) is a syntax highlighting tool made in Python that supports many languages. 

## Requirements
- `Python`
- `Pygments`: [https://pygments.org](https://pygments.org)
- `SwiftPygments`: [https://github.com/Ze0nC/SwiftPygments](https://github.com/Ze0nC/SwiftPygments)
- Swift 5
- Pygments color scheme in your .css file

## How to 
1. Install Python if you don't have it on your system.
2. Install `Pygments` if you don't have it on your system. 
``` zsh
$ pip3 install pygments
```
3. Add `SwiftPygmentsPublishPlugin` to your package. 

```swift
let package = Package(
    ...
    dependencies: [
    .package(url: "https://github.com/Ze0nC/SwiftPygmentsPublishPlugin", .branch("master"))
    ],
    targets: [
        .target(
            ...
            dependencies: [
                ...
                "SwiftPygmentsPublishPlugin"
            ]
        )
    ]
    ...
)
```

4. Add `SwiftPygmentsPublishPlugin` to your build pipeline.
```swift
import SwiftPygmentsPublishPlugin
...
try DeliciousRecipes().publish(using: [
    .installPlugin(.pygments()),
    ...
    .addMarkdownFiles(),
    ...
])
```
5. Add a color scheme in your `css` file. 

Note that your need to specify language after ``` to get correct highlight. If no language is specified, `swift` will be considered as default. 


This plugin will highlight all code block but not inline codes.
Enjoy your highlighted sites!


