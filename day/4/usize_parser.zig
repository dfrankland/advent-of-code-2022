const std = @import("std");
const Zigstr = @import("zigstr");
const ziglyph = @import("ziglyph");

pub const UsizeParserStateTag = enum(u2) {
    idle,
    parsing,
    finished,
};

pub const UsizeParserState = union(UsizeParserStateTag) {
    const Self = @This();

    idle: UsizeParserStateIdle,
    parsing: UsizeParserStateParsing,
    finished: UsizeParserStateFinished,

    pub fn init() UsizeParserState {
        return UsizeParserStateIdle.init();
    }

    pub fn parse(self: Self, allocator: std.mem.Allocator, grapheme: ziglyph.Grapheme) anyerror!UsizeParserState {
        switch (self) {
            .idle => |idle| {
                return try idle.numberInput(allocator, grapheme);
            },
            .parsing => |parsing| {
                return try parsing.numberInput(grapheme);
            },
            .finished => {
                std.debug.print("Unexpected input: {s}", .{grapheme.bytes});
                return error.BadValue;
            },
        }
    }
};

pub const UsizeParserStateIdle = struct {
    const Self = @This();

    pub fn init() UsizeParserState {
        return .{
            .idle = .{},
        };
    }

    pub fn numberInput(self: Self, allocator: std.mem.Allocator, grapheme: ziglyph.Grapheme) anyerror!UsizeParserState {
        _ = self;
        return UsizeParserStateParsing.init(allocator, grapheme);
    }
};

pub const UsizeParserStateParsing = struct {
    const Self = @This();

    numbers: Zigstr,

    pub fn init(allocator: std.mem.Allocator, grapheme: ziglyph.Grapheme) anyerror!UsizeParserState {
        const self: Self = .{
            .numbers = try Zigstr.fromConstBytes(allocator, ""),
        };

        return try self.numberInput(grapheme);
    }

    pub fn deinit(self: *Self) void {
        self.numbers.deinit();
    }

    pub fn numberInput(self: Self, grapheme: ziglyph.Grapheme) anyerror!UsizeParserState {
        var numbers = self.numbers;

        if (grapheme.eql("0") or
            grapheme.eql("1") or
            grapheme.eql("2") or
            grapheme.eql("3") or
            grapheme.eql("4") or
            grapheme.eql("5") or
            grapheme.eql("6") or
            grapheme.eql("7") or
            grapheme.eql("8") or
            grapheme.eql("9"))
        {
            try numbers.concat(grapheme.bytes);
            return .{
                .parsing = .{
                    .numbers = numbers,
                },
            };
        }

        const number = numbers.parseInt(usize, 10) catch |err| {
            std.debug.print("Failed to parse this string as a number: \"{s}\"\nLatest input: \"{s}\"\n", .{ numbers.bytes(), grapheme.bytes });
            return err;
        };

        numbers.deinit();

        return UsizeParserStateFinished.init(number, grapheme);
    }
};

pub const UsizeParserStateFinished = struct {
    const Self = @This();

    number: usize,
    leftover: ziglyph.Grapheme,

    pub fn init(number: usize, leftover: ziglyph.Grapheme) UsizeParserState {
        return .{
            .finished = .{
                .number = number,
                .leftover = leftover,
            },
        };
    }
};
