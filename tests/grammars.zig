const std = @import("std");
const zts = @import("zts");

const Parser = zts.Parser;

test "grammars" {
    const p = try Parser.init();
    defer p.deinit();

    inline for (std.meta.fields(zts.LanguageGrammar)) |lang| {
        const zig = try zts.loadLanguage(@enumFromInt(lang.value));
        defer zig.deinit();
    }
}
