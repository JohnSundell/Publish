import Foundation
import Markdown
import Parsing

public struct MarkdownParser {
    private var modifiers: ModifierCollection

    public init() {
        self.modifiers = .init(modifiers: [])
    }

    public mutating func addModifier(
        for target: Modifier.Target,
        modifier: @escaping Modifier.Closure,
        file: StaticString = #file,
        line: Int = #line
    ) {
        modifiers.insert(.init(target: target, closure: modifier, file: file, line: line))
    }

    public func html(from markdown: String) -> String {
        parse(markdown).body.render()
    }

    public func parse(_ markdown: String) -> MarkdownDocument {
        var visitor = Visitor(modifiers: modifiers)
        var markdown = markdown

        do {
            (visitor.document.metadata, markdown) = try markdownMetadata.parse(markdown)
        } catch let error {
            print(error)
        }

        visitor.parse(
            markdown: Markdown.Document(
                parsing: markdown,
                options: [.parseBlockDirectives]
            )
        )

        return visitor.document
    }

    private var identifier: some Parser<Substring, String> {
        Parse {
            "\($0)\($1)"
        } with: {
            CharacterSet.letters
            Prefix {
                $0.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) }
            }
        }
    }

    private var dottedIdentifier: some Parser<Substring, String> {
        Many(into: "") { (s: inout String, e: String) in
            if !s.isEmpty { s.append(".") }
            s.append(e)
        } element: {
            identifier
        } separator: {
            "."
        }
    }

    private var keyAndValue: some Parser<Substring, (String, String)> {
        Parse {
            Whitespace(.horizontal)

            dottedIdentifier

            Whitespace(.horizontal)
            ":"
            Whitespace(.horizontal)

            Prefix {
                $0 != "\r" && $0 != "\n"
            }
            .map(.string)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        }
    }

    private var metadataDictionary: some Parser<Substring, [String: String]> {
        Many(into: [:]) {
            $0[$1.0] = $1.1
        } element: {
            keyAndValue
        } separator: {
            Whitespace(.vertical)
        }
    }

    private var separator: some Parser<Substring, Void> {
        Skip {
            Whitespace(.vertical)
            "---"
            OneOf {
                Whitespace(.vertical)
                End()
            }
        }
    }

    private var markdownMetadata: some Parser<Substring, ([String: String], String)> {
        Parse {
            Optionally {
                separator
                metadataDictionary
                separator
            }.map {
                $0 ?? [:] as [String: String]
            }

            OneOf {
                End().map { "" }
                Rest().map(.string)
            }
        }
    }
}
