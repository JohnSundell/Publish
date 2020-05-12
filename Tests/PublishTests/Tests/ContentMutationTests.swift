/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class ContentMutationTests: PublishTestCase {
    func testAddingItemUsingClosureAPI() throws {
        let site = try publishWebsite(using: [
            .step(named: "Custom") { context in
                context.sections[.one].addItem(at: "path", withMetadata: .init()) { item in
                    item.title = "Hello, world!"
                }
            }
        ])

        XCTAssertEqual(site.sections[.one].items.count, 1)
        XCTAssertEqual(site.sections[.one].items.first?.title, "Hello, world!")
    }

    func testAddingItemUsingPlotHierarchy() throws {
        let site = try publishWebsite(using: [
            .addItem(Item.stub().setting(\.body,
                to: Content.Body(node: .div("Plot!"))
            ))
        ])

        XCTAssertEqual(site.sections[.one].items.count, 1)
        XCTAssertEqual(site.sections[.one].items.first?.body.html, "<div>Plot!</div>")
    }

    func testRemovingItemsMatchingPredicate() throws {
        let items = [
            Item.stub(withPath: "a").setting(\.tags, to: ["one"]),
            Item.stub(withPath: "b").setting(\.tags, to: ["one", "two"])
        ]

        let site = try publishWebsite(using: [
            .addItems(in: items),
            .removeAllItems(matching: \.tags ~= "two")
        ])

        XCTAssertEqual(site.sections[.one].items, [items[0]])
        XCTAssertNil(site.sections[.one].item(at: "b"), "Item indexes not updated")
    }

    func testMutatingAllSections() throws {
        let site = try publishWebsite(using: [
            .step(named: "Set section titles") { context in
                context.mutateAllSections { section in
                    section.title = section.id.rawValue
                }
            }
        ])

        XCTAssertEqual(site.sections[.one].title, "one")
        XCTAssertEqual(site.sections[.two].title, "two")
        XCTAssertEqual(site.sections[.three].title, "three")
    }

    func testMutatingAllItems() throws {
        let site = try publishWebsite(using: [
            .addItem(.stub(withSectionID: .one)),
            .addItem(.stub(withSectionID: .two)),
            .addItem(.stub(withSectionID: .three)),
            .mutateAllItems { item in
                item.title = "Mutated title"
            }
        ])

        XCTAssertEqual(site.sections[.one].items.count, 1)
        XCTAssertEqual(site.sections[.two].items.count, 1)
        XCTAssertEqual(site.sections[.three].items.count, 1)

        XCTAssertEqual(site.sections[.one].items.first?.title, "Mutated title")
        XCTAssertEqual(site.sections[.two].items.first?.title, "Mutated title")
        XCTAssertEqual(site.sections[.three].items.first?.title, "Mutated title")
    }

    func testMutatingItemsInSection() throws {
        let site = try publishWebsite(using: [
            .addItem(.stub(withSectionID: .one)),
            .addItem(.stub(withSectionID: .two)),
            .addItem(.stub(withSectionID: .three)),
            .mutateAllItems(in: .one) { item in
                item.title = "Mutated title"
            }
        ])

        XCTAssertEqual(site.sections[.one].items.count, 1)
        XCTAssertEqual(site.sections[.two].items.count, 1)
        XCTAssertEqual(site.sections[.three].items.count, 1)

        XCTAssertEqual(site.sections[.one].items.first?.title, "Mutated title")
        XCTAssertEqual(site.sections[.two].items.first?.title, "")
        XCTAssertEqual(site.sections[.three].items.first?.title, "")
    }

    func testMutatingItemsMatchingPredicate() throws {
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

        XCTAssertEqual(Array(site.sections[.one].items), items)
    }

    func testMutatingItemsByChangingTags() throws {
        var items = [
            Item.stub(withPath: "a").setting(\.tags, to: ["first"]),
            Item.stub(withPath: "b").setting(\.tags, to: ["first"]),
            Item.stub(withPath: "c").setting(\.tags, to: ["first"])
        ]

        var allTags: Set<Tag>?

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
                allTags = context.allTags
            }
        ])

        items[0].tags = ["first", "added"]
        items[1].tags = ["replaced"]
        items[2].tags = []

        XCTAssertEqual(site.sections[.one].items, items)
        XCTAssertEqual(allTags, ["first", "added", "replaced"])
    }

    func testMutatingItemsByRemovingTags() throws {
        var initialTags: Set<Tag>?
        var finalTags: Set<Tag>?

        try publishWebsite(using: [
            .addItems(in: [
                Item.stub(withPath: "a").setting(\.tags, to: ["one"]),
                Item.stub(withPath: "b").setting(\.tags, to: ["two"]),
                Item.stub(withPath: "c").setting(\.tags, to: ["three"])
            ]),
            .step(named: "custom") { context in
                initialTags = context.allTags
            },
            .mutateAllItems { item in
                item.tags = []
            },
            .step(named: "custom") { context in
                finalTags = context.allTags
            }
        ])

        XCTAssertEqual(initialTags, ["one", "two", "three"])
        XCTAssertEqual(finalTags, [])
    }

    func testSortingItems() throws {
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

        XCTAssertEqual(ascendingSite.sections[.one].items, items)
        XCTAssertEqual(descendingSite.sections[.one].items, items.reversed())

        // Make sure path associations are still valid
        XCTAssertEqual(ascendingSite.sections[.one].item(at: "a"), items[0])
        XCTAssertEqual(ascendingSite.sections[.one].item(at: "b"), items[1])
        XCTAssertEqual(ascendingSite.sections[.one].item(at: "c"), items[2])

        XCTAssertEqual(descendingSite.sections[.one].item(at: "a"), items[0])
        XCTAssertEqual(descendingSite.sections[.one].item(at: "b"), items[1])
        XCTAssertEqual(descendingSite.sections[.one].item(at: "c"), items[2])
    }

    func testSortingItemsInSection() throws {
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

        XCTAssertEqual(site.sections[.one].items, items[0..<2].reversed())
        XCTAssertEqual(site.sections[.two].items, Array(items[2..<4]))
    }

    func testMutatingItemUsingContentProxyProperties() throws {
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

        XCTAssertEqual(item.title, "Title")
        XCTAssertEqual(item.description, "Description")
        XCTAssertEqual(item.body, "<p>Body</p>")
        XCTAssertEqual(item.imagePath, "image.png")
        XCTAssertEqual(item.audio, audio)
        XCTAssertEqual(item.video, .youTube(id: "123"))
    }

    func testMutatingPage() throws {
        let site = try publishWebsite(using: [
            .addPage(.stub(withPath: "a")),
            .mutatePage(at: "a", using: { page in
                page.title = "A: Mutated"
            })
        ])

        XCTAssertEqual(site.pages["a"]?.title, "A: Mutated")
    }

    func testMutatingPageByChangingPath() throws {
        let site = try publishWebsite(using: [
            .addPage(.stub(withPath: "a")),
            .mutatePage(at: "a", using: { page in
                page.path = "b"
            })
        ])

        XCTAssertNil(site.pages["a"])
        XCTAssertNotNil(site.pages["b"])
    }

    func testMutatingAllPagesMatchingPredicate() throws {
        let site = try publishWebsite(using: [
            .addPages(in: [
                .stub(withPath: "a"),
                .stub(withPath: "b")
            ]),
            .mutateAllPages(matching: \.path == "a") { page in
                page.title = "A: Mutated"
            }
        ])

        XCTAssertEqual(site.pages["a"]?.title, "A: Mutated")
        XCTAssertEqual(site.pages["b"]?.title, "")
    }
}

