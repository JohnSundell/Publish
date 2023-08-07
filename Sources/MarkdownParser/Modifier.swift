//
//  File.swift
//  
//
//  Created by Peter Kovacs on 6/21/23.
//

import Foundation
import Plot
import Markdown

public struct Modifier {
    public typealias Closure = (
        Node<HTML.BodyContext>,
        inout MarkdownDocument,
        Markup
    ) -> Node<HTML.BodyContext>
    public var target: Target
    public var closure: Closure
    public var file: StaticString
    public var line: Int

    public init(target: Target, closure: @escaping Closure, file: StaticString = #file, line: Int = #line) {
        self.target = target
        self.closure = closure
        self.file = file
        self.line = line
    }
}

public extension Modifier {
    enum Target: Hashable {
        case blockQuote
        case codeBlock
        case document
        case heading
        case thematicBreak
        case htmlBlock
        case listItem
        case orderedList
        case unorderedList
        case paragraph
        case blockDirective(String)
        case inlineCode
        case emphasis
        case localImage
        case remoteImage
        case inlineHTML
        case lineBreak
        case link
        case softBreak
        case strong
        case text
        case strikethrough
    }
}

internal struct ModifierCollection {
    private var modifiers: [Modifier.Target : [Modifier]]

    init(modifiers: [Modifier]) {
        self.modifiers = Dictionary(
            grouping: modifiers,
            by: \.target
        )
    }

    func applyModifiers(for target: Modifier.Target,
                        using closure: (Modifier) -> Void) {
        modifiers[target]?.forEach(closure)
    }

    mutating func insert(_ modifier: Modifier) {
        modifiers[modifier.target, default: []].append(modifier)
    }
}

