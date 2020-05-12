# How to add Disqus comments to item pages

## Getting a shortname from Disqus

Before proceeding, make sure that you've [registered](https://disqus.com/register/) a Disqus [shortname](https://help.disqus.com/customer/portal/articles/286833), as this will be used to reference all of your comments and settings.

Once you've got your shortname, you can proceed with the next steps.

## JavaScript

Create a new file called `disqus.js` in your `Resources` folder and paste this code within that file:

```javascript
(function() {
    var t = document,
        e = t.createElement("script");
    e.src = "https://REPLACE-WITH-SHORTNAME.disqus.com/embed.js", e.setAttribute("data-timestamp", +new Date), (t.head || t.body).appendChild(e)
})();
```    

Don't forget to replace `REPLACE-WITH-SHORTNAME` with your shortname.

## Swift

In your theme file add the following code to your `makeItemHTML` function. This ensures that comment threads are only shown on item pages:

```swift
func makeItemHTML(for item: Item<Site>,
                  context: PublishingContext<Site>) throws -> HTML {
    ...
    .div(.id("disqus_thread")),
    .script(.src("/disqus.js")),
    .element(named: "noscript", text: "Please enable JavaScript to view the comments")
    ...
}                     
```
