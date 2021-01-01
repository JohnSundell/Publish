/**
*  Publish
*  Copyright (c) John Sundell 2020
*  MIT license, see LICENSE file for details
*/

/// Configuration type used to customize which and where
/// AMP pages are generated. To use a default implementation,
/// use `AMPHTMLConfiguration.default`.
public struct AMPHTMLConfiguration {
    /// A closure that given a location, provides the path to the AMP version of that location.
    ///
    /// You can filter over the type of location (or a specific location) to return `nil`, which means that no AMP
    /// version of that location is generated.
    public var pathForLocation: (Location) -> Path?
    
    /// Initialize a new configuration instance.
    /// - Parameter pathForLocation: A closure that given a location, provides the path to the AMP version of that location.
    public init(
        pathForLocation: @escaping (Location) -> Path? = { location in
            return Path("\(location.path)/\(Path.defaultForAMPHTML).html")
        }
    ) {
        self.pathForLocation = pathForLocation
    }
}

public extension AMPHTMLConfiguration {
    /// Create a default AMP HTML configuration implementation.
    static var `default`: Self { .init() }
}
