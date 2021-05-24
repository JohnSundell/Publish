/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Plot
import Ink

public extension EnvironmentKey where Value == MarkdownParser {
    /// Environment key that can be used to pass what `MarkdownParser` that
    /// should be used when rendering `Markdown` components.
    static var markdownParser: Self { .init(defaultValue: .init()) }
}
