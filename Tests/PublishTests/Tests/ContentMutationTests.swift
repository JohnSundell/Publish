/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Publish
import Synchronization
import Foundation

@Suite("Content Mutation", .serialized) struct ContentMutationTests: PublishTestCase {
    @Test func testAddingItemUsingClosureAPI() throws {
        let site = try publishWebsite(using: [
            .step(named: "Custom") { context in
                context.addItem(
                    to: .one,
                    at: "path",
                    withMetadata: .init()
                ) { item in
                    item.title = "Hello, world!"
                }
            }
        ])

        #expect(site.sections[.one].items.count == 1)
        #expect(site.sections[.one].items.first?.title == "Hello, world!")
    }

    @Test func testAddingItemUsingPlotHierarchy() throws {
        let site = try publishWebsite(using: [
            .addItem(Item.stub().setting(\.body,
                to: Content.Body(node: .div("Plot!"))
            ))
        ])

        #expect(site.sections[.one].items.count == 1)
        #expect(site.sections[.one].items.first?.body.html == "<div>Plot!</div>")
    }

    @Test func testRemovingItemsMatchingPredicate() throws {
        let items = [
            Item.stub(withPath: "a").setting(\.tags, to: ["one"]),
            Item.stub(withPath: "b").setting(\.tags, to: ["one", "two"])
        ]

        let site = try publishWebsite(using: [
            .addItems(in: items),
            .removeAllItems(matching: \.tags ~= "two")
        ])

        #expect(site.sections[.one].items == [items[0]])
        #expect(site.sections[.one].item(at: "b") == nil, "Item indexes not updated")
    }

    @Test func testMutatingAllSections() throws {
        let site = try publishWebsite(using: [
            .step(named: "Set section titles") { context in
                context.mutateAllSections { section in
                    section.title = section.id.rawValue
                }
            }
        ])

        #expect(site.sections[.one].title == "one")
        #expect(site.sections[.two].title == "two")
        #expect(site.sections[.three].title == "three")
    }

    @Test func testMutatingAllItems() throws {
        let site = try publishWebsite(using: [
            .addItem(.stub(withSectionID: .one)),
            .addItem(.stub(withSectionID: .two)),
            .addItem(.stub(withSectionID: .three)),
            .mutateAllItems { item in
                item.title = "Mutated title"
            }
        ])

        #expect(site.sections[.one].items.count == 1)
        #expect(site.sections[.two].items.count == 1)
        #expect(site.sections[.three].items.count == 1)

        #expect(site.sections[.one].items.first?.title == "Mutated title")
        #expect(site.sections[.two].items.first?.title == "Mutated title")
        #expect(site.sections[.three].items.first?.title == "Mutated title")
    }

    @Test func testMutatingItemsInSection() throws {
        let site = try publishWebsite(using: [
            .addItem(.stub(withSectionID: .one)),
            .addItem(.stub(withSectionID: .two)),
            .addItem(.stub(withSectionID: .three)),
            .mutateAllItems(in: .one) { item in
                item.title = "Mutated title"
            }
        ])

        #expect(site.sections[.one].items.count == 1)
        #expect(site.sections[.two].items.count == 1)
        #expect(site.sections[.three].items.count == 1)

        #expect(site.sections[.one].items.first?.title == "Mutated title")
        #expect(site.sections[.two].items.first?.title == "")
        #expect(site.sections[.three].items.first?.title == "")
    }

    @Test func testMutatingItemsMatchingPredicate() throws {
        var items = [
            Item.stub(withPath: "a").setting(\.tags, to: ["one"]),
            Item.stub(withPath: "b").setting(\.tags, to: ["one", "two"])
        ]

        let site = try publishWebsite(using: [
            .addItems(in: items),
            .mutateAllItems(matching: \.tags ~= "one", using: { item in
                item.title += "One"
            }),
            .mutateAllItems(matching: \.tags ~= "two", using: { item in
                item.title += " Two"
            })
        ])

        items[0].title = "One"
        items[1].title = "One Two"

        #expect(Array(site.sections[.one].items) == items)
    }

    @Test func testMutatingItemsByChangingTags() throws {
        var items = [
            Item.stub(withPath: "a").setting(\.tags, to: ["first"]),
            Item.stub(withPath: "b").setting(\.tags, to: ["first"]),
            Item.stub(withPath: "c").setting(\.tags, to: ["first"])
        ]

        let allTags: Mutex<Set<Publish.Tag>?> = .init(nil)

        let site = try publishWebsite(using: [
            .addItems(in: items),
            .mutateAllItems(matching: \.path == "one/a") { item in
                item.tags.append("added")
            },
            .mutateAllItems(matching: \.path == "one/b") { item in
                item.tags = ["replaced"]
            },
            .mutateAllItems(matching: \.path == "one/c") { item in
                item.tags = []
            },
            .step(named: "custom") { context in
                allTags.withLock { $0 = context.allTags }
            }
        ])

        items[0].tags = ["first", "added"]
        items[1].tags = ["replaced"]
        items[2].tags = []

        #expect(site.sections[.one].items == items)
        let tags = allTags.withLock(\.self)
        #expect(tags == ["first", "added", "replaced"])
    }

