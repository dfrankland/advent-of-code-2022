const std = @import("std");
const ziglyph = @import("ziglyph");
const Zigstr = @import("zigstr");
const inclusive_range_pair = @import("inclusive_range_pair.zig");

const input = @embedFile("./input");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var str = try Zigstr.fromConstBytes(allocator, input);
    defer str.deinit();

    var inclusiveRangePairsOverlappingOneAnother: usize = 0;

    var inclusiveRangePairParserState = inclusive_range_pair.InclusiveRangePairParserState.init();

    var graphemes = try str.graphemeIter();
    while (graphemes.next()) |grapheme| {
        inclusiveRangePairParserState = try inclusiveRangePairParserState.parse(allocator, grapheme);
        switch (inclusiveRangePairParserState) {
            .finished => |finished| {
                if (finished.first.oneOverlapsTheOther(finished.second)) {
                    inclusiveRangePairsOverlappingOneAnother += 1;
                }
                inclusiveRangePairParserState = inclusive_range_pair.InclusiveRangePairParserState.init();
            },
            else => {},
        }
    }

    std.debug.print("Inclusive range pairs containing one another: {}\n", .{inclusiveRangePairsOverlappingOneAnother});
}
