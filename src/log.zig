const std = @import("std");
const Terminal = @import("driver/Terminal.zig");
const limine = @import("boot/limine.zig");

export var framebuffer_request = limine.FramebufferRequest{};
var terminal: Terminal = undefined;

pub fn init() void {
    const framebuffer = framebuffer_request.response.?.framebuffers_ptr[0];
    const ptr: [*]volatile u32 = @ptrCast(@alignCast(framebuffer.address));
    terminal = Terminal.init(Terminal.Buffer.init(ptr, framebuffer.width, framebuffer.height), Terminal.Font.default());
}

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
    } ++ ")";

    const prefix = "[" ++ comptime level.asText() ++ scope_prefix ++ "] ";

    var buf: [1024]u8 = undefined;
    var msg: []const u8 = undefined;

    msg = std.fmt.bufPrint(&buf, prefix ++ format ++ "\n", args) catch @panic("[log.printf] std.fmt.bufPrint seems to have failed, please make sure the message didn't contain more than 1024 characters!");

    terminal.print_str(msg);
}

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
