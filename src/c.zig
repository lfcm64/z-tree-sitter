const config = @import("config");

pub const tree_sitter = @cImport({
    @cInclude("tree_sitter/api.h");
});

pub const grammars = @cImport({
    if (config.bash) @cInclude("bash.h");
    if (config.c) @cInclude("c.h");
    if (config.css) @cInclude("css.h");
    if (config.cpp) @cInclude("cpp.h");
    if (config.c_sharp) @cInclude("c_sharp.h");
    if (config.elixir) @cInclude("elixir.h");
    if (config.elm) @cInclude("elm.h");
    if (config.erlang) @cInclude("erlang.h");
    if (config.fsharp) @cInclude("fsharp.h");
    if (config.go) @cInclude("go.h");
    if (config.haskell) @cInclude("haskell.h");
    if (config.java) @cInclude("java.h");
    if (config.javascript) @cInclude("javascript.h");
    if (config.json) @cInclude("json.h");
    if (config.julia) @cInclude("julia.h");
    if (config.kotlin) @cInclude("kotlin.h");
    if (config.lua) @cInclude("lua.h");
    if (config.markdown) @cInclude("markdown.h");
    if (config.nim) @cInclude("nim.h");
    if (config.ocaml) @cInclude("ocaml.h");
    if (config.perl) @cInclude("perl.h");
    if (config.php) @cInclude("php.h");
    if (config.python) @cInclude("python.h");
    if (config.ruby) @cInclude("ruby.h");
    if (config.rust) @cInclude("rust.h");
    if (config.scala) @cInclude("scala.h");
    if (config.toml) @cInclude("toml.h");
    if (config.typescript) @cInclude("typescript.h");
    if (config.zig) @cInclude("zig.h");
});
