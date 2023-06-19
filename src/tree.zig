const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

/// Generic k-ary tree represented as a "left-child right-sibling" binary tree.
pub fn Tree(comptime T: type) type {
    return struct {
        const Self = @This();
        root: Node,

        /// Node inside the tree.
        pub const Node = struct {
            value: T,
            parent: ?*Node,
            leftmost_child: ?*Node,
            right_sibling: ?*Node,
            depth: u32,

            fn init(value: T) Node {
                return Node {
                    .value = value,
                    .parent = null,
                    .leftmost_child = null,
                    .right_sibling = null,
                    .depth = 0,
                };
            }
        };

        /// Initialize a tree.
        ///
        /// Arguments:
        ///     value: Value (aka weight, key, etc.) of the root node.
        ///
        /// Returns:
        ///     A tree containing one node with specified value.
        pub fn init(value: T) Self {
            return Self{
                .root = Node.init(value),
            };
        }

        /// Allocate a new node. Caller owns returned Node and must free with `destroyNode`.
        ///
        /// Arguments:
        ///     allocator: Dynamic memory allocator.
        ///
        /// Returns:
        ///     A pointer to the new node.
        ///
        /// Errors:
        ///     If a new node cannot be allocated.
        pub fn allocateNode(tree: *Self, allocator: *const Allocator) !*Node {
            // Supress error
            _ = tree;
            
            return allocator.create(Node);
        }

        /// Deallocate a node. Node must have been allocated with `allocator`.
        ///
        /// Arguments:
        ///     node: Pointer to the node to deallocate.
        ///     allocator: Dynamic memory allocator.
        pub fn destroyNode(tree: *Self, node: *Node, allocator: *const Allocator) void {
            assert(tree.containsNode(node));
            allocator.destroy(node);
        }

        /// Allocate and initialize a node and its value.
        ///
        /// Arguments:
        ///     value: Value (aka weight, key, etc.) of newly created node.
        ///     allocator: Dynamic memory allocator.
        ///
        /// Returns:
        ///     A pointer to the new node.
        ///
        /// Errors:
        ///     If a new node cannot be allocated.
        pub fn createNode(tree: *Self, value: T, allocator: *const Allocator) !*Node {
            var node = try tree.allocateNode(allocator);
            node.* = Node.init(value);
            return node;
        }

        /// Insert a node at the specified position inside the tree.
        ///
        /// Arguments:
        ///     node: Pointer to the node to insert.
        ///     parent: Pointer to node which the newly created node will be a child of.
        ///
        /// Returns:
        ///     A pointer to the new node.
        pub fn insert(tree: *Self, node: *Node, parent: *Node) void {
            // Supress error
            _ = tree;

            node.parent = parent;
            node.depth = parent.depth + 1;

            if (parent.leftmost_child == null) {
                parent.leftmost_child = node;
            }
            else {
                var ptr = &parent.leftmost_child;
                while (ptr.*) |sibling| : (ptr = &sibling.right_sibling) {
                    if (sibling.right_sibling == null) {
                        sibling.right_sibling = node;
                        break;
                    }
                }
            }
        }

        /// Iterator that performs a depth-first post-order traversal of the tree.
        /// It is non-recursive and uses constant memory (no allocator needed).
        pub const DepthFirstIterator = struct {
            const State = enum {
                GoDeeper,
                GoBroader,
            };
            tree: *Self,
            current: ?*Node,
            state: State,

            // NB:
            // If not children_done:
            //      Go as deep as possible
            // Yield node
            // If can move right:
            //      children_done = false;
            //      Move right
            // Else:
            //      children_done = true;
            //      Move up

            pub fn init(tree: *Self) DepthFirstIterator {
                return DepthFirstIterator{
                    .tree = tree,
                    .current = &tree.root,
                    .state = State.GoDeeper,
                };
            }

            pub fn next(it: *DepthFirstIterator) ?*Node {
                // State machine
                while (it.current) |current| {
                    switch (it.state) {
                        State.GoDeeper => {
                            // Follow child node until deepest possible level
                            if (current.leftmost_child) |child| {
                                defer it.current = child;
                                return it.current;
                            } else {
                                it.state = State.GoBroader;
                                return current;
                            }
                        },
                        State.GoBroader => {
                            if (current.right_sibling) |sibling| {
                                it.current = sibling;
                                it.state = State.GoDeeper;
                            } else {
                                it.current = current.parent;
                                continue;
                            }
                        },
                    }
                }
                return null;
            }

            pub fn reset(it: *DepthFirstIterator) void {
                it.current = it.tree.root;
            }
        };

        /// Get a depth-first iterator over the nodes of this tree.
        ///
        /// Returns:
        ///     An iterator struct (one containing `next` and `reset` member functions).
        pub fn depthFirstIterator(tree: *Self) DepthFirstIterator {
            return DepthFirstIterator.init(tree);
        }

        /// Check if a node is contained in this tree.
        ///
        /// Arguments:
        ///     target: Pointer to node to be searched for.
        ///
        /// Returns:
        ///     A bool telling whether it has been found.
        pub fn containsNode(tree: *Self, target: *Node) bool {
            var iter = tree.depthFirstIterator();
            while (iter.next()) |node| {
                if (node == target) {
                    return true;
                }
            }
            return false;
        }
    };
}
