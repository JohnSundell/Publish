
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

### Local development

Once your package is created, you can add it as a local dependency by specifying its path in an existing Publish website package:

````
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.1.0"),
        .package(path: "~/Documents/MyTheme")
    ],
    targets: [
        .target(
            name: "MySite",
            dependencies: ["Publish", "MyTheme"]
        )
    ]
````

Once added, Xcode will require you to edit the theme package from the same editor window as your website package.

### Including stylesheets and other resources

Use the `resourcePaths` argument when initializing your theme to ensure any necessary resources in your theme's package are included and copied to the `Output` folder:

````
public extension Theme {
        
    static var myTheme: Self {
        Theme(
            htmlFactory: MyThemeHTMLFactory(),
            resourcePaths: ["myThemeStyles.css"]
        )
    }
}
````

## Extending `Website` with protocols

???

## Injecting custom styles

???
