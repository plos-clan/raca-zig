const std = @import("std");
const terminal = @import("terminal.zig");

pub fn raca_log(
    comptime level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
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
    
    const color = switch (level) {
        .err => "\x1b[31m",
        .warn => "\x1b[33m",
        .info => "\x1b[32m",
        .debug => "\x1b[34m",
    };

    const prefix = "[" ++ color ++ comptime level.asText() ++ "\x1b[0m] " ++ scope_prefix;

    var buf: [1024]u8 = undefined;
    var msg: []const u8 = undefined;
    
    msg = std.fmt.bufPrint(&buf,prefix ++ format ++ "\n", args) catch @panic("[log.printf] std.fmt.bufPrint seems to have failed, please make sure the message didn't contain more than 1024 characters!");
    
    terminal.print_str(msg);
    
    for (msg) |c| {
        terminal.global_serial.putchar(c);
    }
}
