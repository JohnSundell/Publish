import Foundation
import Markdown
import Parsing
import Plot

fileprivate extension Node where Context == HTML.BodyContext {
    static func element<Visitor: MarkupVisitor>(
        named: String,
        children: MarkupChildren,
        visitor: inout Visitor
    ) -> Self
    where Visitor.Result == Self
    {
        .element(named: named, nodes: children.map { $0.accept(&visitor) })
    }
}

struct Visitor: MarkupVisitor {
    typealias Result = Node<HTML.BodyContext>

    var modifiers: ModifierCollection
    var document: MarkdownDocument

    init(modifiers: ModifierCollection) {
        self.modifiers = modifiers
        self.document = .init(body: .empty, metadata: [:])
    }

    mutating func parse(markdown: Markdown.Document) {
        self.document.body = markdown.accept(&self)
    }
}

extension Visitor {
    public mutating func defaultVisit(_ markup: Markdown.Markup) -> Result {
        .group(
            markup.children.map { $0.accept(&self) }
        )
    }

    public mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> Result {
        var html = Result.element(named: "blockquote", children: blockQuote.children, visitor: &self)

        modifiers.applyModifiers(for: .blockQuote) { modifier in
            html = modifier.closure(
                html,
                &document,
                blockQuote
            )
        }

        return html
    }

    public mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> Result {
        var html = Result.element(
            named: "pre",
            nodes: [
                .element(
                    named: "code",
                    nodes: [
                        .attribute(
                            named: "class",
                            value: codeBlock.language.map { "language-\($0)" },
                            ignoreIfValueIsEmpty: true
                        ),
                        .text(codeBlock.code)
                    ]
                )
            ]
        )

        modifiers.applyModifiers(for: .codeBlock) { modifier in
            html = modifier.closure(
                html,
                &document,
                codeBlock
            )
        }

        return html
    }

    public mutating func visitDocument(_ document: Markdown.Document) -> Node<HTML.BodyContext> {
        var html = Result.group(
            document.children.map { $0.accept(&self) }
        )

        modifiers.applyModifiers(for: .document) {
            html = $0.closure(
                html,
                &self.document,
                document
            )
        }

        return html
    }

    public mutating func visitHeading(_ heading: Heading) -> Node<HTML.BodyContext> {
        if heading.level == 1, self.document.title == nil {
            self.document.title = heading.plainText
        }

        var html = Result.element(named: "h\(heading.level)", children: heading.children, visitor: &self)

        modifiers.applyModifiers(for: .heading) {
            html = $0.closure(
                html,
                &document,
                heading
            )
        }

        return html
    }

    public mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> Node<HTML.BodyContext> {
        var html = Result.selfClosedElement(named: "hr")

        modifiers.applyModifiers(for: .thematicBreak) {
            html = $0.closure(
                html,
                &document,
                thematicBreak
            )
        }

        return html
    }

    public mutating func visitHTMLBlock(_ htmlBlock: HTMLBlock) -> Node<HTML.BodyContext> {
        var html = Result.raw(htmlBlock.rawHTML)

        modifiers.applyModifiers(for: .htmlBlock) {
            html = $0.closure(
                html,
                &document,
                htmlBlock
            )
        }

        return html
    }

    public mutating func visitListItem(_ listItem: Markdown.ListItem) -> Node<HTML.BodyContext> {
        var html = Result.element(named: "li", children: listItem.children, visitor: &self)

        modifiers.applyModifiers(for: .listItem) {
            html = $0.closure(
                html,
                &document,
                listItem
            )
        }

        return html
    }

    public mutating func visitOrderedList(_ orderedList: OrderedList) -> Node<HTML.BodyContext> {
        var nodes = [
            Result.attribute(
                named: "start",
                value: orderedList.startIndex > 1 ? "\(orderedList.startIndex)" : nil,
                ignoreIfValueIsEmpty: true
            )
        ]

        nodes.append(contentsOf: orderedList.children.map { $0.accept(&self) })

        var html = Result.element(
            named: "ol",
            nodes: nodes
        )

        modifiers.applyModifiers(for: .orderedList) {
            html = $0.closure(
                html,
                &document,
                orderedList
            )
        }

        return html
    }

    public mutating func visitUnorderedList(_ unorderedList: Markdown.UnorderedList) -> Node<HTML.BodyContext> {
        var html = Result.element(named: "ul", children: unorderedList.children, visitor: &self)

        modifiers.applyModifiers(for: .unorderedList) {
            html = $0.closure(
                html,
                &document,
                unorderedList
            )
        }

        return html
    }

    public mutating func visitParagraph(_ paragraph: Markdown.Paragraph) -> Node<HTML.BodyContext> {
        var html: Result
        if let parent = paragraph.parent as? Markdown.ListItem {
            html = Result.group(paragraph.children.map { $0.accept(&self) })
        } else {
            html = Result.element(named: "p", children: paragraph.children, visitor: &self)
        }

        modifiers.applyModifiers(for: .paragraph) {
            html = $0.closure(
                html,
                &document,
                paragraph
            )
        }

        return html
    }

    public mutating func visitBlockDirective(_ blockDirective: BlockDirective) -> Node<HTML.BodyContext> {
        // TODO: Need to parse the contents of the blockDirective that will end up setting data in Self.

        var html = Result.empty
        modifiers.applyModifiers(
            for: .blockDirective(blockDirective.name)
        ) {
            html = $0.closure(
                .empty,
                &document,
                blockDirective
            )
        }

        return html
    }

    public mutating func visitInlineCode(_ inlineCode: InlineCode) -> Node<HTML.BodyContext> {
        var html = Result.element(named: "code", text: inlineCode.code)

        modifiers.applyModifiers(for: .inlineCode) {
            html = $0.closure(
                html,
                &document,
                inlineCode
            )
        }

        return html
    }

