const std = @import("std");
const mem = std.mem;

pub const IoApic = struct {
    reg: u64,
    data: u64,

    const Self = @This();

    pub fn new(addr: u64) Self {
        return Self{
            .reg = addr,
            .data = addr + 0x10,
        };
    }

    pub fn disable_all(self: *Self) void {
        for (0..self.maxintr() + 1) |irq| {
            self.disable(@truncate(irq));
        }
    }

    // 被优化逼得没办法，故此用内联汇编读写内存
    fn read(self: *Self, reg: u8) u32 {
        mem.writeInt(u8, @ptrFromInt(self.reg), reg, .little);
        return mem.readInt(u32, @ptrFromInt(self.data), .little);
    }

    // 被优化逼得没办法，故此用内联汇编读写内存
    fn write(self: *Self, reg: u8, data: u32) void {
        mem.writeInt(u8, @ptrFromInt(self.reg), reg, .little);
        mem.writeInt(u32, @ptrFromInt(self.data), data, .little);
    }

    fn write_irq(self: *Self, irq: u8, vector: u8, flags: u32, dest: u8) void {
        self.write(REG_TABLE + 2 * irq, @as(u32, vector) | flags);
        self.write(REG_TABLE + 2 * irq + 1, @as(u32, dest) << 24);
    }

    pub fn enable(self: *Self, irq: u8, cpunum: u8) void {
        const vector = self.irq_vector(irq);
        self.write_irq(irq, vector, RedirectionEntry.NONE, cpunum);
    }

    pub fn disable(self: *Self, irq: u8) void {
        const vector = self.irq_vector(irq);
        self.write_irq(irq, vector, RedirectionEntry.DISABLED, 0);
    }

    pub fn config(self: *Self, irq_offset: u8, vector: u8, dest: u8, level_triggered: bool, active_high: bool, dest_logic: bool, mask: bool) void {
        var flags = RedirectionEntry.NONE;

        if (level_triggered) {
            flags |= RedirectionEntry.LEVEL;
        }
        if (!active_high) {
            flags |= RedirectionEntry.ACTIVELOW;
        }
        if (dest_logic) {
            flags |= RedirectionEntry.LOGICAL;
        }
        var t_mask = mask;
        if ((vector < 0x20) || (vector > 0xef)) {
            t_mask = true;
        }
        if (t_mask) {
            flags |= RedirectionEntry.DISABLED;
        }
        self.write_irq(irq_offset, vector, flags, dest);
    }

    pub fn irq_vector(self: *Self, irq: u8) u8 {
        return @truncate(self.read(REG_TABLE + 2 * irq) & 0xff);
    }

    pub fn set_irq_vector(self: *Self, irq: u8, vector: u8) void {
        var old = self.read(REG_TABLE + 2 * irq);
        const old_vector = old & 0xff;
        if ((old_vector < 0x20) or (old_vector > 0xfe)) {
            old |= RedirectionEntry.DISABLED;
        }
        old >>= 8;
        old = (old << 8) | vector;
        self.write(REG_TABLE + 2 * irq, old);
    }

    pub fn id(self: *Self) u8 {
        return @truncate((self.read(REG_ID) >> 24) & 0xf);
    }

    pub fn version(self: *Self) u8 {
        return @truncate(self.read(REG_VER) & 0xff);
    }

    pub fn maxintr(self: *Self) u8 {
        return @truncate((self.read(REG_VER) >> 16) & 0xff);
    }
};

/// Default physical address of IO APIC
pub const IOAPIC_ADDR: u32 = 0xFEC00000;
/// Register index: ID
const REG_ID: u8 = 0x00;
/// Register index: version
const REG_VER: u8 = 0x01;
/// Redirection table base
const REG_TABLE: u8 = 0x10;

const RedirectionEntry = struct {
    /// Interrupt disabled
    pub const DISABLED = 0x00010000;
    /// Level-triggered (vs edge-)
    pub const LEVEL = 0x00008000;
    /// Active low (vs high)
    pub const ACTIVELOW = 0x00002000;
    /// Destination is CPU id (vs APIC ID)
    pub const LOGICAL = 0x00000800;
    /// None
    pub const NONE = 0x00000000;
};
