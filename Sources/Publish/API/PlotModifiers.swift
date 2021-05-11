import Ink
import Plot

public extension Component {
    /// Assign what `MarkdownParser` to use when rendering `Markdown` components
    /// within this component hierarchy. This value is placed in the environment,
    /// and is thus inherited by all child components. Note that this modifier
    /// does not affect nodes rendered using the `.markdown` API.
    /// - parameter parser: The parser to assign.
    func markdownParser(_ parser: MarkdownParser) -> Component {
        environmentValue(parser, key: .markdownParser)
    }
}