    public mutating func visitEmphasis(_ emphasis: Emphasis) -> Node<HTML.BodyContext> {
        var html = Result.element(named: "em", children: emphasis.children, visitor: &self)

        modifiers.applyModifiers(for: .emphasis) {
            html = $0.closure(
                html,
                &document,
                emphasis
            )
        }

        return html
    }

    private var imageSourceParser: some Parser<Substring, ImageSource?> {
        OneOf {
            Parse { (a: Substring, b: Substring) -> ImageSource? in
                URL(string: "\(a)\(b)").map(ImageSource.url)
            } with: {
                PrefixUpTo("://")
                Rest()
            }

            Parse {
                ImageSource.path("\($0)")
            } with: {
                Rest()
            }
        }
    }

    private enum ImageSource {
        case path(String)
        case url(URL)
    }

    public mutating func visitImage(_ image: Markdown.Image) -> Node<HTML.BodyContext> {
        guard let source = image.source else { return .empty }

        var html = Result.selfClosedElement(
            named: "img",
            attributes: [
                .src(source),
                .alt(image.plainText)
            ]
        )

        guard let imageSource = try? imageSourceParser.parse(source[...]) else {
            modifiers.applyModifiers(for: .remoteImage) {
                html = $0.closure(
                    html,
                    &document,
                    image
                )
            }

            return html
        }

        switch imageSource {
        case .path:
            modifiers.applyModifiers(for: .localImage) {
                html = $0.closure(
                    html,
                    &document,
                    image
                )
            }
        case .url:
            modifiers.applyModifiers(for: .remoteImage) {
                html = $0.closure(
                    html,
                    &document,
                    image
                )
            }
        }

        return html
    }

    public mutating func visitInlineHTML(_ inlineHTML: Markdown.InlineHTML) -> Node<HTML.BodyContext> {
        var html = Result.raw(inlineHTML.rawHTML)

        modifiers.applyModifiers(for: .inlineHTML) {
            html = $0.closure(
                html,
                &document,
                inlineHTML
            )
        }

        return html
    }

    public mutating func visitLineBreak(_ lineBreak: Markdown.LineBreak) -> Node<HTML.BodyContext> {
        var html = Result.selfClosedElement(named: "br")

        modifiers.applyModifiers(for: .lineBreak) {
            html = $0.closure(
                html,
                &document,
                lineBreak
            )
        }

        return html
    }

    public mutating func visitLink(_ link: Markdown.Link) -> Node<HTML.BodyContext> {
        var html = Result.element(
            named: "a",
            nodes: [
                .attribute(named: "href", value: link.destination, ignoreIfValueIsEmpty: true)
            ] + link.children.map { $0.accept(&self) }
        )

        modifiers.applyModifiers(for: .link) {
            html = $0.closure(
                html,
                &document,
                link
            )
        }

        return html
    }

    public mutating func visitSoftBreak(_ softBreak: SoftBreak) -> Node<HTML.BodyContext> {
        var html = Result.raw(" ")

        modifiers.applyModifiers(for: .softBreak) {
            html = $0.closure(
                html,
                &document,
                softBreak
            )
        }

        return html
    }

    public mutating func visitStrong(_ strong: Markdown.Strong) -> Node<HTML.BodyContext> {
        var html = Result.element(named: "strong", children: strong.children, visitor: &self)

        modifiers.applyModifiers(for: .strong) {
            html = $0.closure(
                html,
                &document,
                strong
            )
        }

        return html
    }

    public mutating func visitText(_ text: Markdown.Text) -> Node<HTML.BodyContext> {
        var html = Result.text(text.string)

        modifiers.applyModifiers(for: .text) {
            html = $0.closure(
                html,
                &document,
                text
            )
        }

        return html
    }

    public mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> Node<HTML.BodyContext> {
        var html = Result.element(named: "s", children: strikethrough.children, visitor: &self)

        modifiers.applyModifiers(for: .strikethrough) {
            html = $0.closure(
                html,
                &document,
                strikethrough
            )
        }

        return html
    }

    public mutating func visitTable(_ table: Markdown.Table) -> Node<HTML.BodyContext> {
        let columnAlignments = table.columnAlignments

        func columnAlignment(_ alignment: Markdown.Table.ColumnAlignment?) -> String? {
            switch alignment {
            case .left: return "left"
            case .center: return "center"
            case .right: return "right"
            case nil: return nil
            }
        }

        func visitCells(named: String, tableCells: LazyMapSequence<MarkupChildren, Markdown.Table.Cell>) -> Node<HTML.BodyContext> {
            var nodes: [Node<HTML.BodyContext>] = []
            for (i, cell) in tableCells.enumerated() {
                nodes.append(
                    .element(
                        named: named,
                        nodes: [
                            .attribute(named: "align", value: columnAlignments[i].flatMap(columnAlignment), ignoreIfValueIsEmpty: true),
                            .if(cell.colspan > 1, .attribute(named: "colspan", value: "\(cell.colspan)")),
                            .if(cell.rowspan > 1, .attribute(named: "rowspan", value: "\(cell.rowspan)")),
                            cell.accept(&self)
                        ]
                    )
                )
            }

            return .element(named: "tr", nodes: nodes)
        }

        return Result.table(
            .element(
                named: "thead",
                nodes: [
                    visitCells(named: "th", tableCells: table.head.cells)
                ]
            ),
            .if(
                !table.body.isEmpty,
                .element(
                    named: "tbody",
                    nodes: table.body.rows.map { visitCells(named: "td", tableCells: $0.cells) }
                )
            )
        )
    }
}
