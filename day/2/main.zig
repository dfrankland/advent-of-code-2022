const std = @import("std");
const ziglyph = @import("ziglyph");
const Zigstr = @import("zigstr");

const input = @embedFile("./input");

const GameStateTag = enum(u2) {
    theirTurn,
    waiting,
    ourTurn,
    finished,
};

const GameState = union(GameStateTag) {
    theirTurn: GameStateTheirTurn,
    waiting: GameStateWaiting,
    ourTurn: GameStateOurTurn,
    finished: GameStateFinished,

    pub fn init() GameState {
        return GameStateTheirTurn.init();
    }
};

const GameStateTheirTurn = struct {
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

    pub fn init() GameState {
        return GameState{
            .theirTurn = GameStateTheirTurn{},
        };
    }

    pub fn theirShapeInput(self: GameStateTheirTurn, grapheme: ziglyph.Grapheme) anyerror!GameState {
        _ = self;
        return GameStateWaiting.init(try TheirShape.parseGrapheme(grapheme));
    }
};

const GameStateWaiting = struct {
    theirShape: GameStateTheirTurn.TheirShape,

    pub fn init(theirShape: GameStateTheirTurn.TheirShape) GameState {
        return GameState{
            .waiting = GameStateWaiting{
                .theirShape = theirShape,
            },
        };
    }

    pub fn waitInput(self: GameStateWaiting, grapheme: ziglyph.Grapheme) anyerror!GameState {
        if (grapheme.eql(" ")) {
            return GameStateOurTurn.init(self.theirShape);
        }
        std.debug.print("Expected space character, got {s}", .{grapheme.bytes});
        return error.BadValue;
    }
};

const GameStateOurTurn = struct {
    theirShape: GameStateTheirTurn.TheirShape,

    pub const OurShape = enum(u8) {
        X = 1,
        Y = 2,
        Z = 3,

        pub fn parseGrapheme(grapheme: ziglyph.Grapheme) anyerror!OurShape {
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

    pub fn init(theirShape: GameStateTheirTurn.TheirShape) GameState {
        return GameState{
            .ourTurn = GameStateOurTurn{
                .theirShape = theirShape,
            },
        };
    }

    pub fn ourShapeInput(self: GameStateOurTurn, grapheme: ziglyph.Grapheme) anyerror!GameState {
        return GameStateFinished.init(self.theirShape, try OurShape.parseGrapheme(grapheme));
    }
};

const GameStateFinished = struct {
    theirShape: GameStateTheirTurn.TheirShape,
    ourShape: GameStateOurTurn.OurShape,
    outcome: Outcome,
    roundScore: usize,

    pub const Outcome = enum(u8) {
        win = 6,
        draw = 3,
        loss = 0,

        pub fn init(theirShape: GameStateTheirTurn.TheirShape, ourShape: GameStateOurTurn.OurShape) Outcome {
            return switch (theirShape) {
                .A => switch (ourShape) {
                    .X => .draw,
                    .Y => .win,
                    .Z => .loss,
                },
                .B => switch (ourShape) {
                    .X => .loss,
                    .Y => .draw,
                    .Z => .win,
                },
                .C => switch (ourShape) {
                    .X => .win,
                    .Y => .loss,
                    .Z => .draw,
                },
            };
        }
    };

    pub fn init(theirShape: GameStateTheirTurn.TheirShape, ourShape: GameStateOurTurn.OurShape) GameState {
        const outcome = Outcome.init(theirShape, ourShape);
        return GameState{
            .finished = GameStateFinished{
                .theirShape = theirShape,
                .ourShape = ourShape,
                .outcome = outcome,
                .roundScore = @enumToInt(ourShape) + @enumToInt(outcome),
            },
        };
    }

    pub fn nextGameInput(self: GameStateFinished, grapheme: ziglyph.Grapheme) anyerror!GameState {
        _ = self;
        if (grapheme.eql("\n")) {
            return GameState.init();
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

    var gameState = GameState.init();

    var totalScore: usize = 0;

    var graphemes = try str.graphemeIter();
    while (graphemes.next()) |grapheme| {
        switch (gameState) {
            .theirTurn => |theirTurn| {
                gameState = try theirTurn.theirShapeInput(grapheme);
            },
            .waiting => |waiting| {
                gameState = try waiting.waitInput(grapheme);
            },
            .ourTurn => |ourTurn| {
                gameState = try ourTurn.ourShapeInput(grapheme);
            },
            .finished => |finished| {
                totalScore += finished.roundScore;
                gameState = try finished.nextGameInput(grapheme);
            },
        }
    }

    std.debug.print("Total score: {}\n", .{totalScore});
}
