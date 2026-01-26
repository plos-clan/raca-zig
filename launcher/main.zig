const std = @import("std");

pub fn main() void {
    const cwd = std.fs.cwd();

    //const zig_out = cwd.openDir("zig-out", .{}) catch unreachable;
    //const zig_out_bin = zig_out.openDir("bin", .{}) catch unreachable;

    const esp = cwd.openDir("esp", .{}) catch unreachable;

    cwd.copyFile("zig-out/bin/raca", esp, "core.sys", .{}) catch unreachable;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    std.process.execv(allocator, &.{
        "qemu-system-loongarch64",
        "-m",
        "1G",
        "-drive",
        "if=none,format=raw,id=disk,file=fat:rw:esp",
        "-device",
        "ahci,id=ahci0",
        "-device",
        "ide-hd,drive=disk,bus=ahci0.0",
        "-pflash",
        "ovmf-code.fd",
        "-net",
        "none",
        "-serial",
        "stdio",
        "-cpu",
        "la464",
        "-machine",
        "virt",
        "-device",
        "VGA,vgamem_mb=64",
    }) catch unreachable;
}
