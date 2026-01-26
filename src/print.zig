const terminal = @import("device/terminal.zig");
const std = @import("std");

pub fn print(comptime format: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    var msg: []const u8 = undefined;

    msg = std.fmt.bufPrint(&buf, format, args) catch @panic("[print.print] std.fmt.bufPrint seems to have failed, please make sure the message didn't contain more than 1024 characters!");

    terminal.print_str(msg);
}

pub fn println(comptime fmt: []const u8, args: anytype) void {
    print(fmt ++ "\n", args);
}

pub fn serial_print(comptime format: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    var msg: []const u8 = undefined;

    msg = std.fmt.bufPrint(&buf, format, args) catch @panic("[print.print] std.fmt.bufPrint seems to have failed, please make sure the message didn't contain more than 1024 characters!");

    for (msg) |c| {
        terminal.global_serial.putchar(c);
    }
}

pub fn serial_println(comptime fmt: []const u8, args: anytype) void {
    serial_print(fmt ++ "\n", args);
}
