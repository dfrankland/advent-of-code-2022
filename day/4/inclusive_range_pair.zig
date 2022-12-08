const std = @import("std");
const ziglyph = @import("ziglyph");
const inclusive_range = @import("inclusive_range.zig");

pub const InclusiveRangePairParserStateTag = enum {
    first,
    pairDelimiter,
    second,
    rowDelimiter,
    finished,
};

pub const InclusiveRangePairParserState = union(InclusiveRangePairParserStateTag) {
    const Self = @This();

    first: InclusiveRangePairParserStateFirst,
    pairDelimiter: InclusiveRangePairParserStatePairDelimiter,
    second: InclusiveRangePairParserStateSecond,
    rowDelimiter: InclusiveRangePairParserStateRowDelimiter,
    finished: InclusiveRangePairParserStateFinished,

    pub fn init() Self {
        return InclusiveRangePairParserStateFirst.init();
    }

    pub fn parse(self: Self, allocator: std.mem.Allocator, grapheme: ziglyph.Grapheme) anyerror!Self {
        switch (self) {
            .first => |first| {
                return try first.firstInput(allocator, grapheme);
            },
            .pairDelimiter => |pairDelimiter| {
                return try pairDelimiter.pairDelimiterInput(grapheme);
            },
            .second => |second| {
                return try second.secondInput(allocator, grapheme);
            },
            .rowDelimiter => |rowDelimiter| {
                return try rowDelimiter.rowDelimiterInput(grapheme);
            },
            .finished => {
                std.debug.print("Unexpected input: {s}", .{grapheme.bytes});
                return error.BadValue;
            },
        }
    }
};

pub const InclusiveRangePairParserStateFirst = struct {
    const Self = @This();

    first: inclusive_range.InclusiveRangeParserState,

    pub fn init() InclusiveRangePairParserState {
        return .{
            .first = .{
                .first = inclusive_range.InclusiveRangeParserState.init(),
            },
        };
    }

    pub fn firstInput(self: Self, allocator: std.mem.Allocator, grapheme: ziglyph.Grapheme) anyerror!InclusiveRangePairParserState {
        const first = try self.first.parse(allocator, grapheme);
        return switch (first) {
            .finished => |finished| InclusiveRangePairParserStatePairDelimiter.init(finished.inclusiveRange, finished.leftover),
            else => .{
                .first = .{
                    .first = first,
                },
            },
        };
    }
};

pub const InclusiveRangePairParserStatePairDelimiter = struct {
    const Self = @This();

    first: inclusive_range.InclusiveRange,

    pub fn init(first: inclusive_range.InclusiveRange, grapheme: ziglyph.Grapheme) anyerror!InclusiveRangePairParserState {
        const self: Self = .{
            .first = first,
        };
        return try self.pairDelimiterInput(grapheme);
    }

    pub fn pairDelimiterInput(self: Self, grapheme: ziglyph.Grapheme) anyerror!InclusiveRangePairParserState {
        if (grapheme.eql(",")) {
            return InclusiveRangePairParserStateSecond.init(self.first);
        }

        std.debug.print("Expected comma, got {s}\n", .{grapheme.bytes});
        return error.BadValue;
    }
};

pub const InclusiveRangePairParserStateSecond = struct {
    const Self = @This();

    first: inclusive_range.InclusiveRange,
    second: inclusive_range.InclusiveRangeParserState,

    pub fn init(first: inclusive_range.InclusiveRange) InclusiveRangePairParserState {
        return .{
            .second = .{
                .first = first,
                .second = inclusive_range.InclusiveRangeParserState.init(),
            },
        };
    }

    pub fn secondInput(self: Self, allocator: std.mem.Allocator, grapheme: ziglyph.Grapheme) anyerror!InclusiveRangePairParserState {
        const second = try self.second.parse(allocator, grapheme);
        return switch (second) {
            .finished => |finished| InclusiveRangePairParserStateRowDelimiter.init(self.first, finished.inclusiveRange, finished.leftover),
            else => .{
                .second = .{
                    .first = self.first,
                    .second = second,
                },
            },
        };
    }
};

pub const InclusiveRangePairParserStateRowDelimiter = struct {
    const Self = @This();

    first: inclusive_range.InclusiveRange,
    second: inclusive_range.InclusiveRange,

    pub fn init(first: inclusive_range.InclusiveRange, second: inclusive_range.InclusiveRange, grapheme: ziglyph.Grapheme) anyerror!InclusiveRangePairParserState {
        const self: Self = .{
            .first = first,
            .second = second,
        };

        return try self.rowDelimiterInput(grapheme);
    }

    pub fn rowDelimiterInput(self: Self, grapheme: ziglyph.Grapheme) anyerror!InclusiveRangePairParserState {
        if (grapheme.eql("\n")) {
            return InclusiveRangePairParserStateFinished.init(self.first, self.second);
        }

        std.debug.print("Expected \\n, got {s}\n", .{grapheme.bytes});
        return error.BadValue;
    }
};

pub const InclusiveRangePairParserStateFinished = struct {
    const Self = @This();

    first: inclusive_range.InclusiveRange,
    second: inclusive_range.InclusiveRange,

    pub fn init(first: inclusive_range.InclusiveRange, second: inclusive_range.InclusiveRange) InclusiveRangePairParserState {
        return .{
            .finished = .{
                .first = first,
                .second = second,
            },
        };
    }
};
