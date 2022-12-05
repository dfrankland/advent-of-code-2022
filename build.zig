const std = @import("std");
const deps = @import("deps.zig");

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var days = (try std.fs.cwd().openIterableDir("./day", std.fs.Dir.OpenDirOptions{ .access_sub_paths = true, .no_follow = false })).iterate();
    while (try days.next()) |day| {
        var name = std.ArrayList(u8).init(allocator);
        defer name.deinit();
        try name.appendSlice("advent-of-code-2022-day-");
        try name.appendSlice(day.name);

        var root_src = std.ArrayList(u8).init(allocator);
        defer root_src.deinit();
        try root_src.appendSlice("day/");
        try root_src.appendSlice(day.name);
        try root_src.appendSlice("/main.zig");

        const exe = b.addExecutable(name.items, root_src.items);
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();

        deps.addAllTo(exe);

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        var step_name = std.ArrayList(u8).init(allocator);
        defer step_name.deinit();
        try step_name.appendSlice("run-day-");
        try step_name.appendSlice(day.name);

        var description = std.ArrayList(u8).init(allocator);
        defer description.deinit();
        try description.appendSlice("Run the solution for day ");
        try description.appendSlice(day.name);

        const run_step = b.step(step_name.items, description.items);
        run_step.dependOn(&run_cmd.step);
    }
}
