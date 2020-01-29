# How to add Disqus comments to posts

## Getting a shortname from Disqus

Before installing, make sure you've [registered](https://disqus.com/register/) a Disqus [shortname](https://help.disqus.com/customer/portal/articles/286833), as this will be used to reference all of your comments and settings.


Once you've got got your shortname, you can proceed to the next step.

## JavaScript

Create a new file called `disqus.js` in your assets folder and paste this code

```javascript
(function() {  // DON'T EDIT BELOW THIS LINE
        var d = document, s = d.createElement('script');
        
        s.src = 'https://REPLACE-WITH-SHORTNAME.disqus.com/embed.js';
        
        s.setAttribute('data-timestamp', +new Date());
        (d.head || d.body).appendChild(s);
    })();
```    

Do not forget to replace `REPLACE-WITH-SHORTNAME` with your shortname

## Swift

In you `Theme.Swift` add this to the `makeItemHTML` function, this ensures that the comment thread is only shown on posts and not on Index pages

```swift
func makeItemHTML(for item: Item<Site>,
                      context: PublishingContext<Site>) throws -> HTML {
                      ...
                        .span("Tagged with: "),
                        .tagList(for: item, on: context.site),
                        
                        .div(.id("disqus_thread")),
                        .script(.src("/assets/disqus.js")),
                        .element(named: "noscript", text: "Please enable JavaScript to view the comments")
                        
                      ...
}                     
```
