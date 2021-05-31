/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Plot


/// A node with context `Node<HTML.HeadContext>`, will be added only when certain condition is satisfied.
private struct ConditionalHeadNode {
    
    fileprivate typealias Condition = (Location) -> Bool
    
    /// The description of target website to add the node to.
    private var target: String
    
    /// When the condition returns true, the node will be added.
    fileprivate var condition: Condition
    
    /// Node to add.
    fileprivate var node: Node<HTML.HeadContext>
    
    /// Add nodes.
    private static var all: [ConditionalHeadNode] = []
    
    /// Add a new head node with condition to website.
    /// - Parameters:
    ///   - node: The head node to add.
    ///   - condition: Condition of the node.
    ///   - site: Website to add.
    fileprivate static func add<Site: Website>(node: Node<HTML.HeadContext>, when condition: @escaping Condition, for site: Site) {
        self.all.append(ConditionalHeadNode(target: String(describing: site.self), condition: condition, node: node))
    }
    
    
    /// Get head nodes for a website.
    /// - Parameter site: The website that nodes belong to.
    fileprivate static func headNodes<Site: Website>(for site: Site) -> [ConditionalHeadNode] {
        self.all.filter { (conditionalHeadNode) -> Bool in
            String(describing: site.self) == String(describing: conditionalHeadNode.target)
        }
    }
}

public extension Website {
    
    /// Add a global head node to the website
    /// - Parameters:
    ///   - headNode: The head node to add.
    ///   - condition: When condition returns true, the node is added.
    func add(headNode: Node<HTML.HeadContext>, when condition: @escaping (Location) -> Bool = {_ in true}) {
        ConditionalHeadNode.add(node: headNode, when: condition, for: self)
    }
    
    /// Get head nodes for a location of a website.
    /// - Parameter location: The location of the page.
    func headNodes(for location: Location) -> [Node<HTML.HeadContext>] {
        ConditionalHeadNode.headNodes(for: self).filter { (conditionalNode) -> Bool in
            conditionalNode.condition(location)
        }.map { (conditionalNode) -> Node<HTML.HeadContext> in
            conditionalNode.node
        }
    }
}
