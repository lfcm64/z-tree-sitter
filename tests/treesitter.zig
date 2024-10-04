const std = @import("std");
const zts = @import("zts");

const Parser = zts.Parser;
const Point = zts.Point;
const TreeCursor = zts.TreeCursor;
const Query = zts.Query;
const QueryCursor = zts.QueryCursor;
const LookaheadIterator = zts.LookaheadIterator;

const loadLanguage = zts.loadLanguage;

test "parser" {
    const p = try Parser.init();
    defer p.deinit();

    const zig = try loadLanguage(.zig);

    _ = p.getLanguage();
    try p.setLanguage(zig);

    const sp = Point{ .column = 0, .row = 0 };
    const ep = Point{ .column = 1, .row = 1 };

    const ranges = [_]zts.Range{
        .{ .start_point = sp, .end_point = ep, .start_byte = 0, .end_byte = 0 },
    };
    var count: u32 = 0;
    try p.setIncludedRanges(&ranges, 1);
    _ = p.getIncludedRanges(&count);

    const text = "const Foo = 0;";

    //const input: zts.Input = undefined;
    //_ = try p.parse(null, input);
    _ = try p.parseString(null, text);
    _ = try p.parseStringEncoding(null, text, .utf16);

    p.reset();

    p.setTimeoutMicros(0);
    _ = p.getTimeoutMicros();

    var flag: u64 = 0;
    p.setCancellationFlag(&flag);
    _ = p.getCancellationFlag();

    p.setLogger(undefined);
    _ = p.getLogger();

    p.printDotGraphs(0);
}

test "tree" {
    const p = try Parser.init();
    defer p.deinit();

    const zig = try loadLanguage(.zig);

    try p.setLanguage(zig);

    const text = "const Foo = 0;";

    const tree = try p.parseString(null, text);
    defer tree.deinit();

    const tree_copy = try tree.copy();

    _ = tree.rootNode();

    const oe = Point{ .column = 0, .row = 0 };
    _ = tree.rootNodeWithOffset(0, oe);

    _ = tree.getLanguage();

    var length: u32 = 0;
    _ = tree.getIncludedRanges(&length);

    const ie: zts.InputEdit = undefined;
    tree.edit(&ie);

    _ = tree.getChangedRanges(tree_copy, &length);

    //tree.printDotGraph(0);
}

test "language" {
    const lang = try loadLanguage(.zig);
    defer lang.deinit();

    _ = try lang.copy();

    _ = lang.getSymbolCount();
    _ = lang.getStateCount();
    _ = lang.getSymbolName(1);
    _ = lang.getSymbolForName("if", 2, true);
    _ = lang.getFieldCount();
    _ = lang.getFieldNameForId(1);
    _ = lang.getFieldIdForName("if", 2);
    _ = lang.getSymbolType(1);
    _ = lang.getVersion();
    _ = lang.getNextState(1, 1);
}

test "node" {
    const text = "const Foo  = 0;";
    const p = try Parser.init();
    defer p.deinit();

    const zig = try loadLanguage(.zig);
    defer zig.deinit();

    try p.setLanguage(zig);

    const tree = try p.parseString(null, text);
    const node = tree.rootNode();

    _ = node.getType();
    _ = node.getSymbol();
    _ = node.getLanguage();
    _ = node.getGrammarType();
    _ = node.getGrammarSymbol();
    _ = node.getStartByte();
    _ = node.getStartPoint();
    _ = node.getEndByte();
    _ = node.getEndPoint();
    _ = node.toString();
    _ = node.isNull();
    _ = node.isNamed();
    _ = node.isMissing();
    _ = node.isExtra();
    _ = node.hasChanges();
    _ = node.hasError();
    _ = node.isError();
    _ = node.getParseState();
    _ = node.getNextParseState();
    _ = node.getParent();

    if (node.getChild(0)) |child| {
        _ = node.childContainingDescendant(child);
    }

    _ = node.getFieldNameForChild(0);
    _ = node.getChildCount();
    _ = node.getNamedChild(0);
    _ = node.getNamedChildCount();
    _ = node.getChildByFieldName("foo", 3);
    _ = node.getNextSibling();
    _ = node.getPrevSibling();
    _ = node.getDescendantCount();
    _ = node.getDescendantForByteRange(0, text.len);

    var edit_input = [_]zts.InputEdit{.{
        .start_byte = 6,
        .old_end_byte = 9,
        .new_end_byte = 10,
        .start_point = Point{ .row = 0, .column = 6 },
        .old_end_point = Point{ .row = 0, .column = 9 },
        .new_end_point = Point{ .row = 0, .column = 10 },
    }};
    var nodes = [_]zts.Node{node};
    zts.editNodes(&nodes, &edit_input);

    _ = node.eq(node);
}

