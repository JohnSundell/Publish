/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

/// Enum describing various orders that can be used when
/// performing sorting operations.
public enum SortOrder: Sendable {
    /// Sort the collection in ascending order.
    case ascending
    /// Sort the collection in descending order.
    case descending
}

internal extension SortOrder {
    func makeSorter<T, V: Comparable>(
        forKeyPath keyPath: _SendableKeyPath<T, V>
    ) -> @Sendable (T, T) -> Bool {
        switch self {
        case .ascending:
            return {
                $0[keyPath: keyPath] < $1[keyPath: keyPath]
            }
        case .descending:
            return {
                $0[keyPath: keyPath] > $1[keyPath: keyPath]
            }
        }
    }
}
