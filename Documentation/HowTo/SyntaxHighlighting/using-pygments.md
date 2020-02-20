# How to add syntax highlighting with Pygments
[Splash](https://github.com/JohnSundell/Splash) and its [official plugin](https://github.com/JohnSundell/SplashPublishPlugin) are great tools for highlighting Swift syntax when using Publish. 

However, some people write not only in Swift, but also in many other languages. That's when [SwiftPygmentsPublishPlugin](https://github.com/Ze0nC/SwiftPygmentsPublishPlugin) can be really useful.

Please follow the plugin's [installation guide](https://github.com/Ze0nC/SwiftPygmentsPublishPlugin#installation) to install Pygments and to add it to your website's Swift package, and then add it to your publishing pipeline:

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

Please refer to the [usage guide](https://github.com/Ze0nC/SwiftPygmentsPublishPlugin#usage) to see how to specify syntax language and more. 

Note that you will need to add CSS for `Pygments` to actually see the highlighted code. 