test "tree cursor" {
    const text = "const Foo = 0;";
    const p = try Parser.init();
    defer p.deinit();

    const zig = try loadLanguage(.zig);
    defer zig.deinit();

    try p.setLanguage(zig);

    const tree = try p.parseString(null, text);
    const root_node = tree.rootNode();

    var cursor = TreeCursor.init(root_node);
    defer cursor.deinit();

    _ = cursor.currentNode();
    _ = cursor.currentFieldName();
    _ = cursor.currentFieldId();
    _ = cursor.gotoParent();
    _ = cursor.gotoNextSibling();
    _ = cursor.gotoPreviousSibling();
    _ = cursor.gotoFirstChild();
    _ = cursor.gotoLastChild();
    cursor.gotoDescendant(0);
    _ = cursor.currentDescendantIndex();
    _ = cursor.currentDepth();
    _ = cursor.gotoFirstChildForByte(5);
    _ = cursor.gotoFirstChildForPoint(Point{ .row = 0, .column = 6 });

    var copied_cursor = cursor.copy();
    defer copied_cursor.deinit();

    cursor.reset(root_node);
    cursor.resetTo(&copied_cursor);
}

test "query and query cursor" {
    const text = "const Foo = 0;";
    const p = try Parser.init();
    defer p.deinit();

    const zig = try loadLanguage(.zig);
    defer zig.deinit();

    try p.setLanguage(zig);

    const tree = try p.parseString(null, text);
    const node = tree.rootNode();

    const query_source = "";

    var query = try Query.init(zig, query_source);
    defer query.deinit();

    _ = query.patternCount();
    _ = query.captureCount();
    _ = query.stringCount();
    _ = query.startByteForPattern(0);
    _ = query.endByteForPattern(0);

    var step_count: u32 = 0;
    _ = query.predicatesForPattern(1, &step_count);
    _ = query.isPatternRooted(0);
    _ = query.isPatternNonLocal(0);
    _ = query.isPatternGuaranteedAtStep(0);

    var length: u32 = 0;
    _ = query.captureNameForId(0, &length);
    _ = query.captureQuantifierForId(0, 1);
    _ = query.stringValueForId(0, &length);

    query.disableCapture("name");
    query.disablePattern(0);

    var cursor = try QueryCursor.init();
    defer cursor.deinit();
    cursor.exec(query, node);
    _ = cursor.didExceedMatchLimit();
    _ = cursor.matchLimit();
    cursor.setMatchLimit(1000);
    cursor.setByteRange(0, text.len);
    cursor.setPointRange(Point{ .row = 0, .column = 0 }, Point{ .row = 1, .column = 0 });

    var match: zts.QueryMatch = undefined;
    _ = cursor.nextMatch(&match);

    cursor.removeMatch(0);
    var capture_index: u32 = 0;
    _ = cursor.nextCapture(&match, &capture_index);

    cursor.setMaxStartDepth(5);
}

test "lookahead iterator" {
    const lang = try loadLanguage(.zig);
    defer lang.deinit();

    const state = 1;
    const iterator = try LookaheadIterator.init(lang, state);
    defer iterator.deinit();

    _ = try iterator.resetState(2);
    _ = try iterator.reset(lang, 3);
    _ = iterator.getLanguage();
    _ = iterator.next();
    _ = iterator.currentSymbol();
    _ = iterator.currentSymbolName();
}
