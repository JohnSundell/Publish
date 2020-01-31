
# Custom themes

Publish allows customization of layout, markup and styling using Themes.

## Basics

Create a new package to contain your theme in Xcode:

`File > New > Swift Package ...`

In `Package.swift`, be sure to include Publish and Plot as dependencies:

````
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.5.0"),
        .package(url: "https://github.com/johnsundell/plot.git", from: "0.4.0"),

    ],
    targets: [
        .target(
            name: "MyTheme",
            dependencies: ["Publish", "Plot"])        
    ]
````

## Extending `Website` with protocols

???

## Injecting custom styles

???
