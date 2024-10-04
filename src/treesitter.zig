const std = @import("std");
const tree_sitter = @import("c.zig").tree_sitter;

pub const TREE_SITTER_LANGUAGE_VERSION: u32 = 14;

pub const TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION: u32 = 13;

pub const FieldId = u16;
pub const Symbol = u16;
pub const StateId = u16;

pub const Language = opaque {
    const Self = @This();

    pub fn copy(language: *const Self) !*const Self {
        if (tree_sitter.ts_language_copy(@ptrCast(language))) |lang| {
            return @ptrCast(lang);
        } else return error.LanguageCopyFail;
    }

    pub fn deinit(language: *const Self) void {
        tree_sitter.ts_language_delete(@ptrCast(language));
    }

    pub fn getSymbolCount(language: *const Self) u32 {
        return tree_sitter.ts_language_symbol_count(@ptrCast(language));
    }

    pub fn getStateCount(language: *const Self) u32 {
        return tree_sitter.ts_language_state_count(@ptrCast(language));
    }

    pub fn getSymbolName(language: *const Self, symbol: Symbol) []const u8 {
        return std.mem.span(tree_sitter.ts_language_symbol_name(@ptrCast(language), symbol));
    }

    pub fn getSymbolForName(language: *const Self, string: []const u8, length: usize, is_named: bool) Symbol {
        return tree_sitter.ts_language_symbol_for_name(@ptrCast(language), @ptrCast(string), @intCast(length), is_named);
    }

    pub fn getFieldCount(language: *const Self) u32 {
        return tree_sitter.ts_language_field_count(@ptrCast(language));
    }

    pub fn getFieldNameForId(language: *const Self, id: FieldId) []const u8 {
        return std.mem.span(tree_sitter.ts_language_field_name_for_id(@ptrCast(language), id));
    }

    pub fn getFieldIdForName(language: *const Self, name: []const u8, name_length: u32) FieldId {
        return tree_sitter.ts_language_field_id_for_name(@ptrCast(language), @ptrCast(name), name_length);
    }

    pub fn getSymbolType(language: *const Self, symbol: Symbol) SymbolType {
        return @enumFromInt(tree_sitter.ts_language_symbol_type(@ptrCast(language), symbol));
    }

    pub fn getVersion(language: *const Self) u32 {
        return tree_sitter.ts_language_version(@ptrCast(language));
    }

    pub fn getNextState(language: *const Self, state: StateId, symbol: Symbol) StateId {
        return tree_sitter.ts_language_next_state(@ptrCast(language), state, symbol);
    }
};

