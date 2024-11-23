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

pub fn init() void {
    {
        const response = hhdm.response.?;
        physical_offset = @intCast(response.offset);
    }
    
    const response = mem_map_request.response.?;
    
    for (response.entries()) |entry| {
        if (entry.length >= 1*1024*1024 and entry.kind == .usable and entry.base != 0) {
            const virtual = convert_physical_to_virtual(entry.base);
            alloc.init(@ptrFromInt(virtual), entry.length);
            break;
        }
    }
    
    allocator = alloc.raca_allocator.allocator();
    
}
