# How to add colors to article tags

By default, all article tags have the same CSS class `tag`, so they all have same color and style. 

The [ColorfulTagsPublishPlugin](https://github.com/Ze0nC/ColorfulTagsPublishPlugin) can assign different classes to your tags automatically. Then you can give tags different looks with CSS.

Please follow the plugin's [installation guide](https://github.com/Ze0nC/ColorfulTagsPublishPlugin#installation) to add it to your website's Swift package, and then add it to your publishing pipeline:

```swift
import ColorfulTagsPublishPlugin
...
try MyWebsite().publish(using: [
    .addMarkdownFiles(),
    .installPlugin(.colorfulTags(defaultClass: "tag", variantPrefix: "variant", numberOfVariants: 8)),
    ...
    .generateHTML(withTheme: .foundation),
    ...
])
```

Please refer to the [usage guide](https://github.com/Ze0nC/ColorfulTagsPublishPlugin#usage) for details. 

Note that you will need to add CSS for the classes to actually see the effect.

