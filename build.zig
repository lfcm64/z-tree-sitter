const std = @import("std");
const builtin = @import("builtin");

const Build = std.Build;
const Step = std.Build.Step;

const eql = std.mem.eql;

const allocator = std.heap.page_allocator;

const Grammar = struct {
    name: []const u8,
    root: []const u8 = "src",
    scanner: bool = true,
};

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const grammar_map = try createGrammarInstallMap();

    const zts = b.addModule("zts", .{
        .root_source_file = b.path("src/treesitter.zig"),
    });

    const config = b.addOptions();

    const all_opt = b.option(
        bool,
        "all",
        "include all builtin grammars in z-tree-sitter",
    ) orelse shouldInstallAllGrammar();

    config.addOption(bool, "all", all_opt);

    //Grammars options
    for (grammars) |g| {
        const grammar_opt = b.option(
            bool,
            g.name,
            "include grammar in z-tree-sitter",
        ) orelse all_opt or grammar_map.contains(g.name);

        if (grammar_opt) {
            const grammar_build = try buildLanguageGrammar(b, target, optimize, g);
            b.installArtifact(grammar_build);
            zts.linkLibrary(grammar_build);
        }

        config.addOption(bool, g.name, grammar_opt);
    }
    zts.addOptions("config", config);

    const dep = b.dependency("tree_sitter_api", .{});
    const c_tree_sitter = buildTreeSitterApi(b, target, optimize, dep);
    b.installArtifact(c_tree_sitter);
    zts.linkLibrary(c_tree_sitter);

    zts.addIncludePath(dep.path(""));

    //Tests
    const test_step = b.step("test", "Run treesitter tests");

    const tree_sitter_test = b.addTest(.{
        .root_source_file = b.path("tests/treesitter.zig"),
        .target = target,
        .optimize = optimize,
    });
    tree_sitter_test.root_module.addImport("zts", zts);

    const grammars_test = b.addTest(.{
        .root_source_file = b.path("tests/grammars.zig"),
        .target = target,
        .optimize = optimize,
    });
    grammars_test.root_module.addImport("zts", zts);

    const run_tree_sitter_test = b.addRunArtifact(tree_sitter_test);
    test_step.dependOn(&run_tree_sitter_test.step);

    const run_grammars_test = b.addRunArtifact(grammars_test);
    test_step.dependOn(&run_grammars_test.step);

    //Examples
    for (examples) |example| {
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = b.path(example.path),
            .target = target,
            .optimize = optimize,
        });

        exe.root_module.addImport("zts", zts);

        const artifact = b.addInstallArtifact(exe, .{});
        const exe_step = b.step(b.fmt("install-example-{s}", .{example.name}), b.fmt("Install {s} example", .{example.name}));
        exe_step.dependOn(&artifact.step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| run_cmd.addArgs(args);

        const run_step = b.step(b.fmt("example-{s}", .{example.name}), b.fmt("Run {s} example", .{example.name}));
        run_step.dependOn(&run_cmd.step);
    }
}

fn buildTreeSitterApi(b: *Build, target: Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, dep: *Build.Dependency) *Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "tree_sitter",
        .root_source_file = b.path("src/treesitter.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.addCSourceFiles(.{
        .root = dep.path(""),
        .files = &.{"lib/src/lib.c"},
        .flags = &.{"-std=c11"},
    });

    lib.addIncludePath(dep.path("lib/include"));
    lib.addIncludePath(dep.path("lib/src"));
    lib.installHeadersDirectory(dep.path("lib/include"), ".", .{});
    return lib;
}

fn buildLanguageGrammar(
    b: *Build,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    g: Grammar,
) !*Step.Compile {
    const dep = b.dependency(g.name, .{
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = g.name,
        .root_source_file = b.path("src/treesitter.zig"),
        .target = target,
        .optimize = optimize,
    });

    const default_files = &.{ "parser.c", "scanner.c" };
    lib.addCSourceFiles(.{
        .root = dep.path(g.root),
        .files = if (g.scanner) default_files else &.{"parser.c"},
        .flags = &.{"-std=c11"},
    });
    lib.addIncludePath(dep.path(g.root));

    const path = try generateHeaderFile(b, g, dep);
    lib.installHeader(dep.path(path), path);

    return lib;
}

