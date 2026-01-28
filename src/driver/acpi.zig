const Rsdt = @import("acpi/rsdt.zig").Rsdt;
const limine = @import("../boot/limine.zig");
const std = @import("std");
const mem = @import("../mem.zig");

pub var use_xsdt: bool = undefined;

const Rsdp = packed struct {
    signature: u64,
    checksum: u8,
    oem_id: u48,
    revision: u8,
    rsdt_address: u32,
    length: u32,
    xsdt_address: u64,
    ext_checksum: u8,
    reserved: u24,
};

pub var root_sdt: *align(1) Rsdt = undefined;
export var rsdp_request: limine.RsdpRequest linksection(".limine_requests") = .{};

pub fn init() void {
    const rsdp_address = rsdp_request.response.?.address;
    const rsdp: *align(1) Rsdp = @ptrFromInt(rsdp_address);

    use_xsdt = rsdp.revision != 0;
    const oem_id: [6]u8 = @bitCast(rsdp.oem_id);
    const signature: [8]u8 = @bitCast(rsdp.signature);

    std.log.debug(
        "ACPI RSDP Address 0x{x:0>16} Revision: {} Sig: {s} OEM: {s}",
        .{
            rsdp_address,
            rsdp.revision,
            signature,
            oem_id,
        },
    );

    const xsdt_address = &rsdp.xsdt_address;
    const rsdt_address = &rsdp.rsdt_address;

    const rsdt_addr = mem.convert_physical_to_virtual(if (use_xsdt) xsdt_address.* else rsdt_address.*);
    root_sdt = Rsdt.init(rsdt_addr);
    const ptr_start = std.mem.readInt(u64, @ptrFromInt(rsdt_addr + 36), .little);
    const first = std.mem.readInt(u64, @ptrFromInt(ptr_start), .little);
    std.log.debug(
        "ACPI root sdt at 0x{x:0>16} sig {s} start: 0x{x} start: 0x{x} first: 0x{x}",
        .{
            rsdt_addr,
            root_sdt.sdt_header().sig(),
            root_sdt.ptrs_start,
            ptr_start,
            first,
        },
    );

    const spcr_addr = root_sdt.find_sdt("SPCR") orelse {
        std.log.err("ACPI SPCR not found", .{});
        return;
    };
    std.log.debug("ACPI SPCR Address 0x{x:0>16}", .{@intFromPtr(spcr_addr)});
}