pub const Parser = opaque {
    const Self = @This();

    pub fn init() !*Self {
        if (tree_sitter.ts_parser_new()) |parser| {
            return @ptrCast(parser);
        } else return error.ParserInitFail;
    }

    pub fn deinit(self: *Self) void {
        tree_sitter.ts_parser_delete(@ptrCast(self));
    }

    pub fn getLanguage(self: *Self) ?*const Language {
        if (tree_sitter.ts_parser_language(@ptrCast(self))) |lang| {
            return @ptrCast(lang);
        } else return null;
    }

    pub fn setLanguage(self: *Self, language: *const Language) !void {
        if (!tree_sitter.ts_parser_set_language(@ptrCast(self), @ptrCast(language))) {
            return error.LanguageSetFail;
        }
    }

    pub fn setIncludedRanges(self: *Self, ranges: []const Range, count: u32) !void {
        if (!tree_sitter.ts_parser_set_included_ranges(@ptrCast(self), @ptrCast(ranges), count)) {
            return error.InvalidIncludedRanges;
        }
    }

    pub fn getIncludedRanges(self: *Self, count: *u32) ?[*]const Range {
        return @ptrCast(tree_sitter.ts_parser_included_ranges(@ptrCast(self), @ptrCast(count)));
    }

    pub fn parse(self: *Self, old_tree: ?*const Tree, input: Input) !*Tree {
        if (tree_sitter.ts_parser_parse(@ptrCast(self), @ptrCast(old_tree), @bitCast(input))) |tree| {
            return @ptrCast(tree);
        } else return error.ParseFail;
    }

    pub fn parseString(self: *Self, old_tree: ?*const Tree, string: []const u8) !*Tree {
        if (tree_sitter.ts_parser_parse_string(
            @ptrCast(self),
            @ptrCast(old_tree),
            @ptrCast(string),
            @intCast(string.len),
        )) |tree| {
            return @ptrCast(tree);
        } else return error.ParseStringFail;
    }

    pub fn parseStringEncoding(self: *Self, old_tree: ?*const Tree, string: []const u8, encoding: InputEncoding) !*Tree {
        if (tree_sitter.ts_parser_parse_string_encoding(
            @ptrCast(self),
            @ptrCast(old_tree),
            @ptrCast(string),
            @intCast(string.len),
            @intFromEnum(encoding),
        )) |tree| {
            return @ptrCast(tree);
        } else return error.EncodingParseFail;
    }

    pub fn reset(self: *Self) void {
        tree_sitter.ts_parser_reset(@ptrCast(self));
    }

    pub fn setTimeoutMicros(self: *Self, timeout_micros: u64) void {
        tree_sitter.ts_parser_set_timeout_micros(@ptrCast(self), timeout_micros);
    }

    pub fn getTimeoutMicros(self: *Self) u64 {
        return tree_sitter.ts_parser_timeout_micros(@ptrCast(self));
    }

    pub fn setCancellationFlag(self: *Self, flag: *u64) void {
        tree_sitter.ts_parser_set_cancellation_flag(@ptrCast(self), @ptrCast(flag));
    }

    pub fn getCancellationFlag(self: *const Self) *u64 {
        return @constCast(tree_sitter.ts_parser_cancellation_flag(@ptrCast(self)));
    }

    pub fn setLogger(self: *Self, logger: Logger) void {
        tree_sitter.ts_parser_set_logger(@ptrCast(self), @bitCast(logger));
    }

    pub fn getLogger(self: *Self) Logger {
        return @bitCast(tree_sitter.ts_parser_logger(@ptrCast(self)));
    }

    pub fn printDotGraphs(self: *Self, fd: u32) void {
        tree_sitter.ts_parser_print_dot_graphs(@ptrCast(self), @intCast(fd));
    }
};

pub const Tree = opaque {
    const Self = @This();

    pub fn copy(tree: *Self) !*const Self {
        if (tree_sitter.ts_tree_copy(@ptrCast(tree))) |copied_tree| {
            return @ptrCast(copied_tree);
        } else return error.TreeCopyFail;
    }

    pub fn deinit(tree: *Self) void {
        tree_sitter.ts_tree_delete(@ptrCast(tree));
    }

    pub fn rootNode(tree: *Self) Node {
        return @bitCast(tree_sitter.ts_tree_root_node(@ptrCast(tree)));
    }

    pub fn rootNodeWithOffset(tree: *Self, offset_bytes: u32, offset_extent: Point) Node {
        return @bitCast(tree_sitter.ts_tree_root_node_with_offset(@ptrCast(tree), offset_bytes, @bitCast(offset_extent)));
    }

    pub fn getLanguage(tree: *Self) ?*const Language {
        if (tree_sitter.ts_tree_language(@ptrCast(tree))) |lang| {
            return @ptrCast(lang);
        } else return null;
    }

    pub fn getIncludedRanges(tree: *Self, length: *u32) ?[*]Range {
        return @ptrCast(tree_sitter.ts_tree_included_ranges(@ptrCast(tree), length));
    }

    pub fn edit(tree: *Self, input_edit: *const InputEdit) void {
        tree_sitter.ts_tree_edit(@ptrCast(tree), @ptrCast(input_edit));
    }

    pub fn getChangedRanges(old_tree: *Self, new_tree: *const Tree, length: *u32) ?[*]Range {
        return @ptrCast(tree_sitter.ts_tree_get_changed_ranges(@ptrCast(old_tree), @ptrCast(new_tree), length));
    }

    pub fn printDotGraph(tree: *Self, fd: u32) void {
        tree_sitter.ts_tree_print_dot_graph(@ptrCast(tree), @intCast(fd));
    }
};

