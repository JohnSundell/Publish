import Foundation
import Plot

public struct MarkdownDocument: Identifiable {
    public var id: UUID
    public var body: Node<HTML.BodyContext> = .empty
    public var title: String? = nil
    public var description: Node<HTML.BodyContext>? = nil
    public var metadata: [String: String] = .init()

    public init(
        id: UUID = .init(),
        body: Node<HTML.BodyContext> = .empty,
        title: String? = nil,
        description: Node<HTML.BodyContext>? = nil,
        metadata: [String : String] = [:]
    ) {
        self.id = id
        self.body = body
        self.title = title
        self.description = description
        self.metadata = metadata
    }
}
