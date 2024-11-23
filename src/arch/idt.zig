const std = @import("std");
const int = @import("./int.zig");

const Entry = extern struct {
    /// Low 16-bits of ISR address
    pointer_low: u16,

    /// The code selector to switch to when the interrupt is recieved.
    code_selector: u16,

    options: Options,

    /// Middle 16-bits of ISR address
    pointer_middle: u16,

    /// Upper 32-bits of ISR address
    pointer_high: u32,

    _reserved: u32 = 0,

    pub const Options = packed struct(u16) {
        /// Offset into the Interrupt Stack Table, zero means not used.
        ist: u3 = 0,

        _reserved1: u5 = 0,

        gate_type: GateType,

        _reserved2: u1 = 0,

        /// Defines the privilege levels which are allowed to access this interrupt via the INT instruction.
        ///
        /// Hardware interrupts ignore this mechanism.
        privilege_level: u2 = 0,

        present: bool,
    };

    pub const GateType = enum(u4) {
        /// Interrupts are automatically disabled upon entry and reenabled upon IRET
        interrupt = 0xE,

        trap = 0xF,
    };

    const Self = @This();

    pub fn new(
        code_selector: u16,
        gate_type: GateType,
    ) Self {
        return Self{
            .pointer_low = undefined,
            .code_selector = code_selector,
            .options = .{
                .gate_type = gate_type,
                .present = true,
            },
            .pointer_middle = undefined,
            .pointer_high = undefined,
        };
    }

    /// Sets the interrupt handler for this interrupt.
    pub fn set_handler(self: *Self, handler: *const fn () callconv(.Naked) void) void {
        const address = @intFromPtr(handler);
        self.pointer_low = @truncate(address);
        self.pointer_middle = @truncate(address >> 16);
        self.pointer_high = @truncate(address >> 32);
    }

    /// Sets the interrupt stack table (IST) index for this interrupt.
    pub fn set_stack(self: *Self, interrupt_stack: u3) void {
        self.options.ist = interrupt_stack +% 1;
    }
};

fn generate_handle(comptime num: u8) fn () callconv(.Naked) void {
    const error_code_list = [_]u8{ 8, 10, 11, 12, 13, 14, 17, 21, 29, 30 };

    const public = std.fmt.comptimePrint(
        \\     push ${}
        \\     push %%rax
        \\     push %%rbx
        \\     push %%rcx
        \\     push %%rdx
        \\     push %%rsi
        \\     push %%rdi
        \\     push %%rbp
        \\     push %%r8
        \\     push %%r9
        \\     push %%r10
        \\     push %%r11
        \\     push %%r12
        \\     push %%r13
        \\     push %%r14
        \\     push %%r15
        \\     mov %%rsp, %%rdi
    , .{num});

    const save_status = if (for (error_code_list) |value| {
        if (value == num) {
            break true;
        }
    } else false)
        public
    else
        \\     push $0b10000000000000000
        \\
        // Note: the Line breaks are very important
            ++
            public;
    const restore_status =
        \\     pop %%r15
        \\     pop %%r14
        \\     pop %%r13
        \\     pop %%r12
        \\     pop %%r11
        \\     pop %%r10
        \\     pop %%r9
        \\     pop %%r8
        \\     pop %%rbp
        \\     pop %%rdi
        \\     pop %%rsi
        \\     pop %%rdx
        \\     pop %%rcx
        \\     pop %%rbx
        \\     pop %%rax
        \\     add $16, %%rsp
        \\     iretq
    ;
    return struct {
        fn handle() callconv(.Naked) void {
            asm volatile (save_status ::: "memory");
            asm volatile ("call interrupt_handler");
            asm volatile (restore_status ::: "memory");
        }
    }.handle;
}

pub const InterruptDescriptorTable = struct {
    entries: [256]Entry = undefined,

    const Self = @This();

    pub fn new() Self {
        return Self{};
    }

    pub fn init(self: *Self) void {
        for (0..31) |vec| {
            self.entries[vec] = Entry.new(8, Entry.GateType.trap);
        }

        for (32..256) |vec| {
            self.entries[vec] = Entry.new(8, Entry.GateType.interrupt);
        }

        inline for (0..256) |vec| {
            self.entries[vec].set_handler(generate_handle(vec));
        }

        self.entries[8].set_stack(0);
    }

    pub fn load(self: *const Self) void {
        const IDTR = packed struct {
            limit: u16,
            address: u64,
        };

        const idtr = IDTR{
            .address = @intFromPtr(self),
            .limit = @sizeOf(Self) - 1,
        };

        asm volatile (
            \\  lidt (%[idtr_address])
            :
            : [idtr_address] "r" (&idtr),
        );
    }
};

var IDT = InterruptDescriptorTable.new();

pub fn init() void {
    int.init();
    IDT.init();
    IDT.load();
}