pub const Query = opaque {
    const Self = @This();

    pub fn init(language: *const Language, source: []const u8) !*Self {
        var error_type: c_uint = 0;
        if (tree_sitter.ts_query_new(@ptrCast(language), @ptrCast(source), @intCast(source.len), 0, &error_type)) |query| {
            return switch (error_type) {
                0 => @ptrCast(query),
                1 => QueryError.syntaxError,
                2 => QueryError.nodeTypeError,
                3 => QueryError.fieldError,
                4 => QueryError.captureError,
                5 => QueryError.structureError,
                6 => QueryError.languageError,
                else => @panic("query error code not recognized"),
            };
        } else return error.QueryInitFail;
    }

    pub fn deinit(self: *Self) void {
        tree_sitter.ts_query_delete(@ptrCast(self));
    }

    pub fn patternCount(self: *const Self) u32 {
        return tree_sitter.ts_query_pattern_count(@ptrCast(self));
    }

    pub fn captureCount(self: *const Self) u32 {
        return tree_sitter.ts_query_capture_count(@ptrCast(self));
    }

    pub fn stringCount(self: *const Self) u32 {
        return tree_sitter.ts_query_string_count(@ptrCast(self));
    }

    pub fn startByteForPattern(self: *const Self, pattern_index: u32) ?u32 {
        if (self.patternCount() == 0) return null;
        return tree_sitter.ts_query_start_byte_for_pattern(@ptrCast(self), pattern_index);
    }

    pub fn endByteForPattern(self: *const Self, pattern_index: u32) ?u32 {
        if (self.patternCount() == 0) return null;
        return tree_sitter.ts_query_end_byte_for_pattern(@ptrCast(self), pattern_index);
    }

    pub fn predicatesForPattern(self: *const Self, pattern_index: u32, step_count: *u32) ?*const QueryPredicateStep {
        if (self.patternCount() == 0) return null;
        if (tree_sitter.ts_query_predicates_for_pattern(@ptrCast(self), pattern_index, step_count)) |step| {
            return @ptrCast(step);
        } else return null;
    }

    pub fn isPatternRooted(self: *const Self, pattern_index: u32) bool {
        return tree_sitter.ts_query_is_pattern_rooted(@ptrCast(self), pattern_index);
    }

    pub fn isPatternNonLocal(self: *const Self, pattern_index: u32) bool {
        return tree_sitter.ts_query_is_pattern_non_local(@ptrCast(self), pattern_index);
    }

    pub fn isPatternGuaranteedAtStep(self: *const Self, byte_offset: u32) bool {
        return tree_sitter.ts_query_is_pattern_guaranteed_at_step(@ptrCast(self), byte_offset);
    }

    pub fn captureNameForId(self: *const Self, index: u32, length: *u32) ?[]const u8 {
        if (self.captureCount() == 0) return null;
        return std.mem.span(tree_sitter.ts_query_capture_name_for_id(@ptrCast(self), index, length));
    }

    pub fn captureQuantifierForId(self: *const Self, pattern_index: u32, capture_index: u32) ?Quantifier {
        if (self.captureCount() == 0) return null;
        return @enumFromInt(tree_sitter.ts_query_capture_quantifier_for_id(@ptrCast(self), pattern_index, capture_index));
    }

    pub fn stringValueForId(self: *const Self, index: u32, length: *u32) ?[]const u8 {
        if (self.stringCount() == 0) return null;
        return std.mem.span(tree_sitter.ts_query_string_value_for_id(@ptrCast(self), index, length));
    }

    pub fn disableCapture(self: *Self, name: []const u8) void {
        tree_sitter.ts_query_disable_capture(@ptrCast(self), @ptrCast(name), @intCast(name.len));
    }

    pub fn disablePattern(self: *Self, pattern_index: u32) void {
        tree_sitter.ts_query_disable_pattern(@ptrCast(self), pattern_index);
    }
};

