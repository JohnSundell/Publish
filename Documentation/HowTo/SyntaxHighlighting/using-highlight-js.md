# How to add syntax highlighting using highlight.js

Highlight.js is a popular tool to use when adding syntax highlighting to code blocks on websites. The plugin `HighlightJSPublishPlugin` is using highlight.js and JavaScriptCore to add the syntax highlighting when the page is generated. So you can still get your webpage javascript free if you would like to.

Please follow the plugin's [installation guide](https://github.com/alex-ross/HighlightJSPublishPlugin#installation) to install HighlightJSPublishPlugin and to add it to your website's Swift package, and then add it to your publishing pipeline: 
```swift
import HighlightJSPublishPlugin
...
try MyWebsite().publish(using: [
    .installPlugin(.highlightJS()),
    ...
    .addMarkdownFiles(),
    ...
])
```

Please refer to the [usage guide](https://github.com/alex-ross/HighlightJSPublishPlugin#usage) to see how to specify syntax language and more. 

Note that you will need to add CSS for `highlight.js` to actually see the highlighted code. 

For more syntax highlighting solutions, please look at the [how to's index](../../README.md).
