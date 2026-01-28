const trap = @import("arch/trap.zig");

pub fn init() void {
    trap.init();
}
