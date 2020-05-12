/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot
import Ink
import Sweep

public extension Node where Context == HTML.DocumentContext {
    /// Add an HTML `<head>` tag within the current context, based
    /// on inferred information from the current location and `Website`
    /// implementation.
    /// - parameter location: The location to generate a `<head>` tag for.
    /// - parameter site: The website on which the location is located.
    /// - parameter titleSeparator: Any string to use to separate the location's
    ///   title from the name of the website. Default: `" | "`.
    /// - parameter stylesheetPaths: The paths to any stylesheets to add to
    ///   the resulting HTML page. Default: `styles.css`.
    /// - parameter rssFeedPath: The path to any RSS feed to associate with the
    ///   resulting HTML page. Default: `feed.rss`.
    /// - parameter rssFeedTitle: An optional title for the page's RSS feed.
    static func head<T: Website>(
        for location: Location,
        on site: T,
        titleSeparator: String = " | ",
        stylesheetPaths: [Path] = ["/styles.css"],
        rssFeedPath: Path? = .defaultForRSSFeed,
        rssFeedTitle: String? = nil
    ) -> Node {
        var title = location.title

        if title.isEmpty {
            title = site.name
        } else {
            title.append(titleSeparator + site.name)
        }

        var description = location.description

        if description.isEmpty {
            description = site.description
        }

        return .head(
            .encoding(.utf8),
            .siteName(site.name),
            .url(site.url(for: location)),
            .title(title),
            .description(description),
            .twitterCardType(location.imagePath == nil ? .summary : .summaryLargeImage),
            .forEach(stylesheetPaths, { .stylesheet($0) }),
            .viewport(.accordingToDevice),
            .unwrap(site.favicon, { .favicon($0) }),
            .unwrap(rssFeedPath, { path in
                let title = rssFeedTitle ?? "Subscribe to \(site.name)"
                return .rssFeedLink(path.absoluteString, title: title)
            }),
            .unwrap(location.imagePath ?? site.imagePath, { path in
                let url = site.url(for: path)
                return .socialImageLink(url)
            })
        )
    }
}

public extension Node where Context == HTML.HeadContext {
    /// Link the HTML page to an external CSS stylesheet.
    /// - parameter path: The absolute path of the stylesheet to link to.
    static func stylesheet(_ path: Path) -> Node {
        .stylesheet(path.absoluteString)
    }

    /// Declare a favicon for the HTML page.
    /// - parameter favicon: The favicon to declare.
    static func favicon(_ favicon: Favicon) -> Node {
        .favicon(favicon.path.absoluteString, type: favicon.type)
    }
}

public extension Node where Context: HTML.BodyContext {
    /// Render a location's `Content.Body` as HTML within the current context.
    /// - parameter body: The body to render.
    static func contentBody(_ body: Content.Body) -> Node {
        .raw(body.html)
    }

    /// Render a string of inline Markdown as HTML within the current context.
    /// - parameter markdown: The Markdown string to render.
    /// - parameter parser: The Markdown parser to use. Pass `context.markdownParser` to
    ///   use the same Markdown parser as the main publishing process is using.
    static func markdown(_ markdown: String,
                         using parser: MarkdownParser = .init()) -> Node {
        .raw(parser.html(from: markdown))
    }

    /// Add an inline audio player within the current context.
    /// - Parameter audio: The audio to add a player for.
    /// - Parameter showControls: Whether playback controls should be shown to the user.
    static func audioPlayer(for audio: Audio,
                            showControls: Bool = true) -> Node {
        return .audio(
            .controls(showControls),
            .source(.type(audio.format), .src(audio.url))
        )
    }

    /// Add an inline video player within the current context.
    /// - Parameter video: The video to add a player for.
    /// - Parameter showControls: Whether playback controls should be shown to the user.
    ///   Note that this parameter is only relevant for hosted videos.
    static func videoPlayer(for video: Video,
                            showControls: Bool = true) -> Node {
        switch video {
        case .hosted(let url, let format):
            return .video(
                .controls(showControls),
                .source(.type(format), .src(url))
            )
        case .youTube(let id):
            let url = "https://www.youtube-nocookie.com/embed/" + id
            return .iframeVideoPlayer(forURL: url)
        case .vimeo(let id):
            let url = "https://player.vimeo.com/video/" + id
            return .iframeVideoPlayer(forURL: url)
        }
    }
}

public extension Node where Context: HTMLLinkableContext {
    /// Assign a path to link the element to, using its `href` attribute.
    /// - parameter path: The absolute path to assign.
    static func href(_ path: Path) -> Node {
        .href(path.absoluteString)
    }
}

public extension Attribute where Context: HTMLSourceContext {
    /// Assign a source to the element, using its `src` attribute.
    /// - parameter path: The source path to assign.
    static func src(_ path: Path) -> Attribute {
        .src(path.absoluteString)
    }
}

internal extension Node where Context: RSSItemContext {
    static func guid<T>(for item: Item<T>, site: T) -> Node {
        return .guid(
            .text(item.rssProperties.guid ?? site.url(for: item).absoluteString),
            .isPermaLink(item.rssProperties.guid == nil && item.rssProperties.link == nil)
        )
    }

    static func content<T>(for item: Item<T>, site: T) -> Node {
        let baseURL = site.url
        let prefixes = (href: "href=\"", src: "src=\"")

        var html = item.rssProperties.bodyPrefix ?? ""
        html.append(item.body.html)
        html.append(item.rssProperties.bodySuffix ?? "")

        var links = [(url: URL, range: ClosedRange<String.Index>, isHref: Bool)]()

        html.scan(using: [
            Matcher(
                identifiers: [
                    .anyString(prefixes.href),
                    .anyString(prefixes.src)
                ],
                terminators: ["\""],
                handler: { url, range in
                    guard url.first == "/" else {
                        return
                    }

                    let absoluteURL = baseURL.appendingPathComponent(String(url))
                    let isHref = (html[range.lowerBound] == "h")
                    links.append((absoluteURL, range, isHref))
                }
            )
        ])

        for (url, range, isHref) in links.reversed() {
            let prefix = isHref ? prefixes.href : prefixes.src
            html.replaceSubrange(range, with: prefix + url.absoluteString + "\"")
        }

        return content(html)
    }
}

internal extension Node where Context == PodcastFeed.ItemContext {
    static func duration(_ duration: Audio.Duration) -> Node {
        return .duration(
            hours: duration.hours,
            minutes: duration.minutes,
            seconds: duration.seconds
        )
    }
}

private extension Node where Context: HTML.BodyContext {
    static func iframeVideoPlayer(forURL url: String) -> Node {
        return .iframe(
            .frameborder(false),
            .allow("accelerometer", "encrypted-media", "gyroscope", "picture-in-picture"),
            .allowfullscreen(true),
            .src(url)
        )
    }
}
