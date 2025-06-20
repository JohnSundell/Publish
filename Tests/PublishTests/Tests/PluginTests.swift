/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Synchronization
import Foundation
import Publish
import Plot

@Suite("Plugin", .serialized) struct PluginTests: PublishTestCase {
    @Test func testAddingContentUsingPlugin() throws {
        let site = try publishWebsite(using: [
            .installPlugin(Plugin(name: "Plugin") { context in
                context.addItem(.stub())
            })
        ])

        #expect(site.sections[.one].items.count ==  1)
    }

    @Test func testAddingInkModifierUsingPlugin() throws {
        let site = try publishWebsite(using: [
            .installPlugin(Plugin(name: "Plugin") { context in
                context.addModifier(for: .paragraph) { html, document, markup in
                        .div(html)
                }
            }),
            .addMarkdownFiles()
        ], content: [
            "one/a.md": "Hello"
        ])

        let items = site.sections[.one].items
        #expect(items.count ==  1)
        #expect(items.first?.path ==  "one/a")
        #expect(items.first?.body.html ==  "<div><p>Hello</p></div>")
    }

    @Test func testAddingPluginToDefaultPipeline() throws {
        let htmlFactory = HTMLFactoryMock<WithoutItemMetadata>(
            makeIndexHTML: { content, _ in
                HTML(.body(content.body.node))
            }
        )

        try publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            content: ["index.md": "Hello, World!"],
            plugins: [Plugin(name: "Plugin") { context in
                context.addModifier(for: .paragraph) { html, document, markup in
                        .section(html)
                }
            }],
            expectedHTML: ["index.html": "<section><p>Hello, World!</p></section>"]
        )
    }
}
