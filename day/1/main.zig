const std = @import("std");
const Zigstr = @import("zigstr");

const input = @embedFile("./input");

fn maxCompare(_: void, a: usize, b: usize) std.math.Order {
    const difference = @intCast(isize, a) - @intCast(isize, b);
    if (difference == 0) {
        return std.math.Order.eq;
    } else if (difference > 0) {
        return std.math.Order.gt;
    } else {
        return std.math.Order.lt;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var str = try Zigstr.fromConstBytes(allocator, input);
    defer str.deinit();

    var highestCalories = std.PriorityQueue(usize, void, maxCompare).init(allocator, undefined);
    defer highestCalories.deinit();

    try highestCalories.add(0);
    try highestCalories.add(0);
    try highestCalories.add(0);

    var currentCalories: usize = 0;
    var currentCalorieString = try Zigstr.fromConstBytes(allocator, "");
    defer currentCalorieString.deinit();
    var isLastCharacterANewLine = false;

    var graphemes = try str.graphemeIter();
    while (graphemes.next()) |grapheme| {
        if (grapheme.eql("\n")) {
            if (!isLastCharacterANewLine) {
                isLastCharacterANewLine = true;
                currentCalories += try currentCalorieString.parseInt(usize, 10);
                try currentCalorieString.reset("");
                continue;
            }
            try highestCalories.add(currentCalories);
            _ = highestCalories.remove();
            currentCalories = 0;
            isLastCharacterANewLine = false;
            continue;
        }

        isLastCharacterANewLine = false;
        try currentCalorieString.concat(grapheme.bytes);
    }

    std.debug.print("Highest calories: {}\n", .{highestCalories.remove() + highestCalories.remove() + highestCalories.remove()});
}
