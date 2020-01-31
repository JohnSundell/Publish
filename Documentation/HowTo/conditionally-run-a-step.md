# How to conditionally run a publishing step

If you have a publishing step that you don’t necessarily want to run every time that your website is generated or deployed, then wrap it in an `if` conditional to only run it in case an expression evaluated to `true`:

```swift
func shouldAddPrefixToItems() -> Bool {
    ...
}

try MyWebsite().publish(using: [
    .if(shouldAddPrefixToItems(), .mutateAllItems { item in
        item.title = "Prefix: " + item.title
    })
])
```