pub const QueryCursor = opaque {
    const Self = @This();

    pub fn init() !*Self {
        if (tree_sitter.ts_query_cursor_new()) |qc| {
            return @ptrCast(qc);
        } else return error.QueryCursorInitError;
    }

    pub fn deinit(self: *Self) void {
        tree_sitter.ts_query_cursor_delete(@ptrCast(self));
    }

    pub fn exec(self: *Self, query: *const Query, node: Node) void {
        tree_sitter.ts_query_cursor_exec(@ptrCast(self), @ptrCast(query), @bitCast(node));
    }

    pub fn didExceedMatchLimit(self: *const Self) bool {
        return tree_sitter.ts_query_cursor_did_exceed_match_limit(@ptrCast(self));
    }

    pub fn matchLimit(self: *const Self) u32 {
        return tree_sitter.ts_query_cursor_match_limit(@ptrCast(self));
    }

    pub fn setMatchLimit(self: *Self, limit: u32) void {
        tree_sitter.ts_query_cursor_set_match_limit(@ptrCast(self), limit);
    }

    pub fn setByteRange(self: *Self, start_byte: u32, end_byte: u32) void {
        tree_sitter.ts_query_cursor_set_byte_range(@ptrCast(self), start_byte, end_byte);
    }

    pub fn setPointRange(self: *Self, start_point: Point, end_point: Point) void {
        tree_sitter.ts_query_cursor_set_point_range(@ptrCast(self), @bitCast(start_point), @bitCast(end_point));
    }

    pub fn nextMatch(self: *Self, match: *QueryMatch) bool {
        return tree_sitter.ts_query_cursor_next_match(@ptrCast(self), @ptrCast(match));
    }

    pub fn removeMatch(self: *Self, match_id: u32) void {
        tree_sitter.ts_query_cursor_remove_match(@ptrCast(self), match_id);
    }

    pub fn nextCapture(self: *Self, match: *QueryMatch, capture_index: *u32) bool {
        return tree_sitter.ts_query_cursor_next_capture(@ptrCast(self), @ptrCast(match), @ptrCast(capture_index));
    }

    pub fn setMaxStartDepth(self: *Self, max_start_depth: u32) void {
        tree_sitter.ts_query_cursor_set_max_start_depth(@ptrCast(self), max_start_depth);
    }
};

pub const LookaheadIterator = opaque {
    const Self = @This();

    pub fn init(lang: *const Language, state: StateId) !*Self {
        if (tree_sitter.ts_lookahead_iterator_new(@ptrCast(lang), state)) |iterator| {
            return @ptrCast(iterator);
        } else return error.IteratorInitError;
    }

    pub fn deinit(self: *Self) void {
        tree_sitter.ts_lookahead_iterator_delete(@ptrCast(self));
    }

    pub fn resetState(self: *Self, state: StateId) !void {
        if (!tree_sitter.ts_lookahead_iterator_reset_state(@ptrCast(self), state)) {
            return error.ResetIteratorStateFail;
        }
    }

    pub fn reset(self: *Self, lang: *const Language, state: StateId) !void {
        if (!tree_sitter.ts_lookahead_iterator_reset(@ptrCast(self), @ptrCast(lang), state)) {
            return error.ResetIteratorFail;
        }
    }

    pub fn getLanguage(self: *Self) ?*const Language {
        if (tree_sitter.ts_lookahead_iterator_language(@ptrCast(self))) |lang| {
            return @ptrCast(lang);
        } else return null;
    }

    pub fn next(self: *Self) bool {
        return tree_sitter.ts_lookahead_iterator_next(@ptrCast(self));
    }

    pub fn currentSymbol(self: *Self) Symbol {
        return tree_sitter.ts_lookahead_iterator_current_symbol(@ptrCast(self));
    }

    pub fn currentSymbolName(self: *Self) ?[]const u8 {
        if (tree_sitter.ts_lookahead_iterator_current_symbol_name(@ptrCast(self))) |name| {
            return std.mem.span(name);
        } else return null;
    }
};

pub const InputEncoding = enum(u8) {
    utf8,
    utf16,
};

pub const SymbolType = enum(u8) {
    regular,
    anonymous,
    auxiliary,
};

pub const Point = extern struct {
    row: u32,
    column: u32,
};

pub const Range = extern struct {
    start_point: Point,
    end_point: Point,
    start_byte: u32,
    end_byte: u32,
};

