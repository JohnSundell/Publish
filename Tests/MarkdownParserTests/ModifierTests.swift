/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Publish
import Synchronization

@Suite("Modifier", .serialized) struct ModifierTests {
    @Test func testModifierInput() {
        let state = Mutex<(allHTML: [String], allMarkdown: [String])>(([], []))
        var parser = MarkdownParser()

        parser.addModifier(for: .paragraph) { html, _, markup in
            state.withLock {
                $0.allHTML.append(html.render())
                $0.allMarkdown.append(markup.format())
            }
            return html
        }

        let html = parser.html(from: "One\n\nTwo\n\nThree")
        #expect(html == "<p>One</p><p>Two</p><p>Three</p>")
        let allHtml = state.withLock(\.allHTML)
        let allMarkdown = state.withLock(\.allMarkdown)
        #expect(allHtml == ["<p>One</p>", "<p>Two</p>", "<p>Three</p>"])
        #expect(allMarkdown == ["One", "\n\nTwo", "\n\nThree"])
    }

    @Test func testAddingModifiers() {
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

        #expect(html == #"""
        <h1>New heading</h1><p>Text LINK:<a href="url">Link</a> Code</p>
        """#)
    }

    @Test func testMultipleModifiersForSameTarget() {
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

        #expect(html == "<section><div><pre><code>Code\n</code></pre></div></section>")
    }
}