extension ContentMutationTests {
    static var allTests: Linux.TestList<ContentMutationTests> {
        [
            ("testAddingItemUsingClosureAPI", testAddingItemUsingClosureAPI),
            ("testAddingItemUsingPlotHierarchy", testAddingItemUsingPlotHierarchy),
            ("testRemovingItemsMatchingPredicate", testRemovingItemsMatchingPredicate),
            ("testMutatingAllSections", testMutatingAllSections),
            ("testMutatingAllItems", testMutatingAllItems),
            ("testMutatingItemsInSection", testMutatingItemsInSection),
            ("testMutatingItemsMatchingPredicate", testMutatingItemsMatchingPredicate),
            ("testMutatingItemsByChangingTags", testMutatingItemsByChangingTags),
            ("testMutatingItemsByRemovingTags", testMutatingItemsByRemovingTags),
            ("testSortingItems", testSortingItems),
            ("testSortingItemsInSection", testSortingItemsInSection),
            ("testMutatingItemUsingContentProxyProperties", testMutatingItemUsingContentProxyProperties),
            ("testMutatingPage", testMutatingPage),
            ("testMutatingPageByChangingPath", testMutatingPageByChangingPath),
            ("testMutatingAllPagesMatchingPredicate", testMutatingAllPagesMatchingPredicate)
        ]
    }
}