    @Test func testMutatingItemsByRemovingTags() throws {
        let state = Mutex<(initialTags:Set<Publish.Tag>?, finalTags: Set<Publish.Tag>?)>.init((nil, nil))

        try publishWebsite(using: [
            .addItems(in: [
                Item.stub(withPath: "a").setting(\.tags, to: ["one"]),
                Item.stub(withPath: "b").setting(\.tags, to: ["two"]),
                Item.stub(withPath: "c").setting(\.tags, to: ["three"])
            ]),
            .step(named: "custom") { context in
                state.withLock { $0.initialTags = context.allTags }
            },
            .mutateAllItems { item in
                item.tags = []
            },
            .step(named: "custom") { context in
                state.withLock { $0.finalTags = context.allTags }
            }
        ])
        let initialTags = state.withLock(\.initialTags)
        #expect(initialTags == ["one", "two", "three"])
        let finalTags = state.withLock(\.finalTags)
        #expect(finalTags == [])
    }

    @Test func testSortingItems() throws {
        let items = [
            Item.stub(withPath: "a").setting(\.title, to: "A"),
            Item.stub(withPath: "b").setting(\.title, to: "B"),
            Item.stub(withPath: "c").setting(\.title, to: "C")
        ]

        let ascendingSite = try publishWebsite(using: [
            .addItems(in: items),
            .sortItems(by: \.title, order: .ascending)
        ])

        let descendingSite = try publishWebsite(using: [
            .addItems(in: items),
            .sortItems(by: \.title, order: .descending)
        ])

        #expect(ascendingSite.sections[.one].items == items)
        #expect(descendingSite.sections[.one].items == items.reversed())

        // Make sure path associations are still valid
        #expect(ascendingSite.sections[.one].item(at: "a") == items[0])
        #expect(ascendingSite.sections[.one].item(at: "b") == items[1])
        #expect(ascendingSite.sections[.one].item(at: "c") == items[2])

        #expect(descendingSite.sections[.one].item(at: "a") == items[0])
        #expect(descendingSite.sections[.one].item(at: "b") == items[1])
        #expect(descendingSite.sections[.one].item(at: "c") == items[2])
    }

    @Test func testSortingItemsInSection() throws {
        let items = [
            Item.stub(withSectionID: .one).setting(\.title, to: "A"),
            Item.stub(withSectionID: .one).setting(\.title, to: "B"),
            Item.stub(withSectionID: .two).setting(\.title, to: "A"),
            Item.stub(withSectionID: .two).setting(\.title, to: "B")
        ]

        let site = try publishWebsite(using: [
            .addItems(in: items),
            .sortItems(in: .one, by: \.title, order: .descending)
        ])

        #expect(site.sections[.one].items == items[0..<2].reversed())
        #expect(site.sections[.two].items == Array(items[2..<4]))
    }

    @Test func testMutatingItemUsingContentProxyProperties() throws {
        let audio = Audio(url: try require(URL(string: "audio.mp3")))

        let site = try publishWebsite(using: [
            .addItem(.stub(withPath: "item")),
            .mutateItem(at: "item", in: .one) { item in
                item.title = "Title"
                item.description = "Description"
                item.body = "<p>Body</p>"
                item.imagePath = "image.png"
                item.audio = audio
                item.video = .youTube(id: "123")
            }
        ])

        let item = try require(site.sections[.one].item(at: "item"))

        #expect(item.title == "Title")
        #expect(item.description == "Description")
        #expect(item.body == "<p>Body</p>")
        #expect(item.imagePath == "image.png")
        #expect(item.audio == audio)
        #expect(item.video == .youTube(id: "123"))
    }

    @Test func testMutatingPage() throws {
        let site = try publishWebsite(using: [
            .addPage(.stub(withPath: "a")),
            .mutatePage(at: "a", using: { page in
                page.title = "A: Mutated"
            })
        ])

        #expect(site.pages["a"]?.title == "A: Mutated")
    }

    @Test func testMutatingPageByChangingPath() throws {
        let site = try publishWebsite(using: [
            .addPage(.stub(withPath: "a")),
            .mutatePage(at: "a", using: { page in
                page.path = "b"
            })
        ])

        #expect(site.pages["a"] == nil)
        #expect(site.pages["b"] != nil)
    }

    @Test func testMutatingAllPagesMatchingPredicate() throws {
        let site = try publishWebsite(using: [
            .addPages(in: [
                .stub(withPath: "a"),
                .stub(withPath: "b")
            ]),
            .mutateAllPages(matching: \.path == "a") { page in
                page.title = "A: Mutated"
            }
        ])

        #expect(site.pages["a"]?.title == "A: Mutated")
        #expect(site.pages["b"]?.title == "")
    }
}
