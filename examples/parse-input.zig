// Requires the Zig grammar to be installed

const std = @import("std");
const zts = @import("zts");

const Parser = zts.Parser;

var stdin = std.io.getStdIn().reader();
var stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const p = try Parser.init();
    defer p.deinit();

    const zig = try zts.langFromGrammar(.zig);
    try p.setLanguage(zig);

    _ = try stdout.write("Enter a Zig expression to parse:\n");

    const input_text = try stdin.readUntilDelimiterAlloc(std.heap.page_allocator, '\n', 256);
    defer std.heap.page_allocator.free(input_text);

    const text = std.mem.trimRight(u8, input_text, "\r");

    const tree = try p.parseString(null, text);
    const root = tree.rootNode();

    try stdout.print("Parsing result:\n{s}\n", .{root.toString()});
}
