const std = @import("std");
const ziglyph = @import("ziglyph");
const Zigstr = @import("zigstr");

const input = @embedFile("./input");

const StrategyGuideRowParserStateTag = enum(u2) {
    theirInput,
    spaceDelimiter,
    expectedOutcomeInput,
    newLineDelimiter,
};

const StrategyGuideRowParserState = union(StrategyGuideRowParserStateTag) {
    theirInput: StrategyGuideRowParserStateTheirInput,
    spaceDelimiter: StrategyGuideRowParserStateSpaceDelimiter,
    expectedOutcomeInput: StrategyGuideRowParserStateExpectedOutcomeInput,
    newLineDelimiter: StrategyGuideRowParserStateFinished,

    pub fn init() StrategyGuideRowParserState {
        return StrategyGuideRowParserStateTheirInput.init();
    }
};

const StrategyGuideRowParserStateTheirInput = struct {
    pub const TheirShape = enum {
        A,
        B,
        C,

        fn parseGrapheme(grapheme: ziglyph.Grapheme) anyerror!TheirShape {
            if (grapheme.eql("A")) {
                return .A;
            } else if (grapheme.eql("B")) {
                return .B;
            } else if (grapheme.eql("C")) {
                return .C;
            } else {
                std.debug.print("Expected A, B, or C, got {s}", .{grapheme.bytes});
                return error.BadValue;
            }
        }
    };

    pub fn init() StrategyGuideRowParserState {
        return StrategyGuideRowParserState{
            .theirInput = StrategyGuideRowParserStateTheirInput{},
        };
    }

    pub fn theirShapeInput(self: StrategyGuideRowParserStateTheirInput, grapheme: ziglyph.Grapheme) anyerror!StrategyGuideRowParserState {
        _ = self;
        return StrategyGuideRowParserStateSpaceDelimiter.init(try TheirShape.parseGrapheme(grapheme));
    }
};

const StrategyGuideRowParserStateSpaceDelimiter = struct {
    theirShape: StrategyGuideRowParserStateTheirInput.TheirShape,

    pub fn init(theirShape: StrategyGuideRowParserStateTheirInput.TheirShape) StrategyGuideRowParserState {
        return StrategyGuideRowParserState{
            .spaceDelimiter = StrategyGuideRowParserStateSpaceDelimiter{
                .theirShape = theirShape,
            },
        };
    }

    pub fn spaceDelimiterInput(self: StrategyGuideRowParserStateSpaceDelimiter, grapheme: ziglyph.Grapheme) anyerror!StrategyGuideRowParserState {
        if (grapheme.eql(" ")) {
            return StrategyGuideRowParserStateExpectedOutcomeInput.init(self.theirShape);
        }
        std.debug.print("Expected space character, got {s}", .{grapheme.bytes});
        return error.BadValue;
    }
};

const StrategyGuideRowParserStateExpectedOutcomeInput = struct {
    theirShape: StrategyGuideRowParserStateTheirInput.TheirShape,

    pub const ExpectedOutcome = enum(u8) {
        // lose
        X = 0,
        // draw
        Y = 3,
        // win
        Z = 6,

        pub fn parseGrapheme(grapheme: ziglyph.Grapheme) anyerror!ExpectedOutcome {
            if (grapheme.eql("X")) {
                return .X;
            } else if (grapheme.eql("Y")) {
                return .Y;
            } else if (grapheme.eql("Z")) {
                return .Z;
            } else {
                std.debug.print("Expected X, Y, or Z, got {s}", .{grapheme.bytes});
                return error.BadValue;
            }
        }
    };

    pub fn init(theirShape: StrategyGuideRowParserStateTheirInput.TheirShape) StrategyGuideRowParserState {
        return StrategyGuideRowParserState{
            .expectedOutcomeInput = StrategyGuideRowParserStateExpectedOutcomeInput{
                .theirShape = theirShape,
            },
        };
    }

    pub fn expectOutcomeInput(self: StrategyGuideRowParserStateExpectedOutcomeInput, grapheme: ziglyph.Grapheme) anyerror!StrategyGuideRowParserState {
        return StrategyGuideRowParserStateFinished.init(self.theirShape, try ExpectedOutcome.parseGrapheme(grapheme));
    }
};

const StrategyGuideRowParserStateFinished = struct {
    theirShape: StrategyGuideRowParserStateTheirInput.TheirShape,
    expectedOutcome: StrategyGuideRowParserStateExpectedOutcomeInput.ExpectedOutcome,
    ourShape: OurShape,
    roundScore: usize,

    pub const OurShape = enum(u8) {
        rock = 1,
        paper = 2,
        scissors = 3,

        pub fn init(theirShape: StrategyGuideRowParserStateTheirInput.TheirShape, expectedOutcome: StrategyGuideRowParserStateExpectedOutcomeInput.ExpectedOutcome) OurShape {
            return switch (theirShape) {
                .A => switch (expectedOutcome) {
                    .X => .scissors,
                    .Y => .rock,
                    .Z => .paper,
                },
                .B => switch (expectedOutcome) {
                    .X => .rock,
                    .Y => .paper,
                    .Z => .scissors,
                },
                .C => switch (expectedOutcome) {
                    .X => .paper,
                    .Y => .scissors,
                    .Z => .rock,
                },
            };
        }
    };

    pub fn init(theirShape: StrategyGuideRowParserStateTheirInput.TheirShape, expectedOutcome: StrategyGuideRowParserStateExpectedOutcomeInput.ExpectedOutcome) StrategyGuideRowParserState {
        const ourShape = OurShape.init(theirShape, expectedOutcome);
        return StrategyGuideRowParserState{
            .newLineDelimiter = StrategyGuideRowParserStateFinished{
                .theirShape = theirShape,
                .expectedOutcome = expectedOutcome,
                .ourShape = ourShape,
                .roundScore = @enumToInt(expectedOutcome) + @enumToInt(ourShape),
            },
        };
    }

    pub fn newLineDelimiterInput(self: StrategyGuideRowParserStateFinished, grapheme: ziglyph.Grapheme) anyerror!StrategyGuideRowParserState {
        _ = self;
        if (grapheme.eql("\n")) {
            return StrategyGuideRowParserState.init();
        }
        std.debug.print("Expected \\n, got {s}", .{grapheme.bytes});
        return error.BadValue;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var str = try Zigstr.fromConstBytes(allocator, input);
    defer str.deinit();

    var gameState = StrategyGuideRowParserState.init();

    var totalScore: usize = 0;

    var graphemes = try str.graphemeIter();
    while (graphemes.next()) |grapheme| {
        switch (gameState) {
            .theirInput => |theirInput| {
                gameState = try theirInput.theirShapeInput(grapheme);
            },
            .spaceDelimiter => |spaceDelimiter| {
                gameState = try spaceDelimiter.spaceDelimiterInput(grapheme);
            },
            .expectedOutcomeInput => |expectedOutcomeInput| {
                gameState = try expectedOutcomeInput.expectOutcomeInput(grapheme);
            },
            .newLineDelimiter => |newLineDelimiter| {
                totalScore += newLineDelimiter.roundScore;
                gameState = try newLineDelimiter.newLineDelimiterInput(grapheme);
            },
        }
    }

    std.debug.print("Total score: {}\n", .{totalScore});
}
