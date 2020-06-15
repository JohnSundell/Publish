/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot

internal struct PodcastFeedGenerator<Site: Website> where Site.ItemMetadata: PodcastCompatibleWebsiteItemMetadata {
    let sectionID: Site.SectionID
    let itemPredicate: Predicate<Item<Site>>?
    let config: PodcastFeedConfiguration<Site>
    let context: PublishingContext<Site>
    let date: Date

    func generate() throws {
        let outputFile = try context.createOutputFile(at: config.targetPath)
        let cacheFile = try context.cacheFile(named: "feed")
        let oldCache = try? cacheFile.read().decoded() as Cache
        let section = context.sections[sectionID]
        var items = section.items.sorted(by: { $0.date > $1.date })

        if let predicate = itemPredicate?.inverse() {
            items.removeAll(where: predicate.matches)
        }

        if let date = context.lastGenerationDate, let cache = oldCache {
            if cache.config == config, cache.itemCount == items.count {
                let newlyModifiedItem = items.first { $0.lastModified > date }

                guard newlyModifiedItem != nil else {
                    return try outputFile.write(cache.feed)
                }
            }
        }

        let feed = try makeFeed(containing: items, section: section)
            .render(indentedBy: config.indentation)

        let newCache = Cache(config: config, feed: feed, itemCount: items.count)
        try cacheFile.write(newCache.encoded())
        try outputFile.write(feed)
    }
}

private extension PodcastFeedGenerator {
    struct Cache: Codable {
        let config: PodcastFeedConfiguration<Site>
        let feed: String
        let itemCount: Int
    }

    func makeFeed(containing items: [Item<Site>],
                  section: Section<Site>) throws -> PodcastFeed {
        try PodcastFeed(
            .unwrap(config.newFeedURL, Node.newFeedURL),
            .title(context.site.name),
            .description(config.description),
            .link(context.site.url(for: section)),
            .language(context.site.language),
            .lastBuildDate(date, timeZone: context.dateFormatter.timeZone),
            .pubDate(date, timeZone: context.dateFormatter.timeZone),
            .ttl(Int(config.ttlInterval)),
            .atomLink(context.site.url(for: config.targetPath)),
            .copyright(config.copyrightText),
            .author(config.author.name),
            .subtitle(config.subtitle),
            .summary(config.description),
            .explicit(config.isExplicit),
            .owner(
                .name(config.author.name),
                .email(config.author.emailAddress)
            ),
            .category(
                config.category,
                .unwrap(config.subcategory) { .category($0) }
            ),
            .type(config.type),
            .image(config.imageURL),
            .forEach(items.enumerated()) { index, item in
                guard let audio = item.audio else {
                    throw PodcastError(path: item.path, reason: .missingAudio)
                }

                guard let audioDuration = audio.duration else {
                    throw PodcastError(path: item.path, reason: .missingAudioDuration)
                }

                guard let audioSize = audio.byteSize else {
                    throw PodcastError(path: item.path, reason: .missingAudioSize)
                }

                let title = item.rssTitle
                let metadata = item.metadata.podcast

                return .item(
                    .guid(for: item, site: context.site),
                    .title(title),
                    .description(item.description),
                    .link(context.site.url(for: item)),
                    .pubDate(item.date, timeZone: context.dateFormatter.timeZone),
                    .content(for: item, site: context.site),
                    .author(config.author.name),
                    .subtitle(item.description),
                    .summary(item.description),
                    .explicit(metadata?.isExplicit ?? false),
                    .duration(audioDuration),
                    .image(config.imageURL),
                    .unwrap(metadata?.episodeNumber, Node.episodeNumber),
                    .unwrap(metadata?.seasonNumber, Node.seasonNumber),
                    .audio(
                        url: audio.url,
                        byteSize: audioSize,
                        type: "audio/\(audio.format.rawValue)",
                        title: title
                    )
                )
            }
        )
    }
}
