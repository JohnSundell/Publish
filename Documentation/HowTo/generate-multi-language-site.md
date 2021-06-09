#  Generate Multi-Language Site

This post talks about how to produce multi-language site using Publish.
For example, `https://example.com/en/post/title/` and  `https://example.com/zh/post/title/` for two language versions of the same post, where `en` and `zh` specifies language.

This feature did not come with standard `Website` struct of Publish. It needs some tweaks to make this possible.

## Basic Usage

### Generate Publish Project

Generate a new Publish project if you haven't got one. Check introduction in official readme. [https://github.com/JohnSundell/Publish](https://github.com/JohnSundell/Publish)

If you already have a working Publish project, you may skip this step and modify the existing one.

### Setup Your Website

- Modify your website to conform to `MultiLanguageWebsite` instead of `Website`.
- Add a new variable `var languages: [Language]`, an array of languages your website has.
- Modify the `ItemMetadata` to conform to `MultiLanguageWebsiteItemMetadata` instead of `WebsiteItemMetadata`.
- Add a variable in `ItemMetadata`: `var alternateLinkIdentifier: String?`.
- *Optional* Remove the `var language: Language` variable, or change it to default language of your website.

A modified version of the website that supports English and Chinese would look like below:

```swift
// This type acts as the configuration for your website.
struct InternationalWebsite: MultiLanguageWebsite {
    // The languages of your website. The first language becomes default language.
    var languages: [Language] = [.english, .chinese, .japanese]
    
    enum SectionID: String, WebsiteSectionID {
        // Add the sections that you want your website to contain here:
        case posts
    }

    struct ItemMetadata: MultiLanguageWebsiteItemMetadata {
        // A metadata entry to correlate posts in different languages.
        var alternateLinkIdentifier: String?
        
        // Add any site-specific metadata that you want to use here.
    }

    // Update these properties to configure your website:
    var url = URL(string: "https://your-website-url.com")!
    var name = "InternationalWebsite
    var description = "A description of InternationalWebsite"
    var imagePath: Path? { nil }
}
```

### Arrange Markdown Files

By default, the markdown files for posts are located in 'Content' folder, with the following structure:

```
Content/
    SectionOne/
        PostOne.md
        PostTwo.md
    SectionTwo/
        PostThree.md
```

Change the above structure and make a folder for each language, where the folder name is language code of the language.
You may find a list of supported languages in `Language.swift` of Plot.

```
en/
    SectionOne/
        PostOne.md
        PostTwo.md
    SectionTwo/
        PostThree.md
        
zh/
    SectionOne/
        PostOne.md
        PostTwo.md
    SectionTwo/
        PostThree.md
        
ja/
    SectionOne/
        PostOne.md
        PostTwo.md
    SectionTwo/
        PostThree.md
```

### Localize Theme

Localize the Theme you are using to show different versions for languages. 

For example, the `makeIndexHTML()` becomes 

```swift
func makeIndexHTML(for index: Index,
                   context: PublishingContext<Site>) throws -> HTML {
    HTML(
        .lang(index.language!),                 // Use language of the index.
        .head(for: index, on: context.site),
        .body(
            .header(for: context, selectedSection: nil),
            .wrapper(
                .h1(.text(index.title)),
                .p(
                    .class("description"),
                    .text(context.site.description)
                ),
                .h2("Latest content"),
                .itemList(
                    for: context.allItems(
                        sortedBy: \.date,
                        in: index.language!,    // Get items in the specific language only.
                        order: .descending
                    ),
                    on: context.site
                )
            ),
            .footer(for: context.site)
        )
    )
}
```

You may need to localize the text of the website, *e.g.* section names, links, etc. 

It is the time to use your creativity to make your own website localized.

## More Usage 

### Customize the name of content folder name of each language.

By default, Publish process markdown files of each language located in folder named by language code, *e.g.* en, zh, etc.
To change it, implement the following method of your website:

```
extension InternationalWebsite {
    func contentFolder(for language: Language) -> String {
        switch language {
        case .english:
            return "English Content"    // "en" by default
        case .chinese:
            return "Chinese Content"    // "zh" by default
        case .japanese:
            return "Japanese Content"   // "ja" by default
        default:
            return language.rawValue
        }
    }
}
```

### Customize the language component of output path.

By default, Publish outputs html files of each language located in folder named by language code, *e.g.* en, zh, etc.
To change it, implement the following method of your website:

```
extension InternationalWebsite {
    func pathPrefix(for language: Language) -> String {
        switch language {
        case .english:
            return "us"             // "en" by default
        case .chinese:
            return "cn"             // "zh" by default
        case .japanese:
            return "jp"             // "ja" by default
        default:
            return language.rawValue
        }
    }
}
```

### Specify the language of markdown file.

You may specify then language of markdown file by setting `language` to language code in metadata.

```
---
language: en
---
```

### Correlate markdown files in different languages

By default, markdown files with the same path are considered as language variations of the same item. 
If you want to correlate markdown files with different file name, e.g.

- en/Section/example.md in English
- zh/Section/样例.md in Chinese
- ja/Section/例.md in Japanese

You need to correlate them by setting `alternateLinkIdentifier` to the same value in metadata of the above files.

```
---
alternateLinkIdentifier: example-markdown
---
```

