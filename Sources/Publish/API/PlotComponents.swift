/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot
import Ink
import Sweep

// MARK: - Nodes and Attributes

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
    /// - parameter audio: The audio to add a player for.
    /// - parameter showControls: Whether playback controls should be shown to the user.
    static func audioPlayer(for audio: Audio,
                            showControls: Bool = true) -> Node {
        AudioPlayer(
            audio: audio,
            showControls: showControls
        )
        .convertToNode()
    }

    /// Add an inline video player within the current context.
    /// - parameter video: The video to add a player for.
    /// - parameter showControls: Whether playback controls should be shown to the user.
    ///   Note that this parameter is only relevant for hosted videos.
    static func videoPlayer(for video: Video,
                            showControls: Bool = true) -> Node {
        VideoPlayer(
            video: video,
            showControls: showControls
        )
        .convertToNode()
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

// MARK: - Extensions to Plot's built-in components

public extension AudioPlayer {
    /// Create an inline player for an `Audio` model.
    /// - parameter audio: The audio to create a player for.
    /// - parameter showControls: Whether playback controls should be shown to the user.
    init(audio: Audio, showControls: Bool = true) {
        self.init(
            source: Source(url: audio.url, format: audio.format),
            showControls: showControls
        )
    }
}

// MARK: - New Component implementations

/// Component that can be used to parse a Markdown string into HTML
/// that's then rendered as the body of the component.
///
/// You can control what `MarkdownParser` that's used for parsing
/// using the `markdownParser` environment key, or by applying the
/// `markdownParser` modifier to a component.
public struct Markdown: Component {
    /// The Markdown string to render.
    public var string: String

    @EnvironmentValue(.markdownParser) private var parser

    /// Initialize an instance of this component with a Markdown string.
    /// - parameter string: The Markdown string to render.
    public init(_ string: String) {
        self.string = string
    }

    public var body: Component {
        Node.markdown(string, using: parser)
    }
}

/// Component that can be used to render an inline video player, using either
/// the `<video>` element (for hosted videos), or by embedding either a YouTube
/// or Vimeo player using an `<iframe>`.
public struct VideoPlayer: Component {
    /// The video to create a player for.
    public var video: Video
    /// Whether playback controls should be shown to the user. Note that this
    /// property is ignored when rendering a video hosted by a service like YouTube.
    public var showControls: Bool

    /// Create an inline player for a `Video` model.
    /// - parameter video: The video to create a player for.
    /// - parameter showControls: Whether playback controls should be shown to the user.
    ///   Note that this parameter is only relevant for hosted videos.
    public init(video: Video, showControls: Bool = true) {
        self.video = video
        self.showControls = showControls
    }

    public var body: Component {
        switch video {
        case .hosted(let url, let format):
            return Node.video(
                .controls(showControls),
                .source(.type(format), .src(url))
            )
        case .youTube(let id):
            let url = "https://www.youtube-nocookie.com/embed/" + id
            return iframeVideoPlayer(for: url)
        case .vimeo(let id):
            let url = "https://player.vimeo.com/video/" + id
            return iframeVideoPlayer(for: url)
            case .tedTalk(let id):
            let url = "https://embed.ted.com/talks/" + id
        }
    }

    private func iframeVideoPlayer(for url: URLRepresentable) -> Component {
        IFrame(
            url: url,
            addBorder: false,
            allowFullScreen: true,
            enabledFeatureNames: [
                "accelerometer",
                "encrypted-media",
                "gyroscope",
                "picture-in-picture"
            ]
        )
    }
}
