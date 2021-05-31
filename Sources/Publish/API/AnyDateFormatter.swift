//
//  AnyDateFormatter.swift
//  
//
//  Created by Dustin Pfannenstiel on 3/10/20.
//  Copyright (c) Dustin Pfannenstiel, 2020
//  MIT license, see LICENSE file for details
//

import Foundation

/// A common interface to abstract common methods and properties present
/// in all date formatter types.
public protocol AnyDateFormatter: Formatter {
    /// The time zone for the receiver.
    var timeZone: TimeZone! { get set }
    /// The date format string used by the receiver.
    var dateFormat: String! { get }

    /// Returns a date representation of a given string interpreted using the receiver’s current settings.
    /// - parameter string: The string to parse.
    func date(from string: String) -> Date?
    /// Returns a string representation of a given date formatted using the receiver’s current settings.
    /// - parameter date: The date to format.
    func string(from date: Date) -> String
}

/// Apply `AnyDateFormatter` to `DateFormatter`
extension DateFormatter: AnyDateFormatter {}

/// Apply `AnyDateFormatter` to `ISO8601DateFormatter`
@available(OSX 10.12, *)
extension ISO8601DateFormatter: AnyDateFormatter {
    /// Since `ISO8601DateFormatter` does not have a variable format, return a descriptive string for reporting.
    public var dateFormat: String! {
        get { "ISO8601DateFormatter" }
    }
}
