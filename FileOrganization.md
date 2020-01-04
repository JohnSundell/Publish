## Cool URL management

[Cool URIs don't change](https://www.w3.org/Provider/Style/URI) implies that the best practice is to keep a nice URI for your content.

[Clean URL](https://en.wikipedia.org/wiki/Clean_URL#Slug) shows how a Slug feature can help with the cool URI.  

The slug offers an alternative to using the markdown filename as the URI ending.  Many implementations use the Markdown frontmatter to specify the slug. (such as [Hugo Slug](https://gohugo.io/content-management/organization/#slug-1) )

The current Publish implementation uses the filename as the Cool URI. It seems to be determined before the Markdown front-matter is parsed and decoded. The publishing path should be determined after parsing the front-matter.  I believe the inclusion in a Tag Index page occurs after such front-matter declares the tags.

At the moment I am publishing this discussion paper, rather than submitting code as the code change looks significant.
