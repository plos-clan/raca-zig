const ost = @import("../lib/ost.zig");
const limine = @import("../boot/limine.zig");
const alloc = @import("../mem.zig").c_alloc;
const PortIO = @import("../arch/PortIO.zig");
pub export var framebuffer_request: limine.FramebufferRequest = .{};

pub var global_serial: SerialPort = undefined;

pub const SerialPort = struct {
    port: PortIO,

    const Self = @This();

    /// Create a new SerialPort
    pub fn new(base: u16) Self {
        return Self{
            .port = PortIO{ .port = base },
        };
    }

    /// Check whether the transmit buffer is empty or not
    pub fn is_transmit_buffer_empty(self: *Self) bool {
        return (self.port.offset(5).inb() & 0x20) != 0;
    }

    /// Put out a single char to COM1
    pub fn putchar(self: *Self, char: u8) void {
        while (!self.is_transmit_buffer_empty()) {}
        self.port.outb(char);
    }
};

fn serial_print(str: [*c]const u8) void {
    const len = @import("std").mem.len(str);
    for (str[0..len]) |c| {
        global_serial.putchar(c);
    }
}

pub fn init() void {
    global_serial = SerialPort.new(0x3f8);

    const framebuffer = framebuffer_request.response.?.framebuffers()[0];

    _ = ost.terminal_init(framebuffer.width, framebuffer.height, framebuffer.address, 16.0, &alloc.malloc, &alloc.free, &serial_print);

    ost.terminal_set_color_scheme(8);
}

pub fn print_str(str: []const u8) void {
    for (str) |c| {
        ost.terminal_advance_state_single(c);
    }
}