pub const Input = extern struct {
    payload: *anyopaque,
    read: *const fn (*anyopaque, u32, Point, *u32) callconv(.C) [*]const u8,
    encoding: InputEncoding,
};

pub const LogType = enum(u8) {
    parse,
    lex,
};

pub const Logger = extern struct {
    payload: *anyopaque,
    log: *const fn (*anyopaque, LogType, [*:0]const u8) callconv(.C) void,
};

pub const InputEdit = extern struct {
    start_byte: u32,
    old_end_byte: u32,
    new_end_byte: u32,
    start_point: Point,
    old_end_point: Point,
    new_end_point: Point,
};

pub const Node = extern struct {
    context: [4]u32,
    id: *const anyopaque,
    tree: *const Tree,

    const Self = @This();

    pub fn getType(self: Self) []const u8 {
        return std.mem.span(tree_sitter.ts_node_type(@bitCast(self)));
    }

    pub fn getSymbol(self: Self) Symbol {
        return tree_sitter.ts_node_symbol(@bitCast(self));
    }

    pub fn getLanguage(self: Self) ?*const Language {
        if (tree_sitter.ts_node_language(@bitCast(self))) |lang| {
            return @ptrCast(lang);
        } else return null;
    }

    pub fn getGrammarType(self: Self) []const u8 {
        return std.mem.span(tree_sitter.ts_node_grammar_type(@bitCast(self)));
    }

    pub fn getGrammarSymbol(self: Self) Symbol {
        return tree_sitter.ts_node_grammar_symbol(@bitCast(self));
    }

    pub fn getStartByte(self: Self) u32 {
        return tree_sitter.ts_node_start_byte(@bitCast(self));
    }

    pub fn getStartPoint(self: Self) Point {
        return @bitCast(tree_sitter.ts_node_start_point(@bitCast(self)));
    }

    pub fn getEndByte(self: Self) u32 {
        return tree_sitter.ts_node_end_byte(@bitCast(self));
    }

    pub fn getEndPoint(self: Self) Point {
        return @bitCast(tree_sitter.ts_node_end_point(@bitCast(self)));
    }

    pub fn toString(self: Self) []const u8 {
        return std.mem.span((tree_sitter.ts_node_string(@bitCast(self))));
    }

    pub fn isNull(self: Self) bool {
        return tree_sitter.ts_node_is_null(@bitCast(self));
    }

    pub fn isNamed(self: Self) bool {
        return tree_sitter.ts_node_is_named(@bitCast(self));
    }

    pub fn isMissing(self: Self) bool {
        return tree_sitter.ts_node_is_missing(@bitCast(self));
    }

    pub fn isExtra(self: Self) bool {
        return tree_sitter.ts_node_is_extra(@bitCast(self));
    }

    pub fn hasChanges(self: Self) bool {
        return tree_sitter.ts_node_has_changes(@bitCast(self));
    }

    pub fn hasError(self: Self) bool {
        return tree_sitter.ts_node_has_error(@bitCast(self));
    }

    pub fn isError(self: Self) bool {
        return tree_sitter.ts_node_is_error(@bitCast(self));
    }

    pub fn getParseState(self: Self) StateId {
        return tree_sitter.ts_node_parse_state(@bitCast(self));
    }

    pub fn getNextParseState(self: Self) StateId {
        return tree_sitter.ts_node_next_parse_state(@bitCast(self));
    }

    pub fn getParent(self: Self) ?Self {
        const parent: Node = @bitCast(tree_sitter.ts_node_parent(@bitCast(self)));
        return if (parent.isNull()) null else parent;
    }

    pub fn childContainingDescendant(self: Self, descendant: Self) ?Self {
        const child: Node = @bitCast(tree_sitter.ts_node_child_containing_descendant(@bitCast(self), @bitCast(descendant)));
        return if (child.isNull()) null else child;
    }

    pub fn getChild(self: Self, child_index: u32) ?Self {
        const child: Node = @bitCast(tree_sitter.ts_node_child(@bitCast(self), child_index));
        return if (child.isNull()) null else child;
    }

    pub fn getFieldNameForChild(self: Self, child_index: u32) ?[]const u8 {
        if (tree_sitter.ts_node_field_name_for_child(@bitCast(self), child_index)) |field| {
            return std.mem.span(field);
        } else return null;
    }

    pub fn getChildCount(self: Self) u32 {
        return tree_sitter.ts_node_child_count(@bitCast(self));
    }

    pub fn getNamedChild(self: Self, child_index: u32) ?Self {
        const child: Node = @bitCast(tree_sitter.ts_node_named_child(@bitCast(self), child_index));
        return if (child.isNull()) null else child;
    }

    pub fn getNamedChildCount(self: Self) u32 {
        return tree_sitter.ts_node_named_child_count(@bitCast(self));
    }

    pub fn getChildByFieldName(self: Self, name: []const u8, name_length: usize) ?Self {
        const child: Node = @bitCast(tree_sitter.ts_node_child_by_field_name(@bitCast(self), @ptrCast(name), @intCast(name_length)));
        return if (child.isNull()) null else child;
    }

    pub fn getChildByFieldId(self: Self, field_id: FieldId) ?Self {
        const child: Node = @bitCast(tree_sitter.ts_node_child_by_field_id(@bitCast(self), field_id));
        return if (child.isNull()) null else child;
    }

    pub fn getNextSibling(self: Self) ?Self {
        const next: Node = @bitCast(tree_sitter.ts_node_next_sibling(@bitCast(self)));
        return if (next.isNull()) null else next;
    }

    pub fn getPrevSibling(self: Self) ?Self {
        const prev: Node = @bitCast(tree_sitter.ts_node_prev_sibling(@bitCast(self)));
        return if (prev.isNull()) null else prev;
    }

    pub fn getNextNamedSibling(self: Self) ?Self {
        const next: Node = @bitCast(tree_sitter.ts_node_next_named_sibling(@bitCast(self)));
        return if (next.isNull()) null else next;
    }

    pub fn getPrevNamedSibling(self: Self) ?Self {
        const prev: Node = @bitCast(tree_sitter.ts_node_prev_named_sibling(@bitCast(self)));
        return if (prev.isNull()) null else prev;
    }

    pub fn getFirstChildForByte(self: Self, byte: u32) ?Self {
        const child: Node = @bitCast(tree_sitter.ts_node_first_child_for_byte(@bitCast(self), byte));
        return if (child.isNull()) null else child;
    }

    pub fn getFirstNamedChildForByte(self: Self, byte: u32) ?Self {
        const child: Node = @bitCast(tree_sitter.ts_node_first_named_child_for_byte(@bitCast(self), byte));
        return if (child.isNull()) null else child;
    }

    pub fn getDescendantCount(self: Self) u32 {
        return tree_sitter.ts_node_descendant_count(@bitCast(self));
    }

    pub fn getDescendantForByteRange(self: Self, start: u32, end: u32) ?Self {
        const desc: Node = @bitCast(tree_sitter.ts_node_descendant_for_byte_range(@bitCast(self), start, end));
        return if (desc.isNull()) null else desc;
    }

    pub fn getDescendantForPointRange(self: Self, start: Point, end: Point) ?Self {
        const desc: Node = @bitCast(tree_sitter.ts_node_descendant_for_point_range(@bitCast(self), @bitCast(start), @bitCast(end)));
        return if (desc.isNull()) null else desc;
    }

    pub fn getNamedDescendantForByteRange(self: Self, start: u32, end: u32) ?Self {
        const desc: Node = @bitCast(tree_sitter.ts_node_named_descendant_for_byte_range(@bitCast(self), start, end));
        return if (desc.isNull()) null else desc;
    }

    pub fn getNamedDescendantForPointRange(self: Self, start: Point, end: Point) ?Self {
        const desc: Node = @bitCast(tree_sitter.ts_node_named_descendant_for_point_range(@bitCast(self), @bitCast(start), @bitCast(end)));
        return if (desc.isNull()) null else desc;
    }

    pub fn eq(self: Self, other: Self) bool {
        return tree_sitter.ts_node_eq(@bitCast(self), @bitCast(other));
    }
};

