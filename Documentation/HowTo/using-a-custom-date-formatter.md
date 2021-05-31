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

Alternatively,  `ISO8601DateFormatter` may be used rather than defining a custom date formatter also via the custom publishing step.

```swift
try MyWebsite.publish(using: [
...
    .step(named: "Use ISO8601DateFormatter") { context in
        if #available(OSX 10.12, *) {
            context.dateFormatter = ISO8601DateFormatter()
        }
    }
])
```
