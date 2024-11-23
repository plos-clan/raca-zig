const std = @import("std");

pub fn main() void {
    const cwd = std.fs.cwd();

    //const zig_out = cwd.openDir("zig-out", .{}) catch unreachable;
    //const zig_out_bin = zig_out.openDir("bin", .{}) catch unreachable;

    const esp = cwd.openDir("esp", .{}) catch unreachable;

    cwd.copyFile("zig-out/bin/racaOS", esp, "core.sys", .{}) catch unreachable;
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    std.process.execv(allocator, &.{
        "qemu-system-x86_64",
        "-m", "512M",
        "-drive", "file=fat:rw:esp,format=raw",
        "-pflash","ovmf-code.fd",
        "-net","none",
        "-serial","stdio",
        "-enable-kvm",
        "-cpu","qemu64,+x2apic",
    }) catch unreachable;
}
