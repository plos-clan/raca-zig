const log = @import("../log.zig");
const PortIO = @import("../../arch/PortIO.zig");
const CpuID = @import("../../arch/CpuID.zig");
const IoApic = @import("./ioapic.zig").IoApic;
const IOAPIC_ADDR = @import("./ioapic.zig").IOAPIC_ADDR;
const X2Apic = @import("./lapic.zig").X2Apic;
const mem = @import("../../mem.zig");

var ioapic: IoApic = undefined;
var lapic = X2Apic.new();

pub fn init() void {
    //const cpuid = CpuID.new();
    //if (!cpuid.has_x2apic()) {
    //    Log.printf("CPU doesn't support x2apic!", .{});
    //    @panic("CPU doesn't support x2apic!");
    //}else {
    //    Log.printf("CPU supports x2apic!", .{});
    //}

    ioapic = IoApic.new(mem.convert_physical_to_virtual(IOAPIC_ADDR));

    PortIO.new(0x21).outb(0xff);
    PortIO.new(0xa1).outb(0xff);

    lapic.init();

    const id: u8 = @truncate(lapic.id());

    ioapic.disable_all();

    ioapic.set_irq_vector(IrqVecotr.IRQ_KBD, InterruptIndex.INT_KBD);
    ioapic.set_irq_vector(IrqVecotr.IRQ_MOUSE, InterruptIndex.INT_MOUSE);

    ioapic.enable(IrqVecotr.IRQ_KBD, id);
    ioapic.enable(IrqVecotr.IRQ_MOUSE, id);

    asm volatile ("cli");
}

pub fn eoi() void {
    lapic.eoi();
}

pub const IRQ_OFFSET = 0x20;

pub const IrqVecotr = struct {
    pub const IRQ_TIMER = 0;
    pub const IRQ_KBD = 1;
    pub const IRQ_MOUSE = 12;
};

pub const InterruptIndex = struct {
    pub const INT_TIMER = IrqVecotr.IRQ_TIMER + IRQ_OFFSET;
    pub const INT_KBD = IrqVecotr.IRQ_KBD + IRQ_OFFSET;
    pub const INT_MOUSE = IrqVecotr.IRQ_MOUSE + IRQ_OFFSET;
};
