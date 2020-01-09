# How to use a custom date formatter

If you’d like Publish to use a custom `DateFormatter`, rather than its built-in one (which decodes dates using the `yyyy-MM-dd HH:mm` format), then you can assign a new instance to the current `PublishingContext` within a custom step:

```swift
try MyWebsite.publish(using: [
    ...
    .step(named: "Use custom DateFormatter") { context in
        let formatter = DateFormatter()
        ...
        context.dateFormatter = formatter
    }
])
```