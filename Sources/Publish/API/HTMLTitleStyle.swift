//
//  HTMLTitleStyle.swift
//  
//
//  Created by Ben Syverson on 2020/01/28.
//

import Foundation
import Plot

/// Enum defining the method used to generate HTML title
public enum HTMLTitleStyle {
    /// Use `Location.title` on its own (e.g.
    /// `<title>About Us</title>`)
    case locationTitle

    /// Use `Location.title` and `Site.name` separated
    /// by a supplied string (e.g.
    /// `<title>About Us | Swifters</title>`)
    case titleAndSiteName(separator: String)

    /// Use a custom fixed string
    case fixed(string: String)
}

/// Return the resolved title for a `Location` in a `Website` using
/// the chosen title style
/// - Parameter location: The location to title
/// - Parameter site: The location's site
internal extension HTMLTitleStyle {
    func title<T: Website>(for location: Location, in site: T) -> String {
        switch self {
           case .fixed(string: let fixed):
               return fixed
           case .locationTitle:
               return location.title
            case .titleAndSiteName(separator: let separator):
                guard !location.title.isEmpty else {
                    return site.name
                }
                return location.title.appending(separator + site.name)
        }
    }
}
