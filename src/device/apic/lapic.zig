const Msr = @import("../../arch/Msr.zig");
const InterruptIndex = @import("./apic.zig").InterruptIndex;
const Log = @import("../log.zig");

const APIC_TIMER_FREQ = 1000;

const INTR_FIXED = 0;
const INTR_SMI = 0b010 << 8;
const INTR_NMI = 0b100 << 8;
const INTR_INIT = 0b101 << 8;
const INTR_STARTUP = 0b110 << 8;

const IPI_ASSERT = 1 << 14;
const IPI_LEVEL_TRIGGER = 1 << 15;

const LVTIndex = enum(u32) {
    Timer = 0,
    ThermalSensor = 1,
    PerformanceMonitoringCounters = 2,
    LINT0 = 3,
    LINT1 = 4,
    Error = 5,
};

pub const X2Apic = struct {
    const Self = @This();

    pub fn new() Self {
        return Self{};
    }

    fn write(self: *Self, reg: u32, value: u64) void {
        _ = self;
        Msr.new(@as(u64, 0x800 + (reg >> 4))).write(value);
    }

    fn read(self: *Self, reg: u32) u64 {
        _ = self;
        return Msr.new(@as(u64, 0x800 + (reg >> 4))).read();
    }

    fn write_lvt(self: *Self, index: LVTIndex, value: u32) void {
        self.write(0x320 + @intFromEnum(index) * 0x10, @as(u64, value));
    }

    fn read_lvt(self: *Self, index: LVTIndex) u32 {
        return @truncate(self.read(@truncate(0x320 + @intFromEnum(index) * 0x10)));
    }

    pub fn mask_lvt(self: *Self, index: LVTIndex) void {
        const value = self.read_lvt(index);
        self.write_lvt(index, value | (1 << 16));
    }

    pub fn enable_lvt(self: *Self, index: LVTIndex) void {
        const value = self.read_lvt(index);
        self.write_lvt(index, (value & (~@as(u32,1 << 16))));
    }

    pub fn eoi(self: *Self) void {
        self.write(0xb0, 0);
    }

    pub fn send_ipi(self: *Self, dest: u32, value: u64) void {
        self.write(0x300, @as(u64, dest) << 32 | value);

        while (self.read(0x300) & (1 << 12)) asm volatile ("pause");
    }

    pub fn init(self: *Self) void {
        self.ap_init();

        for (@intFromEnum(LVTIndex.Timer)..@intFromEnum(LVTIndex.Error)) |lvt| {
            self.write_lvt(@enumFromInt(lvt),0x10000);
        }

        self.write(0xf0, 0x1ff);

        asm volatile ("cli");

        self.write(0x3e0, 0b1011);
        self.write(0x380, ~@as(u64, 0));

        for (0..APIC_TIMER_FREQ) |_| {
            asm volatile ("nop");
        }

        const ticks = ~self.read(0x390);

        self.write_lvt(LVTIndex.Timer, InterruptIndex.INT_TIMER | (1 << 17));
        self.write(0x380, ticks);
        self.enable_lvt(LVTIndex.Timer);
    }

    pub fn ap_init(self: *Self) void {
        _ = self;

        var msr = Msr.new(0x1b).read();
        msr |= (1 << 11);
        msr |= (1 << 10);
        Msr.new(0x1b).write(msr);
    }

    pub fn id(self: *Self) u32 {
        return @truncate(self.read(0x20));
    }
};

pub const XApic = struct {
    data: u64,
    control: u64,

    const Self = @This();
};
