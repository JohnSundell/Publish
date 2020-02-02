//
//  File.swift
//  
//
//  Created by Dorian Grolaux on 02/02/2020.
//

import Foundation

internal extension Array {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
