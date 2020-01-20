# Adding Sections and Pages

Publish works with two main types of pages: Sections and Pages.

A **Section** is a top-level page which shows up in the menu.
A **Page** is a stand-alone page which you can assign any URL. These do not show up in the menu.

## Creating a new Section

To create your sections, open up the main.swift file and fill in each section inside the `SectionID` enum like below:
```
struct MyWebsite: Website {
  enum SectionID: String, WebsiteSectionID {
    // Add the sections that you want your website to contain here:
    case blog
    case about
  }
}
```

### Adding content to your section-page

To add content to these sections, you have a few options: markdown or manual Swift-code. To create your section using markdown, you must create a folder inside the Content-folder with the same name as your enum case. In the case above, you should create the folders: `/Content/articles` and `/Content/about-me`.

To use a different folder name, you can assign a raw string value to the enum case like this: 
```
struct MyWebsite: Website {
  enum SectionID: String, WebsiteSectionID {
    case blog = "articles"
    case about = "about-me"
  }
}
```

To create a page for the URL http://website.com/articles/ you must create the folder `/Content/articles`.
In this folder you should add an index.md file with the content you wish. This file will then serve as your sections "front-page".

The file `/Content/articles/index.md` could look like so: 
```
# Articles

Every week I write articles on the blog. See them in the list below.
```

With this added, run the project. Publish will now generate your site, and you can navigate to your new sections.

## Creating a new Page

Pages work exactly the same way as Sections, however, you should no longer add a case to the enum.

Just like Sections you should add a top-level folder, and an index.md file inside, for example: `/Content/about/index.md` or `Content/contact/index.md`, with your desired contents.

When you run Publish, URLs will be generated accordingly to generate the URLs: `http://website.com/about` and `http://website.com/contact` respectively.

So what is the difference?

Anything you add as a SectionID will show up in the menu. Regular folders will not show up without adding a case.

## Learn more

To learn more about this and dig deep, check out [MarkdownFileHandler.swift](https://github.com/JohnSundell/Publish/blob/master/Sources/Publish/Internal/MarkdownFileHandler.swift). Keep playing around with it!
