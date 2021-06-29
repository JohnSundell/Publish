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

    /// Initialize a new instance of this type
    /// - parameter title: The location's title.
    /// - parameter description: A description of the location.
    /// - parameter body: The main body of the location's content.
    /// - parameter date: The location's main publishing date.
    /// - parameter lastModified: The last modification date.
    /// - parameter imagePath: A path to any image for the location.
    /// - parameter audio: Any audio data associated with this content.
    /// - parameter video: Any video data associated with this content.
    public init(title: String = "",
                description: String = "",
                body: Body = Body(html: ""),
                date: Date = Date(),
                lastModified: Date = Date(),
                imagePath: Path? = nil,
                audio: Audio? = nil,
                video: Video? = nil) {
        self.title = title
        self.description = description
        self.body = body
        self.date = date
        self.lastModified = lastModified
        self.imagePath = imagePath
        self.audio = audio
        self.video = video
    }
}

public extension Content {
    /// Type that represents the main renderable body of a piece of content.
    struct Body: Hashable {
        /// The content's renderable HTML.
        public var html: String
        /// A node that can be used to embed the content in a Plot hierarchy.
        public var node: Node<HTML.BodyContext> { .raw(html) }
        /// Whether this value doesn't contain any content.
        public var isEmpty: Bool { html.isEmpty }

        /// Initialize an instance with a ready-made HTML string.
        /// - parameter html: The content HTML that the instance should cointain.
        public init(html: String) {
            self.html = html
        }

        /// Initialize an instance with a Plot `Node`.
        /// - parameter node: The node to render. See `Node` for more information.
        /// - parameter indentation: Any indentation to apply when rendering the node.
        public init(node: Node<HTML.BodyContext>,
                    indentation: Indentation.Kind? = nil) {
            html = node.render(indentedBy: indentation)
        }

        /// Initialize an instance using Plot's `Component` API.
        /// - parameter indentation: Any indentation to apply when rendering the components.
        /// - parameter components: The components that should make up this instance's content.
        public init(indentation: Indentation.Kind? = nil,
                    @ComponentBuilder components: () -> Component) {
           self.init(node: .component(components()),
                     indentation: indentation)
       }
    }
}

extension Content.Body: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(html: value)
    }
}

extension Content.Body: Component {
    public var body: Component { node }
}
