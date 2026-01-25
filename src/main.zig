const builtin = @import("builtin");
const limine = @import("boot.zig").limine;
const terminal = @import("device/terminal.zig");
const log = @import("device/log.zig");
const std = @import("std");
const arch = @import("arch.zig");
const print = @import("print.zig");
const apic = @import("device/apic/apic.zig");

pub const mem = @import("mem.zig");

pub export var base_revision: limine.BaseRevision = .{ .revision = 2 };

inline fn done() noreturn {
    while (true) {
        switch (builtin.cpu.arch) {
            .x86_64 => asm volatile ("hlt"),
            .aarch64 => asm volatile ("wfi"),
            .riscv64 => asm volatile ("wfi"),
            else => unreachable,
        }
    }
}

pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = log.raca_log,
};

// The following will be our kernel's entry point.
export fn _start() callconv(.c) noreturn {
    // Ensure the bootloader actually understands our base revision (see spec).
    if (!base_revision.is_supported()) {
        done();
    }

    mem.init();

    terminal.init();

    arch.init();

    apic.init();

    //asm volatile ("int $0");

    std.log.debug("Hello, world!", .{});

    asm volatile ("sti");

    // We're done, just hang...
    done();
}

var already_panicking: bool = false;

/// Handle kernel panics
pub fn panic(msg: []const u8, stack_trace: ?*std.builtin.StackTrace, return_address: ?usize) noreturn {
    // put out things
    // only print things if not panicking while panic
    if (!already_panicking) {
        already_panicking = true;
        std.log.err("\n !!! Kernel Panic !!! ", .{});
        std.log.err(" !!! Message: {s}", .{msg});
        if (stack_trace) |trace| {
            // if stack trace is delivered, we can loop over it
            std.log.info(" Stack Trace: ", .{});
            for (trace.*.instruction_addresses) |address| {
                print.println(" 0x{x:0>16}", .{address});
            }
        } else {
            // else, we will have to capture it via std.debug.StackIterator
            std.log.info("  Stack Trace: ", .{});
            var stack = std.debug.StackIterator.init(return_address orelse @returnAddress(), null);
            while (stack.next()) |address| {
                print.println(" 0x{x:0>16}", .{address});
            }
        }
    }
    done();
}
