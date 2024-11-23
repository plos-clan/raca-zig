//! Port I/O functionality

port: u16,

const Self = @This();

pub fn new(port: u16) Self {
    return Self{
        .port = port,
    };
}

pub fn offset(self: *const Self, off: u16) Self {
    return Self{
        .port = self.port + off,
    };
}

/// Input bytes
pub fn inb(self: *const Self,) u8 {
    return asm volatile ("inb %[port], %[ret]"
        : [ret] "={al}" (-> u8),
        : [port] "{dx}" (self.port),
        : "dx", "al"
    );
}

/// Input two bytes
pub fn inw(self: *const Self) u16 {
    return asm volatile ("inw %[port], %[ret]"
        : [ret] "={ax}" (-> u16),
        : [port] "{dx}" (self.port),
        : "dx", "al"
    );
}

/// Output bytes
pub fn outb(self: *const Self, val: u8) void {
    asm volatile ("outb %[val], %[port]"
        :
        : [val] "{al}" (val),
          [port] "{dx}" (self.port),
        : "dx", "al"
    );
}


