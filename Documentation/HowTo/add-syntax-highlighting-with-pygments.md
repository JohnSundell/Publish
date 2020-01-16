# How to add syntax highlighting with Pygments
[Splash](https://github.com/JohnSundell/Splash) and its [official plugin](https://github.com/JohnSundell/SplashPublishPlugin) are great tools for highlighting swift syntax in Publish. 

However, some people write not only in Swift, but also in many other languages. There comes the [SwiftPygmentsPublishPlugin](https://github.com/Ze0nC/SwiftPygmentsPublishPlugin) to help. 

Please follow the plugin's [installation guide](https://github.com/Ze0nC/SwiftPygmentsPublishPlugin#installation) to install pygments and add it to your website's Swift package, and then add it to publishing pipeline:

```swift
import SwiftPygmentsPublishPlugin
...
try MyWebsite().publish(using: [
    .installPlugin(.pygments()),
    ...
    .addMarkdownFiles(),
    ...
])
```

Please refer to [usage guide](https://github.com/Ze0nC/SwiftPygmentsPublishPlugin#usage) to see how to specify syntax language and more. 

Note that you will need to add css for `Pygments` to actually see the highlighted code. 
