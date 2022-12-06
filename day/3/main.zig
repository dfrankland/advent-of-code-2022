const std = @import("std");
const ziglyph = @import("ziglyph");
const Zigstr = @import("zigstr");

const input = @embedFile("./input");

const GROUP_SIZE = 3;

const RucksackItem = enum(u8) {
    a = 1,
    b = 2,
    c = 3,
    d = 4,
    e = 5,
    f = 6,
    g = 7,
    h = 8,
    i = 9,
    j = 10,
    k = 11,
    l = 12,
    m = 13,
    n = 14,
    o = 15,
    p = 16,
    q = 17,
    r = 18,
    s = 19,
    t = 20,
    u = 21,
    v = 22,
    w = 23,
    x = 24,
    y = 25,
    z = 26,
    A = 27,
    B = 28,
    C = 29,
    D = 30,
    E = 31,
    F = 32,
    G = 33,
    H = 34,
    I = 35,
    J = 36,
    K = 37,
    L = 38,
    M = 39,
    N = 40,
    O = 41,
    P = 42,
    Q = 43,
    R = 44,
    S = 45,
    T = 46,
    U = 47,
    V = 48,
    W = 49,
    X = 50,
    Y = 51,
    Z = 52,

    pub fn init(grapheme: ziglyph.Grapheme) anyerror!RucksackItem {
        if (grapheme.eql("a")) {
            return .a;
        } else if (grapheme.eql("b")) {
            return .b;
        } else if (grapheme.eql("c")) {
            return .c;
        } else if (grapheme.eql("d")) {
            return .d;
        } else if (grapheme.eql("e")) {
            return .e;
        } else if (grapheme.eql("f")) {
            return .f;
        } else if (grapheme.eql("g")) {
            return .g;
        } else if (grapheme.eql("h")) {
            return .h;
        } else if (grapheme.eql("i")) {
            return .i;
        } else if (grapheme.eql("j")) {
            return .j;
        } else if (grapheme.eql("k")) {
            return .k;
        } else if (grapheme.eql("l")) {
            return .l;
        } else if (grapheme.eql("m")) {
            return .m;
        } else if (grapheme.eql("n")) {
            return .n;
        } else if (grapheme.eql("o")) {
            return .o;
        } else if (grapheme.eql("p")) {
            return .p;
        } else if (grapheme.eql("q")) {
            return .q;
        } else if (grapheme.eql("r")) {
            return .r;
        } else if (grapheme.eql("s")) {
            return .s;
        } else if (grapheme.eql("t")) {
            return .t;
        } else if (grapheme.eql("u")) {
            return .u;
        } else if (grapheme.eql("v")) {
            return .v;
        } else if (grapheme.eql("w")) {
            return .w;
        } else if (grapheme.eql("x")) {
            return .x;
        } else if (grapheme.eql("y")) {
            return .y;
        } else if (grapheme.eql("z")) {
            return .z;
        } else if (grapheme.eql("A")) {
            return .A;
        } else if (grapheme.eql("B")) {
            return .B;
        } else if (grapheme.eql("C")) {
            return .C;
        } else if (grapheme.eql("D")) {
            return .D;
        } else if (grapheme.eql("E")) {
            return .E;
        } else if (grapheme.eql("F")) {
            return .F;
        } else if (grapheme.eql("G")) {
            return .G;
        } else if (grapheme.eql("H")) {
            return .H;
        } else if (grapheme.eql("I")) {
            return .I;
        } else if (grapheme.eql("J")) {
            return .J;
        } else if (grapheme.eql("K")) {
            return .K;
        } else if (grapheme.eql("L")) {
            return .L;
        } else if (grapheme.eql("M")) {
            return .M;
        } else if (grapheme.eql("N")) {
            return .N;
        } else if (grapheme.eql("O")) {
            return .O;
        } else if (grapheme.eql("P")) {
            return .P;
        } else if (grapheme.eql("Q")) {
            return .Q;
        } else if (grapheme.eql("R")) {
            return .R;
        } else if (grapheme.eql("S")) {
            return .S;
        } else if (grapheme.eql("T")) {
            return .T;
        } else if (grapheme.eql("U")) {
            return .U;
        } else if (grapheme.eql("V")) {
            return .V;
        } else if (grapheme.eql("W")) {
            return .W;
        } else if (grapheme.eql("X")) {
            return .X;
        } else if (grapheme.eql("Y")) {
            return .Y;
        } else if (grapheme.eql("Z")) {
            return .Z;
        } else {
            std.debug.print("Expected [a-zA-Z], got {s}", .{grapheme.bytes});
            return error.BadValue;
        }
    }
};

pub fn NarrowedSet(
    comptime K: type,
) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        set: std.AutoHashMap(K, void),

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .set = std.AutoHashMap(K, void).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            return self.set.deinit();
        }

        pub fn expand(self: *Self, keys: []const K) anyerror!void {
            for (keys) |key| {
                try self.set.put(key, {});
            }
        }

        pub fn narrow(self: *Self, keys: []const K) anyerror!void {
            var narrowedSet = std.AutoHashMap(K, void).init(self.allocator);
            for (keys) |key| {
                if (self.set.contains(key)) {
                    try narrowedSet.put(key, {});
                }
            }
            self.set.deinit();
            self.set = narrowedSet;
        }
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var str = try Zigstr.fromConstBytes(allocator, input);
    defer str.deinit();

    var items = std.ArrayList(RucksackItem).init(allocator);
    defer items.deinit();

    var sumOfPriorities: usize = 0;

    var badgeNarrowedSet = NarrowedSet(RucksackItem).init(allocator);
    defer badgeNarrowedSet.deinit();

    var groupIndex: usize = 0;

    var sumOfBadgePriorities: usize = 0;

    var graphemes = try str.graphemeIter();
    while (graphemes.next()) |grapheme| {
        if (grapheme.eql("\n")) {
            groupIndex = (groupIndex % GROUP_SIZE) + 1;
            const half = (items.items.len / 2);

            var itemNarrowedSet = NarrowedSet(RucksackItem).init(allocator);
            defer itemNarrowedSet.deinit();

            try itemNarrowedSet.expand(items.items[0..half]);
            try itemNarrowedSet.narrow(items.items[half..]);

            var duplicatedItems = itemNarrowedSet.set.keyIterator();
            if (duplicatedItems.next()) |item| {
                sumOfPriorities += @enumToInt(item.*);
            }

            if (groupIndex == 1) {
                try badgeNarrowedSet.expand(items.items);
            } else {
                try badgeNarrowedSet.narrow(items.items);
            }

            if (groupIndex == GROUP_SIZE) {
                var duplicatedBadgeItems = badgeNarrowedSet.set.keyIterator();
                if (duplicatedBadgeItems.next()) |item| {
                    sumOfBadgePriorities += @enumToInt(item.*);
                }
                badgeNarrowedSet.set.clearRetainingCapacity();
            }

            items.clearRetainingCapacity();
        } else {
            const rucksackItem = try RucksackItem.init(grapheme);
            try items.append(rucksackItem);
        }
    }

    std.debug.print("Sum of priorities: {}\n", .{sumOfPriorities});
    std.debug.print("Sum of badge priorities: {}\n", .{sumOfBadgePriorities});
}
