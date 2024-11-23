reg: u64,

pub fn new(reg: u64) @This() {
    return .{
        .reg = reg,
    };
}

pub fn read(self: *const @This()) u64 {
    return asm volatile ("rdmsr"
        : [ret] "={rax}" (-> u64),
        : [reg] "{rcx}" (self.reg),
    );
}

pub fn write(self: *const @This(), value: u64) void {
    asm volatile ("wrmsr"
        :
        : [reg] "{rcx}" (self.reg),
          [value1] "{rdx}" (value << 32),
          [value2] "{rax}" (value),
    );
}
