/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class ModifierTests: XCTestCase {
    func testModifierInput() {
        var allHTML = [String]()
        var allMarkdown = [String]()
        var parser = MarkdownParser()
        parser.addModifier(for: .paragraph) { html, _, markup in
            allHTML.append(html.render())
            allMarkdown.append(markup.format())
            return html
        }

        let html = parser.html(from: "One\n\nTwo\n\nThree")
        XCTAssertEqual(html, "<p>One</p><p>Two</p><p>Three</p>")
        XCTAssertEqual(allHTML, ["<p>One</p>", "<p>Two</p>", "<p>Three</p>"])
        XCTAssertEqual(allMarkdown, ["One", "\n\nTwo", "\n\nThree"])
    }

    func testAddingModifiers() {
        var parser = MarkdownParser()
        parser.addModifier(for: .heading) { _, _, _ in
            return .h1(.text("New heading"))
        }
        parser.addModifier(for: .link) { html, _, _ in
            return .group([
                .text("LINK:"),
                html
            ])
        }
        parser.addModifier(for: .inlineCode) { _, _, _ in
            return .text("Code")
        }

        let html = parser.html(from: """
        # Heading

        Text [Link](url) `code`
        """)

        XCTAssertEqual(html, #"""
        <h1>New heading</h1><p>Text LINK:<a href="url">Link</a> Code</p>
        """#)
    }

    func testMultipleModifiersForSameTarget() {
        var parser = MarkdownParser()

        parser.addModifier(for: .codeBlock) { html, _, _ in
            return .div(html)
        }

        parser.addModifier(for: .codeBlock) { html, _, _ in
            return .section(html)
        }

        let html = parser.html(from: """
        ```
        Code
        ```
        """)

        XCTAssertEqual(html, "<section><div><pre><code>Code\n</code></pre></div></section>")
    }
}