pub fn editNodes(nodes: [*]Node, edit_input: [*]const InputEdit) void {
    tree_sitter.ts_node_edit(@ptrCast(nodes), @ptrCast(edit_input));
}

pub const TreeCursor = extern struct {
    tree: *const anyopaque,
    id: *const anyopaque,
    context: [3]u32,

    const Self = @This();

    pub fn init(node: Node) Self {
        return @bitCast(tree_sitter.ts_tree_cursor_new(@bitCast(node)));
    }

    pub fn deinit(self: *Self) void {
        tree_sitter.ts_tree_cursor_delete(@ptrCast(self));
    }

    pub fn reset(self: *Self, node: Node) void {
        tree_sitter.ts_tree_cursor_reset(@ptrCast(self), @bitCast(node));
    }

    pub fn resetTo(self: *Self, src: *Self) void {
        tree_sitter.ts_tree_cursor_reset_to(@ptrCast(self), @ptrCast(src));
    }

    pub fn currentNode(self: *Self) Node {
        return @bitCast(tree_sitter.ts_tree_cursor_current_node(@ptrCast(self)));
    }

    pub fn currentFieldName(self: *Self) ?[]const u8 {
        if (tree_sitter.ts_tree_cursor_current_field_name(@ptrCast(self))) |name| {
            return std.mem.span(name);
        } else return null;
    }

    pub fn currentFieldId(self: *Self) FieldId {
        return tree_sitter.ts_tree_cursor_current_field_id(@ptrCast(self));
    }

    pub fn gotoParent(self: *Self) bool {
        return tree_sitter.ts_tree_cursor_goto_parent(@ptrCast(self));
    }

    pub fn gotoNextSibling(self: *Self) bool {
        return tree_sitter.ts_tree_cursor_goto_next_sibling(@ptrCast(self));
    }

    pub fn gotoPreviousSibling(self: *Self) bool {
        return tree_sitter.ts_tree_cursor_goto_previous_sibling(@ptrCast(self));
    }

    pub fn gotoFirstChild(self: *Self) bool {
        return tree_sitter.ts_tree_cursor_goto_first_child(@ptrCast(self));
    }

    pub fn gotoLastChild(self: *Self) bool {
        return tree_sitter.ts_tree_cursor_goto_last_child(@ptrCast(self));
    }

    pub fn gotoDescendant(self: *Self, goal_descendant_index: u32) void {
        tree_sitter.ts_tree_cursor_goto_descendant(@ptrCast(self), goal_descendant_index);
    }

    pub fn currentDescendantIndex(self: *Self) u32 {
        return tree_sitter.ts_tree_cursor_current_descendant_index(@ptrCast(self));
    }

    pub fn currentDepth(self: *Self) u32 {
        return tree_sitter.ts_tree_cursor_current_depth(@ptrCast(self));
    }

    pub fn gotoFirstChildForByte(self: *Self, goal_byte: u32) i64 {
        return tree_sitter.ts_tree_cursor_goto_first_child_for_byte(@ptrCast(self), goal_byte);
    }

    pub fn gotoFirstChildForPoint(self: *Self, goal_point: Point) i64 {
        return tree_sitter.ts_tree_cursor_goto_first_child_for_point(@ptrCast(self), @bitCast(goal_point));
    }

    pub fn copy(self: *Self) Self {
        return @bitCast(tree_sitter.ts_tree_cursor_copy(@ptrCast(self)));
    }
};

pub const QueryCapture = extern struct {
    node: Node,
    index: u32,
};

pub const Quantifier = enum(u8) {
    zero,
    zero_or_one,
    zero_or_more,
    one,
    one_or_more,
};

pub const QueryMatch = extern struct {
    id: u32,
    pattern_index: u16,
    capture_count: u16,
    captures: *const QueryCapture,
};

pub const QueryPredicateStepType = enum(u8) {
    done,
    capture,
    string,
};

pub const QueryPredicateStep = extern struct {
    typ: QueryPredicateStepType,
    value_id: u32,
};

pub const QueryError = error{
    syntaxError,
    nodeTypeError,
    fieldError,
    captureError,
    structureError,
    languageError,
};

pub const LanguageGrammar = @import("grammars.zig").LanguageGrammar;
pub const loadLanguage = @import("grammars.zig").loadLanguage;
