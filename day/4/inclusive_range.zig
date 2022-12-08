const std = @import("std");
const ziglyph = @import("ziglyph");
const usize_parser = @import("usize_parser.zig");

pub const InclusiveRange = struct {
    const Self = @This();

    start: usize,
    end: usize,

    pub fn init(start: usize, end: usize) Self {
        return .{
            .start = start,
            .end = end,
        };
    }

    pub fn oneOverlapsTheOther(self: *const Self, other: InclusiveRange) bool {
        const ordered: [2]InclusiveRange = if (self.start < other.start) .{ self.*, other } else .{ other, self.* };
        return (ordered[0].end >= ordered[1].start);
    }
};

pub const InclusiveRangeParserStateTag = enum(u2) {
    start,
    delimiter,
    end,
    finished,
};

pub const InclusiveRangeParserState = union(InclusiveRangeParserStateTag) {
    const Self = @This();

    start: InclusiveRangeParserStateStart,
    delimiter: InclusiveRangeParserStateDelimiter,
    end: InclusiveRangeParserStateEnd,
    finished: InclusiveRangeParserStateFinished,

    pub fn init() Self {
        return InclusiveRangeParserStateStart.init();
    }

    pub fn parse(self: Self, allocator: std.mem.Allocator, grapheme: ziglyph.Grapheme) anyerror!Self {
        switch (self) {
            .start => |start| {
                return try start.startInput(allocator, grapheme);
            },
            .delimiter => |delimiter| {
                return try delimiter.delimiterInput(grapheme);
            },
            .end => |end| {
                return try end.endInput(allocator, grapheme);
            },
            .finished => {
                std.debug.print("Unexpected input: {s}", .{grapheme.bytes});
                return error.BadValue;
            },
        }
    }
};

pub const InclusiveRangeParserStateStart = struct {
    const Self = @This();

    start: usize_parser.UsizeParserState,

    pub fn init() InclusiveRangeParserState {
        return .{
            .start = .{
                .start = usize_parser.UsizeParserState.init(),
            },
        };
    }

    pub fn startInput(self: Self, allocator: std.mem.Allocator, grapheme: ziglyph.Grapheme) anyerror!InclusiveRangeParserState {
        const start = try self.start.parse(allocator, grapheme);
        return switch (start) {
            .finished => |finished| try InclusiveRangeParserStateDelimiter.init(finished.number, finished.leftover),
            else => .{
                .start = .{
                    .start = start,
                },
            },
        };
    }
};

pub const InclusiveRangeParserStateDelimiter = struct {
    const Self = @This();

    start: usize,

    pub fn init(start: usize, grapheme: ziglyph.Grapheme) anyerror!InclusiveRangeParserState {
        const self: Self = .{
            .start = start,
        };

        return try self.delimiterInput(grapheme);
    }

    pub fn delimiterInput(self: Self, grapheme: ziglyph.Grapheme) anyerror!InclusiveRangeParserState {
        if (grapheme.eql("-")) {
            return InclusiveRangeParserStateEnd.init(self.start);
        }
        std.debug.print("Expected hyphen character, got {s}\n", .{grapheme.bytes});
        return error.BadValue;
    }
};

pub const InclusiveRangeParserStateEnd = struct {
    const Self = @This();

    start: usize,
    end: usize_parser.UsizeParserState,

    pub fn init(start: usize) InclusiveRangeParserState {
        return .{
            .end = .{
                .start = start,
                .end = usize_parser.UsizeParserState.init(),
            },
        };
    }

    pub fn endInput(self: Self, allocator: std.mem.Allocator, grapheme: ziglyph.Grapheme) anyerror!InclusiveRangeParserState {
        const end = try self.end.parse(allocator, grapheme);
        return switch (end) {
            .finished => |finished| InclusiveRangeParserStateFinished.init(self.start, finished.number, finished.leftover),
            else => .{
                .end = .{
                    .start = self.start,
                    .end = end,
                },
            },
        };
    }
};

pub const InclusiveRangeParserStateFinished = struct {
    const Self = @This();

    inclusiveRange: InclusiveRange,
    leftover: ziglyph.Grapheme,

    pub fn init(start: usize, end: usize, leftover: ziglyph.Grapheme) InclusiveRangeParserState {
        return .{
            .finished = .{
                .inclusiveRange = InclusiveRange.init(start, end),
                .leftover = leftover,
            },
        };
    }
};
