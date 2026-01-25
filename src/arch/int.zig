const std = @import("std");
const eoi = @import("../device/apic/apic.zig").eoi;
const InterruptIndex = @import("../device/apic/apic.zig").InterruptIndex;
const PortIO = @import("./PortIO.zig");
const print = @import("../print.zig").print;

pub fn init() void {}

const InterruptStack = packed struct {
    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    r11: u64,
    r10: u64,
    r9: u64,
    r8: u64,
    rbp: u64,
    rdi: u64,
    rsi: u64,
    rdx: u64,
    rcx: u64,
    rbx: u64,
    rax: u64,

    vec: u64,
    error_code: u64,

    rip: u64,
    cs: u64,
    rflags: u64,

    rsp: u64,
    ss: u64,

    const Self = @This();

    pub fn show(self: *Self) void {
        const ty = @TypeOf(self.*);
        const ty_info = @typeInfo(ty);

        switch (ty_info) {
            .@"struct" => |info| {
                print("InterruptStack {{\n", .{});
                inline for (info.fields, 0..) |f, i| {
                    if (i == 0) {
                        print("    .", .{});
                    } else {
                        print(",\n    .", .{});
                    }
                    print("{s}", .{f.name});
                    print(" = 0x{x}", .{@field(self.*, f.name)});
                }
                print("\n}}\n", .{});
            },
            else => {
                @panic("error at show stack!");
            },
        }
    }
};

pub fn divide_zero(stack: *InterruptStack) void {
    print("Error!Divide Zero! Stack: \n", .{});
    stack.show();
    @panic("Error!");
}

pub fn debug_exception(stack: *InterruptStack) void {
    print("Error!Debug Exception! Stack: \n", .{});
    stack.show();
    @panic("Error!");
}

pub fn break_point(stack: *InterruptStack) void {
    print("Error!Break Point! Stack: \n", .{});
    stack.show();
}

pub fn over_flow(stack: *InterruptStack) void {
    print("Error!Overflow! Stack: \n", .{});
    stack.show();
    @panic("Error!");
}

pub fn invalid_opcode(stack: *InterruptStack) void {
    print("Error!Invalid Opcode! Stack: \n", .{});
    stack.show();
    @panic("Error!");
}

pub fn double_fault(stack: *InterruptStack) void {
    print("Error!Double Fault! Stack: \n", .{});
    stack.show();
    @panic("Error!");
}

pub fn invalid_tss(stack: *InterruptStack) void {
    print("Error!Invalid TSS! Stack: \n", .{});
    stack.show();
    @panic("Error!");
}

pub fn general_protection(stack: *InterruptStack) void {
    print("Error!General Protection! Stack: \n", .{});
    stack.show();
    @panic("Error!");
}

pub fn page_fault(stack: *InterruptStack) void {
    print("Error!Page Fault! Stack: \n", .{});
    stack.show();
    @panic("Error!");
}

const IRQ_0 = 0x20;

pub export fn interrupt_handler(stack: *InterruptStack) void {
    switch (stack.vec) {
        0 => divide_zero(stack),
        1 => debug_exception(stack),
        3 => break_point(stack),
        4 => over_flow(stack),
        6 => invalid_opcode(stack),
        8 => double_fault(stack),
        10 => invalid_tss(stack),
        13 => general_protection(stack),
        14 => page_fault(stack),
        else => {},
    }

    eoi();

    switch (stack.vec) {
        InterruptIndex.INT_TIMER => timer(stack),
        InterruptIndex.INT_KBD => keyboard(stack),
        InterruptIndex.INT_MOUSE => mouse(stack),
        else => {},
    }
}

pub fn timer(stack: *InterruptStack) void {
    _ = stack;
    //print(".",.{});
    //Log.printf(".", .{});
}

pub fn keyboard(stack: *InterruptStack) void {
    _ = stack;
    const scan_code = PortIO.new(0x60).inb();
    print("[{}]", .{scan_code});
}

pub fn mouse(stack: *InterruptStack) void {
    _ = stack;
    const scan_code = PortIO.new(0x60).inb();
    print("({})", .{scan_code});
}
