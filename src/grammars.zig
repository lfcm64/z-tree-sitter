const std = @import("std");
const config = @import("config");

const Language = @import("treesitter.zig").Language;
const grammars = @import("c.zig").grammars;

pub const LanguageGrammar = enum {
    bash,
    c,
    css,
    cpp,
    c_sharp,
    elixir,
    elm,
    erlang,
    fsharp,
    go,
    haskell,
    java,
    javascript,
    json,
    julia,
    kotlin,
    lua,
    markdown,
    nim,
    ocaml,
    perl,
    php,
    python,
    ruby,
    rust,
    scala,
    toml,
    typescript,
    zig,
};

pub inline fn loadLanguage(lg: LanguageGrammar) !*const Language {
    const name = @tagName(lg);
    if (!@field(config, name)) return error.FetchingGrammarFail;

    const c_func = @field(grammars, "tree_sitter_" ++ name);
    return if (c_func()) |lang| @ptrCast(lang) else error.InvalidLang;
}
