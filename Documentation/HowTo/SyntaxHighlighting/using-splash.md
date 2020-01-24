# How to add Swift syntax highlighting to Markdown code blocks

If you’re using Publish to write articles about Swift development, then you probably want to highlight the code blocks within those articles according to Swift’s syntax.

While there are a number of tools that you can use to accomplish this (including several JavaScript-based tools that can be added to any website), Publish is fully compatible with the Swift syntax highlighter [Splash](https://github.com/JohnSundell/Splash), which can be easily added using its [official plugin](https://github.com/JohnSundell/SplashPublishPlugin).

Start by following the plugin’s [installation instructions](https://github.com/JohnSundell/SplashPublishPlugin#installation) to add it to your website’s Swift package. Then add it to your publishing pipeline (before your Markdown files are processed):

```swift
try MyWebsite().publish(using: [
    .installPlugin(.splash(withClassPrefix: "")),
    ...
    .addMarkdownFiles()
])
```

That’ll automatically highlight all code blocks (except the ones marked using `no-highlight`). However, to actually see the syntax highlighting rendered within a web browser, you also need to define a set of CSS styles corresponding to the classes that Splash will assign to each code token. An example CSS file can be [found here](https://github.com/JohnSundell/Splash/blob/master/Examples/sundellsColors.css).