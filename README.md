# z-tree-sitter 🌳

A Zig package that provides a complete wrapper around [tree-sitter API](https://tree-sitter.github.io/tree-sitter/), along with built-in support for well-known languages grammar (see [supported languages grammar](#supported-languages-grammar)). The current version of z-tree-sitter supports tree-sitter 0.23.0.

## Documentation
You can find documentation directly from the [tree-sitter API header](https://github.com/tree-sitter/tree-sitter/blob/master/lib/include/tree_sitter/api.h) or on the [tree-sitter website](https://tree-sitter.github.io/tree-sitter/).

All wrapper functions and types are demonstrated in the [tests file](https://github.com/lfcm64/z-tree-sitter/tree/main/tests), where you can see Zig equivalents of the C tree-sitter API.

* Run tests with `zig build test -- --all-language`
* Run an example with `zig build example-<name> -- --language zig`

Example code is included in the [examples](https://github.com/lfcm64/z-tree-sitter/tree/main/examples) directory.

The --all-languages argument includes all built-in language grammars in z-tree-sitter, which is necessary for running tests.

The --language argument installs only the language grammar specified after it (usefull for running examples).

## Install z-tree-sitter in your project

To integrate z-tree-sitter into your project, you can either find the appropriate version archive in this github repo, or simply run: `zig fetch --save git+https://github.com/lfcm64/z-tree-sitter` to add the most recent commit of ziglua to your `build.zig.zon` file.

Then in your `build.zig` file you can use the dependency:

```zig
pub fn build(b: *std.Build) void {
    // ... snip ...

    const zts = b.dependency("zts", .{
        .target = target,
        .optimize = optimize,
    });

    // ... snip ...

    // add the z-tree-sitter module
    exe.root_module.addImport("zts", zts.module("zts"));
}
```
This will compile the C tree-sitter library and link it with your project.

## Install tree-sitter grammars in your project

To compile and use tree-sitter grammar with z-tree-sitter, pass the relevant options in the `b.dependency()` call in your `build.zig` file.

For example, here is a `b.dependency()` call that links erlang and javascript grammar to z-tree-sitter:

```zig
const zts = b.dependency("zts", .{
    .target = target,
    .optimize = optimize,
    .erlang = true,
    .javascript = true,
});
```

You can then load and use the imported grammar languages by calling `zts.loadLanguage()`, see this [example](https://github.com/lfcm64/z-tree-sitter/blob/main/examples/parse-input.zig) for more details.

### Supported languages Grammar
Here is a list of all available languages grammar:

- [x] [bash](https://github.com/tree-sitter/tree-sitter-bash)
- [x] [c](https://github.com/tree-sitter/tree-sitter-c)
- [x] [css](https://github.com/tree-sitter/tree-sitter-css)
- [x] [cpp](https://github.com/tree-sitter/tree-sitter-cpp)
- [x] [c-sharp](https://github.com/tree-sitter/tree-sitter-c-sharp)
- [x] [elixir](https://github.com/elixir-lang/tree-sitter-elixir)
- [x] [elm](https://github.com/elm-tooling/tree-sitter-elm)
- [x] [erlang](https://github.com/WhatsApp/tree-sitter-erlang)
- [x] [fsharp](https://github.com/ionide/tree-sitter-fsharp)
- [x] [go](https://github.com/tree-sitter/tree-sitter-go)
- [x] [haskell](https://github.com/tree-sitter/tree-sitter-haskell)
- [x] [java](https://github.com/tree-sitter/tree-sitter-java)
- [x] [javascript](https://github.com/tree-sitter/tree-sitter-javascript)
- [x] [json](https://github.com/tree-sitter/tree-sitter-json)
- [x] [julia](https://github.com/tree-sitter/tree-sitter-julia)
- [x] [kotlin](https://github.com/fwcd/tree-sitter-kotlin)
- [x] [lua](https://github.com/tree-sitter-grammars/tree-sitter-lua)
- [x] [markdown](https://github.com/tree-sitter-grammars/tree-sitter-markdown)
- [x] [nim](https://github.com/alaviss/tree-sitter-nim)
- [x] [ocaml](https://github.com/tree-sitter/tree-sitter-ocaml)
- [x] [perl](https://github.com/ganezdragon/tree-sitter-perl)
- [x] [php](https://github.com/tree-sitter/tree-sitter-php)
- [x] [python](https://github.com/tree-sitter/tree-sitter-python)
- [x] [ruby](https://github.com/tree-sitter/tree-sitter-ruby)
- [x] [rust](https://github.com/tree-sitter/tree-sitter-rust)
- [x] [scala](https://github.com/tree-sitter/tree-sitter-scala)
- [x] [toml](https://github.com/tree-sitter-grammars/tree-sitter-toml)
- [x] [typescript](https://github.com/tree-sitter/tree-sitter-typescript)
- [x] [zig](https://github.com/tree-sitter-grammars/tree-sitter-zig)