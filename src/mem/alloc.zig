const std = @import("std");

pub const alloc = struct {
    pub extern fn heap_init(ptr: *const u8, size: usize) bool;
    pub extern fn malloc(size: usize) ?*anyopaque;
    pub extern fn free(ptr: ?*anyopaque) void;
};

const RacaAllocator = struct {
    pub fn new(ptr: *const u8, size: usize) RacaAllocator {
        if (!alloc.heap_init(ptr, size)) {
            @panic("Failed to initialize heap");
        }
        return .{};
    }

    const vtable: std.mem.Allocator.VTable = .{
        .alloc = &allocate_memory,
        .resize = &resize,
        .free = &free_memory,
        .remap = remap,
    };

    pub fn allocator(self: *const RacaAllocator) std.mem.Allocator {
        return .{
            .ptr = @constCast(self),
            .vtable = &vtable,
        };
    }

    fn allocate_memory(ctx: *anyopaque, len: usize, ptr_align: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
        _ = ret_addr;
        _ = ctx;
        _ = ptr_align;
        const ptr = alloc.malloc(len) orelse return null;
        const ptr2: *u8 = @ptrCast(ptr);
        const ptr3: *[1]u8 = ptr2;
        return ptr3;
    }

    fn resize(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
        _ = ret_addr;
        _ = ctx;
        _ = buf_align;
        _ = buf;
        _ = new_len;
        return false;
    }

    fn free_memory(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, ret_addr: usize) void {
        _ = ret_addr;
        _ = ctx;
        _ = buf_align;
        alloc.free(@ptrCast(buf));
    }

    fn remap(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, new_addr: usize, ret_addr: usize) ?[*]u8 {
        _ = ret_addr;
        _ = ctx;
        _ = buf_align;
        _ = new_addr;
        _ = buf;
        return null;
    }
};

pub var raca_allocator: RacaAllocator = undefined;

pub fn init(ptr: *const u8, size: usize) void {
    raca_allocator = RacaAllocator.new(ptr, size);
}
