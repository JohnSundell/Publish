/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Type representing one of a website's top sections, as defined by
/// its `SectionID` type. Each section can contain content of its own,
/// as well as a list of items. To modify a given section, access it
/// through the `sections` property on the current `PublishingContext`.
public struct Section<Site: Website>: Location {
    /// The section's ID, as defined by its `Website` implementation.
    public let id: Site.SectionID
    /// The items contained within the section.
    public private(set) var items = [Item<Site>]()
    /// The date of the last modified item within the section.
    public private(set) var lastItemModificationDate: Date?
    public var path: Path { Path(id.rawValue) }
    public var content = Content()

    internal var allTags: AnySequence<Tag> { .init(itemIndexesByTag.keys) }

    private var itemIndexesByPath = [Path : Int]()
    private var itemIndexesByTag = [Tag : Set<Int>]()

    internal init(id: Site.SectionID) {
        self.id = id
        self.title = id.rawValue.capitalized
    }
}

public extension Section {
    /// Retrieve an item that's located within a given path within the section.
    /// - parameter path: The relative path of the item to retrieve.
    func item(at path: Path) -> Item<Site>? {
        itemIndexesByPath[path].map { items[$0] }
    }

    /// Retrieve all of the section's items that are tagged with a given tag.
    /// - parameter tag: The tag to retrieve all items for.
    func items(taggedWith tag: Tag) -> [Item<Site>] {
        guard let indexes = itemIndexesByTag[tag] else {
            return []
        }

        return indexes.map { items[$0] }
    }

    /// Add an item to this section.
    /// - parameter path: The relative path to add an item at.
    /// - parameter metadata: The item's site-specific metadata.
    /// - parameter configure: A closure used to configure the new item.
    mutating func addItem(
        at path: Path,
        withMetadata metadata: Site.ItemMetadata,
        configure: (inout Item<Site>) throws -> Void
    ) rethrows {
        var item = Item<Site>(path: path, sectionID: id, metadata: metadata)
        try configure(&item)
        item.sectionID = id
        addItem(item)
    }

    /// Mutate one of the section's items.
    /// - parameter path: The path of the item to mutate.
    /// - parameter mutations: Closure containing the mutations to apply.
    /// - throws: An error if the item couldn't be found, or if the mutation failed.
    mutating func mutateItem(at path: Path,
                             using mutations: Mutations<Item<Site>>) throws {
        guard let index = itemIndexesByPath[path] else {
            throw ContentError(path: path, reason: .itemNotFound)
        }

        var item = items[index]
        try mutateItem(&item, at: index, using: mutations)
        items[index] = item
    }

    /// Mutate all of the section's items, optionally matching a given predicate.
    /// - Parameter predicate: Any predicate to filter the items based on.
    /// - Parameter mutations: Closure containing the mutations to apply.
    mutating func mutateItems(matching predicate: Predicate<Item<Site>> = .any,
                              using mutations: Mutations<Item<Site>>) rethrows {
        items = try items.map { item in
            guard predicate.matches(item) else {
                return item
            }

            var item = item
            let index = itemIndexesByPath[item.relativePath]!
            try mutateItem(&item, at: index, using: mutations)
            return item
        }
    }
    
    /// Remove all items within this section matching a given predicate.
    /// - Parameter predicate: Any predicate to filter the items based on.
    mutating func removeItems(matching predicate: Predicate<Item<Site>> = .any) {
        items.removeAll(where: predicate.matches)
        rebuildIndexes()
    }

    /// Sort all items within this section using a closure.
    /// - Parameter sorter: The closure to use to sort the items.
    mutating func sortItems(by sorter: (Item<Site>, Item<Site>) throws -> Bool) rethrows {
        try items.sort(by: sorter)
        rebuildIndexes()
    }
}

internal extension Section {
    mutating func addItem(_ item: Item<Site>) {
        let index = items.count
        itemIndexesByPath[item.relativePath] = index

        for tag in item.tags {
            itemIndexesByTag[tag, default: []].insert(index)
        }

        updateLastItemModificationDateIfNeeded(to: item.date)
        items.append(item)
    }
}

private extension Section {
    mutating func mutateItem(
        _ item: inout Item<Site>,
        at index: Int,
        using mutations: Mutations<Item<Site>>
    ) throws {
        do {
            let oldTags = Set(item.tags)
            try mutations(&item)
            item.sectionID = id
            let newTags = Set(item.tags)

            if oldTags != newTags {
                for tag in oldTags {
                    if !newTags.contains(tag), var indexes = itemIndexesByTag[tag] {
                        indexes.remove(index)
                        itemIndexesByTag[tag] = indexes.isEmpty ? nil : indexes
                    }
                }

                for tag in newTags {
                    if !oldTags.contains(tag) {
                        itemIndexesByTag[tag, default: []].insert(index)
                    }
                }
            }

            updateLastItemModificationDateIfNeeded(to: item.date)
        } catch {
            throw ContentError(
                path: item.path,
                reason: .itemMutationFailed(error)
            )
        }
    }

    mutating func updateLastItemModificationDateIfNeeded(to newDate: Date) {
        if let previous = lastItemModificationDate {
            guard newDate > previous else { return }
        }

        lastItemModificationDate = newDate
    }
    
    mutating func rebuildIndexes() {
        itemIndexesByPath = [:]
        itemIndexesByTag = [:]

        for (index, item) in items.enumerated() {
            itemIndexesByPath[item.relativePath] = index

            for tag in item.tags {
                itemIndexesByTag[tag, default: []].insert(index)
            }
        }
    }
}
