/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot

internal struct RSSFeedGenerator<Site: Website> {
    let includedSectionIDs: Set<Site.SectionID>
    let config: RSSFeedConfiguration
    let context: PublishingContext<Site>

    func generate() throws {
        var items = [Item<Site>]()

        for sectionID in includedSectionIDs {
            items += context.sections[sectionID].items
        }

        items.sort { $0.date > $1.date }

        let feed = makeFeed(containing: items)
        let file = try context.createOutputFile(at: config.targetPath)
        try file.write(feed.render(indentedBy: config.indentation))
    }
}

private extension RSSFeedGenerator {
    func makeFeed(containing items: [Item<Site>], currentDate: Date = Date()) -> RSS {
        RSS(
            .title(context.site.name),
            .description(context.site.description),
            .link(context.site.url),
            .language(context.site.language),
            .lastBuildDate(currentDate, timeZone: context.dateFormatter.timeZone),
            .pubDate(currentDate, timeZone: context.dateFormatter.timeZone),
            .ttl(Int(config.ttlInterval)),
            .atomLink(context.site.url(for: config.targetPath)),
            .forEach(items.prefix(config.maximumItemCount)) { item in
                .item(
                    .guid(for: item, site: context.site),
                    .title(item.rssTitle),
                    .description(item.description),
                    .link(context.site.url(for: item)),
                    .pubDate(item.date, timeZone: context.dateFormatter.timeZone),
                    .content(for: item, site: context.site)
                )
            }
        )
    }
}
