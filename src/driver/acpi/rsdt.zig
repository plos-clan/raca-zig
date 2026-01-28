const use_xsdt = &@import("../acpi.zig").use_xsdt;
const mem = @import("../../mem.zig");
const std = @import("std");
const SdtHeader = @import("sdt.zig").SdtHeader;

pub const Rsdt = packed struct {
    header: SdtHeader,
    ptrs_start: usize,

    const ThisPtr = *align(1) const Rsdt;

    pub fn init(addr: u64) *align(1) @This() {
        return @ptrFromInt(addr);
    }

    pub inline fn sdt_header(self: ThisPtr) SdtHeader {
        return self.header;
    }

    pub inline fn size(self: ThisPtr) u64 {
        const ptr_size: u64 = if (use_xsdt.*) 8 else 4;
        const data_len = self.sdt_header().length - @sizeOf(SdtHeader);
        return data_len / ptr_size;
    }

    inline fn ptr_start(self: ThisPtr) usize {
        std.log.debug("ptr_start: 0x{x:0>16}", .{self.ptrs_start});
        const value = std.mem.readInt(u64, @ptrFromInt(self.ptrs_start), .little);
        std.log.debug("value: 0x{x:0>16}", .{value});
        return self.ptrs_start;
    }

    /// Get virtual address of entry at index
    pub inline fn entry(self: ThisPtr, index: u64) u64 {
        const entry_size: usize = if (use_xsdt.*) 8 else 4;
        const ptr = self.ptr_start() + index * entry_size;
        std.log.debug("ptr: 0x{x:0>16}", .{ptr});

        const u64_ptr: *u64 = @ptrFromInt(ptr);
        const u32_ptr: *u32 = @ptrFromInt(ptr);
        return mem.convert_physical_to_virtual(if (use_xsdt.*) u64_ptr.* else u32_ptr.*);
    }

    pub fn find_sdt(self: ThisPtr, name: []const u8) ?*align(1) anyopaque {
        _ = name;
        std.log.debug("self size: {}", .{self.size()});
        for (0..self.size()) |i| {
            const ptr = self.entry(i);
            std.log.debug("ptr: 0x{x:0>16}", .{ptr});
            const signature_ptr: [*]u8 = @ptrFromInt(ptr);
            const signature = signature_ptr[0..4];
            std.log.debug("signature: {s}", .{signature});
        }
        return null;
    }
};
