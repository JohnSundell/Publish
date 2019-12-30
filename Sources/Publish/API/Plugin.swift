/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

/// Type used to implement Publish plugins, that can be used to customize
/// the publising process in any way.
public struct Plugin<Site: Website> {
    /// Closure type used to install a plugin within the current context.
    public typealias Installer = PublishingStep<Site>.Closure

    /// The human-readable name of the plugin.
    public var name: String
    /// The closure used to install the plugin within the current context.
    public var installer: Installer

    /// Initialize a new plugin instance.
    /// - Parameter name: The human-readable name of the plugin.
    /// - Parameter installer: The closure used to install the plugin.
    public init(name: String, installer: @escaping Installer) {
        self.name = name
        self.installer = installer
    }
}
