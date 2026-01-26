const std = @import("std");
const terminal = @import("terminal.zig");

pub fn raca_log(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const scope_prefix = "(" ++ switch (scope) {
        .my_project, .nice_library, std.log.default_log_scope => @tagName(scope),
        else => if (@intFromEnum(level) <= @intFromEnum(std.log.Level.err))
            @tagName(scope)
        else
            return,
    } ++ "): ";

    const prefix = "[" ++ comptime level.asText() ++ scope_prefix;

    var buf: [1024]u8 = undefined;
    var msg: []const u8 = undefined;

    msg = std.fmt.bufPrint(&buf, prefix ++ format ++ "\n", args) catch @panic("[log.printf] std.fmt.bufPrint seems to have failed, please make sure the message didn't contain more than 1024 characters!");

    terminal.print_str(msg);
}
