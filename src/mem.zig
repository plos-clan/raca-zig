const limine = @import("boot/limine.zig");
const KernelAlloc = @import("mem/KernelAlloc.zig");
const Allocator = @import("std").mem.Allocator;

pub const c_alloc = KernelAlloc.c_alloc;

pub export var mem_map_request: limine.MemoryMapRequest = .{};
pub export var hhdm: limine.HhdmRequest = .{};

pub var physical_offset: usize = undefined;

pub fn convert_physical_to_virtual(physical: usize) usize {
    return physical + physical_offset;
}

pub fn convert_virtual_to_physical(virtual: usize) usize {
    return virtual - physical_offset;
}

const heap_size = 8 * 1024 * 1024;

pub fn init() void {
    {
        const response = hhdm.response.?;
        physical_offset = @intCast(response.offset);
    }

    const response = mem_map_request.response.?;
    var initialized = false;

    for (response.entries()) |entry| {
        if (entry.length >= heap_size and entry.kind == .usable and entry.base != 0) {
            const virtual = convert_physical_to_virtual(entry.base);
            KernelAlloc.init_on_boot(@ptrFromInt(virtual), entry.length);
            initialized = true;
            break;
        }
    }
    if (!initialized) {
        @panic("Unable to find a memory region for heap!");
    }
}
