const std = @import("std");
const ArrayList = std.ArrayList;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const Tree = @import("tree.zig").Tree;

const CODE =
    \\=(a 1)
    \\if( (a == 1.2) and (true == false) (
    \\  print("a is 1.2")
    \\))
;

const TokenType = enum {
    ROOT,

    LEFT_PAREN,
    RIGHT_PAREN,

    LABEL,
    INTEGER,
    FLOAT,
    STRING,

    ERROR,
};

const Token = struct {
    token_type: TokenType,
    slice: []const u8,
    line: u32,

    fn init(token_type: TokenType, slice: []const u8, line: u32) Token {
        return Token {
            .token_type = token_type,
            .slice = slice,
            .line = line,
        };
    }
};

pub fn main() !void {
    var line: u32 = 1;
    var tokens = ArrayList(Token).init(allocator);
    var tree = Tree(Token).init(Token.init(TokenType.ROOT, CODE[0..0], 0));
    var last_node = &tree.root;
    _ = last_node;
    
    var ptr: usize = 0;
    while (ptr < CODE.len) {
        while (true) {
            switch (CODE[ptr]) {
                ' ', '\t', '\r' => {
                    ptr += 1;
                },
                '\n' => {
                    line += 1;
                    ptr += 1;
                },
                else => {
                    break;
                },
            }
        }

        var length: usize = 0;
        defer ptr = ptr + length;

        while (ptr + length < CODE.len) : (length += 1) {
            switch (CODE[ptr + length]) {
                '(', ')' => {
                    if (length == 0) length = 1;
                    break;
                },
                ' ', '\t', '\r' => {
                    if (CODE[ptr] != '"' and CODE[ptr] != '\'') break;
                },
                '\n' => {
                    break;
                },
                else => {},
            }
        }

        if ((CODE[ptr] == '"' or CODE[ptr] == '\'' ) and
            CODE[ptr] != CODE[ptr + length - 1]) {
            std.debug.print("Error: expected end of string\n", .{});
            unreachable;
        }

        const token_type = switch (CODE[ptr]) {
            '(' => TokenType.LEFT_PAREN,
            ')' => TokenType.RIGHT_PAREN,
            '0'...'9' => blk: {
                var number_type = TokenType.INTEGER;

                var i: usize = ptr + 1;
                while (i < length) : (i += 1) {
                    switch (CODE[i]) {
                        '0'...'9' => {},
                        '.' => {
                            number_type = TokenType.FLOAT;
                        },
                        else => {
                            break :blk TokenType.ERROR;
                        },
                    }
                }

                break :blk number_type;
            },
            '"' => blk: {
                if ((CODE[ptr] == '"' or CODE[ptr] == '\'') and
                    CODE[ptr] == CODE[ptr + length - 1]) {
                    break :blk TokenType.STRING;
                }
                
                break :blk TokenType.ERROR;
            },
            else => TokenType.LABEL,
        };

        try tokens.append(
            Token.init(token_type, CODE[ptr..ptr+length], line)
        );
    }

    line = 1;
    var j: usize = 0;
    const items = tokens.items;
    var curr_parent = &tree.root;

    while (j < items.len) : (j += 1) {
        const node = try tree.createNode(items[j], &allocator);
        tree.insert(node, curr_parent);

        if (items[j].token_type == TokenType.LABEL and
            items[j+1].token_type == TokenType.LEFT_PAREN) {
            curr_parent = node;
        }
        
        if (items[j].token_type == TokenType.RIGHT_PAREN) {
            curr_parent = node.*.parent.?;
        }
    }

    std.debug.print("\n\n", .{});

    var iter = tree.depthFirstIterator();
    _ = iter.next(); // Skip the root

    while (iter.next()) |node| {
        var i: u32 = 1;
        while (i < node.depth) : (i += 1) std.debug.print("\t", .{});
        std.debug.print("{s}: {}\n", .{node.value.slice, node.value.token_type});
    }
}
