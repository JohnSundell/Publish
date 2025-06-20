/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Publish
import Plot

struct WithItemMetadata<ItemMetadata: WebsiteItemMetadata>: Website {
    enum SectionID: String, WebsiteSectionID {
        case one, two, three, customRawValue = "custom-raw-value"
    }

    var url: URL = URL(string: "https://swiftbysundell.com")!
    var name: String = "WebsiteName"
    var description: String = "Description"
    var language: Plot.Language = .english
    var imagePath: Publish.Path? = nil
    var faviconPath: Favicon? = nil
    var tagHTMLConfig: TagHTMLConfiguration? = .default

    func title(for sectionID: SectionID) -> String {
        sectionID.rawValue
    }
}

struct WithPodcastMetadata: Website {
    enum SectionID: String, WebsiteSectionID {
        case one, two, three, customRawValue = "custom-raw-value"
    }

    struct ItemMetadata: PodcastCompatibleWebsiteItemMetadata {
        var podcast: PodcastEpisodeMetadata?
    }

    var url: URL = URL(string: "https://swiftbysundell.com")!
    var name: String = "WebsiteName"
    var description: String = "Description"
    var language: Plot.Language = .english
    var imagePath: Publish.Path? = nil
    var faviconPath: Favicon? = nil
    var tagHTMLConfig: TagHTMLConfiguration? = .default
}

struct WithoutItemMetadata: Website {
    var url: URL = URL(string: "https://swiftbysundell.com")!
    var name: String = "WebsiteName"
    var description: String = "Description"
    var language: Plot.Language = .english
    var imagePath: Publish.Path? = nil
    var faviconPath: Favicon? = nil
    var tagHTMLConfig: TagHTMLConfiguration? = .default

    enum SectionID: String, WebsiteSectionID {
        case one, two, three, customRawValue = "custom-raw-value"
    }

    struct ItemMetadata: WebsiteItemMetadata {}
}
