const limine = @import("boot.zig").limine;
const alloc = @import("mem/alloc.zig");
const Allocator = @import("std").mem.Allocator;

pub const c_alloc = alloc.alloc;
pub var allocator: Allocator = undefined;

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
        const response = hhdm.response orelse {
            return;
        };
        physical_offset = @intCast(response.offset);
    }

    const response = mem_map_request.response.?;
    var initialized = false;

    for (response.entries()) |entry| {
        if (entry.length >= heap_size and entry.kind == .usable and entry.base != 0) {
            const virtual = convert_physical_to_virtual(entry.base);
            alloc.init(@ptrFromInt(virtual), entry.length);
            initialized = true;
            break;
        }
    }
    if (!initialized) {
        return;
    }

    allocator = alloc.raca_allocator.allocator();
}

fn stop() noreturn {
    while (true) {}
}
