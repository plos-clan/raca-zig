const csr = @import("cpu/csr.zig");
const std = @import("std");

pub fn init() void {
    csr.EEntry.write(@intFromPtr(&trapHandler));
}

fn trapHandler() void {
    const estat = csr.Estat.read();
    const ecode = (estat >> 16) & 0x3f;
    const esubcode = estat >> 22;

    if (ecode != 0) {
        const era = csr.Era.read();
        const badv = csr.Badv.read();

        std.log.err("Unhandled exception! Ecode: {}", .{ecode});
        std.log.err("ESUBCODE: {x}, ERA: {x}, BADV: {x}", .{ esubcode, era, badv });

        while (true) {}
    }
}
