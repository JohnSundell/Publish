//
//  AnyDateFormatter.swift
//  
//
//  Created by Dustin Pfannenstiel on 3/10/20.
//  Copyright (c) Dustin Pfannenstiel, 2020
//  MIT license, see LICENSE file for details
//

import Foundation

public protocol AnyDateFormatter: Formatter {
    var timeZone: TimeZone! { get set }
    var dateFormat: String! { get set }

    func date(from string: String) -> Date?
    func string(from date: Date) -> String
}

extension DateFormatter: AnyDateFormatter {}

@available(OSX 10.12, *)
extension ISO8601DateFormatter: AnyDateFormatter {
    public var dateFormat: String! {
        get { "ISO8601DateFormatter" }
        set { print("Warning: May not set dateFormat for ISO8601DateFormatter") }
    }
}