fn generateHeaderFile(b: *Build, g: Grammar, dep: *std.Build.Dependency) ![]const u8 {
    const path = dep.path("").getPath(b);
    const dir = try std.fs.openDirAbsolute(path, .{});

    const file_name = try std.fmt.allocPrint(allocator, "{s}.h", .{g.name});

    var buf: [32]u8 = undefined;
    const upper_name = std.ascii.upperString(&buf, file_name);

    const f = try dir.createFile(file_name, .{});
    defer f.close();

    const writer = f.writer();
    try writer.print(
        \\#ifndef TREE_SITTER_{s}_H_
        \\#define TREE_SITTER_{s}_H_
        \\typedef struct TSLanguage TSLanguage;
        \\#ifdef __cplusplus
        \\extern "C"
        \\{{
        \\#endif
        \\const TSLanguage *tree_sitter_{s}(void);
        \\#ifdef __cplusplus
        \\}}
        \\#endif
        \\#endif
    ,
        .{ upper_name, upper_name, g.name },
    );
    return file_name;
}

pub fn shouldInstallAllGrammar() bool {
    var isArg = false;

    var args = std.process.args();
    while (args.next()) |arg| {
        if (eql(u8, arg, "--")) isArg = true;
        if (isArg and eql(u8, arg, "--all-languages")) return true;
    }
    return false;
}

pub fn createGrammarInstallMap() !std.StringHashMap(bool) {
    var isArg = false;
    var isGrammar = false;

    var grammar_map = std.StringHashMap(bool).init(allocator);

    var args = std.process.args();
    while (args.next()) |arg| {
        if (isGrammar) {
            if (isSupportedGrammar(arg)) {
                if (grammar_map.contains(arg)) @panic("duplicate grammar found");
                try grammar_map.put(arg, true);
                continue;
            } else if (arg[0] == '-') break else @panic("incorrect grammar found");
        }

        if (eql(u8, arg, "--")) isArg = true;
        if (isArg and eql(u8, arg, "--language")) isGrammar = true;
    }
    return grammar_map;
}

fn isSupportedGrammar(name: []const u8) bool {
    for (grammars) |g| {
        if (eql(u8, g.name, name)) return true;
    }
    return false;
}

const examples = [_]struct { name: []const u8, path: []const u8 }{
    .{ .name = "parse-input", .path = "examples/parse-input.zig" },
};

const grammars = [_]Grammar{
    .{ .name = "bash" },
    .{ .name = "c", .scanner = false },
    .{ .name = "css" },
    .{ .name = "cpp" },
    .{ .name = "c_sharp" },
    .{ .name = "elixir" },
    .{ .name = "elm" },
    .{ .name = "erlang", .scanner = false },
    .{ .name = "fsharp", .root = "fsharp/src" },
    .{ .name = "go", .scanner = false },
    .{ .name = "haskell" },
    .{ .name = "java", .scanner = false },
    .{ .name = "javascript" },
    .{ .name = "json", .scanner = false },
    .{ .name = "julia" },
    .{ .name = "kotlin" },
    .{ .name = "lua" },
    .{ .name = "markdown", .root = "tree-sitter-markdown/src" },
    .{ .name = "nim" },
    .{ .name = "ocaml", .root = "grammars/ocaml/src" },
    .{ .name = "perl" },
    .{ .name = "php", .root = "php/src" },
    .{ .name = "python" },
    .{ .name = "ruby" },
    .{ .name = "rust" },
    .{ .name = "scala" },
    .{ .name = "toml" },
    .{ .name = "typescript", .root = "typescript/src" },
    .{ .name = "zig", .scanner = false },
};
