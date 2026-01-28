const builtin = @import("builtin");
const limine = @import("boot/limine.zig");
const log = @import("log.zig");
const std = @import("std");
const acpi = @import("driver/acpi.zig");
const mem = @import("mem.zig");
const arch = @import("arch.zig");

export var base_revision: limine.BaseRevision linksection(".limine_requests") = .{ .revision = 4 };

inline fn done() noreturn {
    while (true) {
        switch (builtin.cpu.arch) {
            .loongarch64 => asm volatile ("idle 0"),
            else => unreachable,
        }
    }
}

pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = log.raca_log,
};

export fn _start() callconv(.c) noreturn {
    if (!base_revision.is_supported()) {
        done();
    }

    log.init();
    mem.init();
    arch.init();
    acpi.init();

    std.log.debug("Hello, world!", .{});

    done();
}

var already_panicking: bool = false;

pub fn panic(
    msg: []const u8,
    stack_trace: ?*std.builtin.StackTrace,
    return_address: ?usize,
) noreturn {
    if (!already_panicking) {
        already_panicking = true;
        std.log.err("\n !!! Kernel Panic !!! ", .{});
        std.log.err(" !!! Message: {s}", .{msg});
        if (stack_trace) |trace| {
            std.log.info(" Stack Trace: ", .{});
            for (trace.*.instruction_addresses) |address| {
                log.println(" 0x{x:0>16}", .{address});
            }
        } else {
            std.log.info("  Stack Trace: ", .{});
            var stack = std.debug.StackIterator.init(
                return_address orelse @returnAddress(),
                null,
            );
            while (stack.next()) |address| {
                log.println(" 0x{x:0>16}", .{address});
            }
        }
    }
    done();
}
