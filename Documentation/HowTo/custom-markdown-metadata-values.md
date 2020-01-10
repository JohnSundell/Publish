# How to express custom metadata values using Markdown

Publish enables each website to define its own site-specific item metadata, through its `Website.ItemMetadata` type. When adding items using Markdown, those values can then be expressed by adding a metadata header at the top of a file (within other tools referred to as *front matter*).

Let’s say that we’re building an shopping website, and that we’ve defined a custom `productPrice` item metadata value, like this:

```swift
struct ShoppingWebsite: Website {
    struct ItemMetadata: WebsiteItemMetadata {
        var productPrice: Int
    }
    
    ...
}
```

Just by adding it to our `ItemMetadata` type, our new value can now be expressed by using its name within any item’s Markdown metadata header:

```markdown
---
productPrice: 250
---

# A fantastic product

...
```

The above implementation assumes that *all* items within our website will contain a `productPrice` declaration, since we’ve made it non-optional (which will result in an error in case it’s missing). If that’s not what we want, then we can make it an optional (`Int?`) instead:

```swift
struct ItemMetadata: WebsiteItemMetadata {
    var productPrice: Int?
}
```

Publish also supports nested metadata values, as long as they can be decoded from raw values — like strings, integers, and doubles. For example, if we wanted to also add a *product category* property to our site-specific item metadata, then we could do that by introducing a new `ProductInfo` type — like this:

```swift
// Note that our nested type must also conform to 'WebsiteItemMetadata',
// in order for Publish to be able to decode it from Markdown:
struct ProductInfo: WebsiteItemMetadata {
    var price: Int
    var category: String
}
```

We’ll then update our `ItemMetadata` type to use our new `ProductInfo` type:

```swift
struct ItemMetadata: WebsiteItemMetadata {
    var product: ProductInfo?
}
```

In order to express our nested `price` and `category` values, we simply have to specify their full path, and Publish will decode them accordingly:

```markdown
---
product.price: 250
product.category: Electronics
---

# A fantastic product

...
```

Finally, we can also use arrays within any custom metadata type (again as long as the elements of such arrays can be expressed using raw values). For example, let’s add a `keywords` property to `ProductInfo`:

```swift
struct ProductInfo: WebsiteItemMetadata {
    var price: Int
    var category: String
    var keywords: [String]
}
```

Array-based properties are expressed using comma-separate lists (just like how Publish’s built-in `tags` property is used), like this:

```markdown
---
product.price: 250
product.category: Electronics
product.keywords: low-power, efficient, accessory
---

# A fantastic product

...
```

Publish’s item metadata capabilities are incredibly powerful, since they enable us to express completely custom values in a way that’s fully type-safe.