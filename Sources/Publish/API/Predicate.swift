/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Type used to implement predicates that can be used to filter and
/// conditionally select items when mutating them.
public struct Predicate<Target>: Sendable {
    internal let matches: @Sendable (Target) -> Bool

    /// Initialize a new predicate instance using a given matching closure.
    /// You can also create predicates based on operators and key paths.
    /// - parameter matcher: The matching closure to use.
    public init(matcher: @escaping @Sendable (Target) -> Bool) {
        matches = matcher
    }
}

public extension Predicate {
    /// Create a predicate that matches any candidate.
    static var any: Self { Predicate { _ in true } }

    /// Create an inverse of this predicate - that is one that matches
    /// all candidates that this predicate does not, and vice versa.
    func inverse() -> Self {
        Predicate { !self.matches($0) }
    }
}

public typealias _SendableKeyPath<Root, Value> = any KeyPath<Root, Value> & Sendable

/// Create a predicate for comparing a key path against a value.
/// Usage example: `\.path == "somePath"`.
public func ==<T, V: Equatable & Sendable>(lhs: _SendableKeyPath<T, V>, rhs: V) -> Predicate<T> {
    Predicate { $0[keyPath: lhs] == rhs }
}

/// Create a predicate for checking whether an element is contained
/// within a collection-based key path's value.
/// Usage example: `\.tags ~= "someTag"`.
public func ~=<T, V: Collection>(
    lhs: _SendableKeyPath<T, V>,
    rhs: V.Element
) -> Predicate<T> where V.Element: Equatable & Sendable {
    Predicate { $0[keyPath: lhs].contains(rhs) }
}

/// Create a predicate that matches against `false` values for a given
/// `Bool` key path.
/// Usage example: `!\.isExplicit`
public prefix func !<T>(rhs: _SendableKeyPath<T, Bool>) -> Predicate<T> {
    rhs == false
}

/// Create a predicate that matches when a key path's value is
/// higher than a given value.
/// Usage example: `\.metadata.intValue > 3`.
public func ><T, V: Comparable & Sendable>(lhs: _SendableKeyPath<T, V>, rhs: V) -> Predicate<T> {
    Predicate { $0[keyPath: lhs] > rhs }
}

/// Create a predicate that matches when a key path's value is
/// lower than a given value.
/// Usage example: `\.metadata.intValue < 3`.
public func <<T, V: Comparable & Sendable>(lhs: _SendableKeyPath<T, V>, rhs: V) -> Predicate<T> {
    Predicate { $0[keyPath: lhs] < rhs }
}

/// Combine two predicates into one. Both of the underlying predicates
/// have to match for the new predicate to match.
public func &&<T>(lhs: Predicate<T>, rhs: Predicate<T>) -> Predicate<T> {
    Predicate { lhs.matches($0) && rhs.matches($0) }
}

/// Combine two predicates into one. Either of the underlying predicates
/// has to match for the new predicate to match.
public func ||<T>(lhs: Predicate<T>, rhs: Predicate<T>) -> Predicate<T> {
    Predicate { lhs.matches($0) || rhs.matches($0) }
}
