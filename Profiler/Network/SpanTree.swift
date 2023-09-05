// Copyright 2023 Yuri6037
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy
// of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS
// IN THE SOFTWARE.

import Foundation

class Span {
    let name: String
    let id: UInt32
    private var children: [Span] = []

    init(name: String, id: UInt32) {
        self.name = name
        self.id = id
    }

    /// Attempts to find the parent of the specified node.
    func findParent(_ id: UInt32) -> UInt32? {
        for v in children {
            if v.id == id {
                return self.id
            }
            if let id = v.findParent(id) {
                return id
            }
        }
        return nil
    }

    private func findNode(_ id: UInt32) -> Int? {
        for (k, v) in children.enumerated() {
            if v.id == id {
                return k
            }
        }
        return nil
    }

    /// Attempts to remove the specified node.
    ///
    /// If the node wasn't found, None is returned.
    /// If the node was found and removed, the removed node is returned.
    func removeNode(_ id: UInt32) -> Span? {
        if let index = findNode(id) {
            return children.remove(at: index)
        }
        for v in children {
            if let node = v.removeNode(id) {
                return node
            }
        }
        return nil
    }

    /// Inserts a new child node to this node.
    func addNode(_ node: Span) {
        children.append(node)
    }

    /// Attempts to add the specified node under the specified parent.
    ///
    /// If the parent could not be found the node is returned.
    /// If the parent was found and the node added None is returned.
    func addNode(_ node: Span, parent: UInt32) -> Span? {
        if id == parent {
            addNode(node)
            return nil
        }
        var node = node
        for v in children {
            if let v = v.addNode(node, parent: parent) {
                node = v
            } else {
                return nil
            }
        }
        return node
    }
}

class SpanTree {
    let root = Span(name: "/", id: 0)
    private var nodeMap: [UInt32: Span] = [:]
    private var nodeParent: [UInt32: UInt32] = [:]

    /// Inserts a new child node to this node.
    func addNode(_ node: Span) {
        root.addNode(node)
        nodeMap[node.id] = node
    }

    /// Attempts to relocated the specified node under the new specified parent.
    ///
    /// Returns true if the operation has succeeded.
    func relocateNode(_ id: UInt32, newParent: UInt32) -> Bool {
        // If the node's parent is already set and the parent has not changed, no need to set it again.
        if nodeParent[id] == newParent {
            return false
        }
        if let node = root.removeNode(id) {
            if root.addNode(node, parent: newParent) == nil {
                nodeParent[id] = newParent
                return true
            }
        }
        return false
    }

    func getPath(_ id: UInt32) -> String {
        var id = id
        var components: [String] = []
        let path = nodeMap[id]?.name ?? ""
        components.append(path)
        while let component = root.findParent(id) {
            if let node = nodeMap[component] {
                components.append(node.name)
            } else {
                components.append("")
            }
            id = component
        }
        components.reverse()
        return components.joined(separator: "/")
    }
}
