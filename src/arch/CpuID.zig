const CPUIDInfo = struct {
    rax: u64 = 0,
    rbx: u64 = 0,
    rcx: u64 = 0,
    rdx: u64 = 0,

    const Self = @This();

    pub fn new(op: u64) Self {
        var rax: u64 = 0;
        var rbx: u64 = 0;
        var rcx: u64 = 0;
        var rdx: u64 = 0;

        asm volatile ("cpuid"
            : [_] "={rax}" (rax),
              [_] "={rbx}" (rbx),
              [_] "={rcx}" (rcx),
              [_] "={rdx}" (rdx),
            : [_] "{rax}" (op),
              [_] "{rcx}" (0),
        );

        return Self{
            .rax = rax,
            .rbx = rbx,
            .rcx = rcx,
            .rdx = rdx,
        };
    }

    pub fn vendor_id() [16]u8 {
        var vendor: [16]u8 = [_]u8{0} ** 16;

        var info = Self.new(0);
        const info_ptr = &info;
        const info_bytes: [*]u8 = @ptrCast(info_ptr);

        for (0..4) |i| {
            vendor[i] = info_bytes[i + 8];
        }
        for (0..4) |i| {
            vendor[i + 4] = info_bytes[i + 24];
        }
        for (0..4) |i| {
            vendor[i + 8] = info_bytes[i + 16];
        }

        return vendor;
    }

    pub fn has_x2apic() bool {
        const info = Self.new(1);
        return (info.rcx & (1 << 21)) == 1;
    }
};

vendor: [16]u8 = [_]u8{0} ** 16,
x2apic: bool,

//const Self = @This();

pub fn new() @This() {
    return .{
        .vendor = CPUIDInfo.vendor_id(),
        .x2apic = CPUIDInfo.has_x2apic(),
    };
}

pub fn vendor_id(self: *const @This()) [16]u8 {
    return self.vendor;
}

pub fn has_x2apic(self: *const @This()) bool {
    return self.x2apic;
}
