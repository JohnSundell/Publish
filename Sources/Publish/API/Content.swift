/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Plot

/// Type representing a location's main content.
public struct Content: Hashable, ContentProtocol {
    public var title: String
    public var description: String
    public var body: Body
    public var date: Date
    public var lastModified: Date
    public var imagePath: Path?
    public var audio: Audio?
    public var video: Video?
    public var isDraft: Bool

    /// Initialize a new instance of this type
    /// - parameter title: The location's title.
    /// - parameter description: A description of the location.
    /// - parameter body: The main body of the location's content.
    /// - parameter date: The location's main publishing date.
    /// - parameter lastModified: The last modification date.
    /// - parameter imagePath: A path to any image for the location.
    /// - parameter audio: Any audio data associated with this content.
    /// - parameter video: Any video data associated with this content.
    /// - parameter isDraft: Whether the content is ready to be published.
    public init(title: String = "",
                description: String = "",
                body: Body = Body(html: ""),
                date: Date = Date(),
                lastModified: Date = Date(),
                imagePath: Path? = nil,
                audio: Audio? = nil,
                video: Video? = nil,
                isDraft: Bool = false) {
        self.title = title
        self.description = description
        self.body = body
        self.date = date
        self.lastModified = lastModified
        self.imagePath = imagePath
        self.audio = audio
        self.video = video
        self.isDraft = isDraft
    }
}

public extension Content {
    struct Body: Hashable {
        public var html: String
        public var node: Node<HTML.BodyContext> { .raw(html) }
        public var isEmpty: Bool { html.isEmpty }

        public init(html: String) {
            self.html = html
        }

        public init(node: Node<HTML.BodyContext>,
                    indentation: Indentation.Kind? = nil) {
            html = node.render(indentedBy: indentation)
        }
    }
}

extension Content.Body: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(html: value)
    }
}
