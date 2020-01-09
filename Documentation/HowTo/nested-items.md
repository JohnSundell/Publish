# How to nest items within folders

If you want to place items nested within folders, for example according to the month they were published — then simply create any folder structure that you’d like within a given section’s `Content` folder, for example like this:

```
Content
    sectionOne
        2019
            january
                one-item.md
            february
                another-item.md
                and-another-one.md
    sectionTwo
        2018
            november
                an-older-item.md
```

Publish will then output the HTML for the above items with the exact same folder structure, like this:

```
Output
    sectionOne
        2019
            january
                one-item
                    index.html
            february
                another-item
                    index.html
                and-another-one
                    index.html
    sectionTwo
        2018
            november
                an-older-item
                    index.html
```

If you’d rather specify an item’s path using Markdown metadata, instead of setting up the above kind of folder structure, then you can do that like this:

```markdown
---
path: path/to/my/item
---

# My nested item
```