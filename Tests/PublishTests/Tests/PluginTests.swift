/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish
import Plot
import Ink

final class PluginTests: PublishTestCase {
    func testAddingContentUsingPlugin() throws {
        let site = try publishWebsite(using: [
            .installPlugin(Plugin(name: "Plugin") { context in
                context.addItem(.stub())
            })
        ])

        XCTAssertEqual(site.sections[.one].items.count, 1)
    }

    func testAddingInkModifierUsingPlugin() throws {
        let site = try publishWebsite(using: [
            .installPlugin(Plugin(name: "Plugin") { context in
                context.markdownParser.addModifier(Modifier(
                    target: .paragraphs,
                    closure: { html, _ in
                        "<div>\(html)</div>"
                    }
                ))
            }),
            .addMarkdownFiles()
        ], content: [
            "one/a.md": "Hello"
        ])

        let items = site.sections[.one].items
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.path, "one/a")
        XCTAssertEqual(items.first?.body.html, "<div><p>Hello</p></div>")
    }

    func testAddingPluginToDefaultPipeline() throws {
        let htmlFactory = HTMLFactoryMock<WebsiteStub.WithoutItemMetadata>()
        htmlFactory.makeIndexHTML = { content, _ in
            HTML(.body(content.body.node))
        }

        try publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            content: ["index.md": "Hello, World!"],
            plugins: [Plugin(name: "Plugin") { context in
                context.markdownParser.addModifier(Modifier(
                    target: .paragraphs,
                    closure: { html, _ in
                        "<section>\(html)</section>"
                    }
                ))
            }],
            expectedHTML: ["index.html": "<section><p>Hello, World!</p></section>"]
        )
    }
}

extension PluginTests {
    static var allTests: Linux.TestList<PluginTests> {
        [
            ("testAddingContentUsingPlugin", testAddingContentUsingPlugin),
            ("testAddingInkModifierUsingPlugin", testAddingInkModifierUsingPlugin),
            ("testAddingPluginToDefaultPipeline", testAddingPluginToDefaultPipeline)
        ]
    }
}
