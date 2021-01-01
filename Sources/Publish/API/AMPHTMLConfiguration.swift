/**
*  Publish
*  Copyright (c) John Sundell 2020
*  MIT license, see LICENSE file for details
*/

/// Configuration type used to customize how a website's
/// AMP pages gets rendered. To use a default implementation,
/// use `AMPHTMLConfiguration.default`.
public struct AMPHTMLConfiguration {
    /// The path that will be appended to a resources to obtain the path of the AMP version.
    public var suffixPath: Path

    /// Initialize a new configuration instance.
    /// - Parameter suffixPath: The path that will be appended to a resources to obtain the path of the AMP version.
    public init(
        suffixPath: Path = .defaultForAMPHTML
    ) {
        self.suffixPath = suffixPath
    }
}

public extension AMPHTMLConfiguration {
    /// Create a default AMP HTML configuration implementation.
    static var `default`: Self { .init() }
}
