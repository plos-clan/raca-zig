const std = @import("std");

/// The x86_64 Task State Segment structure.
pub const TaskStateSegment = extern struct {
    _reserved_1: u32 align(1) = 0,

    /// Stack pointers (RSP) for privilege levels 0-2.
    privilege_stack_table: [3]u64 align(1) = [_]u64{0} ** 3,

    _reserved_2: u64 align(1) = 0,

    /// Interrupt stack table (IST) pointers.
    interrupt_stack_table: [7]u64 align(1) = [_]u64{0} ** 7,

    _reserved_3: u64 align(1) = 0,

    _reserved_4: u16 align(1) = 0,

    /// The 16-bit offset to the I/O permission bit map from the 64-bit TSS base.
    iomap_base: u16 align(1) = 0,

    const Self = @This();

    pub fn new() Self {
        return Self{};
    }

    /// Sets the stack for the given stack selector.
    pub fn set_interrupt_stack(
        self: *Self,
        index: u64,
        stack: u64,
    ) void {
        self.interrupt_stack_table[index] = stack;
    }

    /// Sets the stack for the given privilege level.
    pub fn set_privilege_stack(self: *Self, privilege_level: u64, stack: u64) void {
        self.privilege_stack_table[privilege_level] = stack;
    }
};

/// The Global Descriptor Table for x86_64.
pub const GlobalDescriptorTalbe = extern struct {
    descriptors: [7]u64 = [7]u64{
        0x0000000000000000, // Null
        0x00A09A0000000000, // 64 bit code
        0x0000920000000000, // 64 bit data
        0x00A09A0000000000 | (3 << 45), // Userspace 64 bit code
        0x0000920000000000 | (3 << 45), // Userspace 64 bit data
        0, // TSS
        0,
    },

    pub const null_selector: u16 = 0x00;
    pub const kernel_code_selector: u16 = 0x08;
    pub const kernel_data_selector: u16 = 0x10;
    pub const user_code_selector: u16 = 0x18 | 3;
    pub const user_data_selector: u16 = 0x20 | 3;
    pub const tss_selector: u16 = 0x28;

    const mask_u8: u64 = std.math.maxInt(u8);
    const mask_u16: u64 = std.math.maxInt(u16);
    const mask_u24: u64 = std.math.maxInt(u24);

    const Self = @This();

    pub fn new() Self {
        return Self{};
    }

    pub fn set_tss(self: *Self, tss: *TaskStateSegment) void {
        const tss_ptr = @intFromPtr(tss);

        const low_base: u64 = (tss_ptr & mask_u24) << 16;
        const mid_base: u64 = ((tss_ptr >> 24) & mask_u8) << 56;

        const high_base: u64 = tss_ptr >> 32;

        const present: u64 = 1 << 47;

        const available_64_bit_tss: u64 = 0b1001 << 40;

        const limit: u64 = (@sizeOf(TaskStateSegment) - 1) & mask_u16;

        self.descriptors[5] = low_base | mid_base | limit | present | available_64_bit_tss;
        self.descriptors[6] = high_base;

        asm volatile (
            \\  ltr %[ts_sel]
            :
            : [ts_sel] "rm" (tss_selector),
        );
    }

    pub fn load(self: *Self) void {
        const gdt_ptr = GDTR{
            .limit = @sizeOf(Self) - 1,
            .base = @intFromPtr(self),
        };

        // Load the GDT
        asm volatile (
            \\  lgdt %[p]
            :
            : [p] "*p" (&gdt_ptr),
        );

        // Use the data selectors
        asm volatile (
            \\  mov %[dsel], %%ds
            \\  mov %[dsel], %%fs
            \\  mov %[dsel], %%gs
            \\  mov %[dsel], %%es
            \\  mov %[dsel], %%ss
            :
            : [dsel] "rm" (kernel_data_selector),
        );

        // Use the code selector
        asm volatile (
            \\ push %[csel]
            \\ lea 1f(%%rip), %%rax
            \\ push %%rax
            \\ .byte 0x48, 0xCB // Far return
            \\ 1:
            :
            : [csel] "i" (kernel_code_selector),
            : "rax"
        );
    }

    const GDTR = packed struct {
        limit: u16,
        base: u64,
    };
};

var GDT: GlobalDescriptorTalbe = GlobalDescriptorTalbe.new();
var TSS: TaskStateSegment = TaskStateSegment.new();

const tss_stack_size = 4*1024;
var tss_stack: [tss_stack_size]u8 = [_]u8{0} ** tss_stack_size;

pub fn init() void {
    const stack_start = @intFromPtr(&tss_stack);
    const stack_end = stack_start + tss_stack_size;

    TSS.set_interrupt_stack(0,stack_end);
    GDT.load();
    GDT.set_tss(&TSS);
}

