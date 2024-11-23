const gdt = @import("arch/gdt.zig");
const idt = @import("arch/idt.zig");

pub fn init() void {
    gdt.init();
    idt.init();
}
