const std = @import("std");

pub const alloc = struct {
    pub const enum_HeapError = c_uint;
    pub const HeapError = enum_HeapError;
    pub const ErrorHandler = ?*const fn (enum_HeapError, ?*anyopaque) callconv(.c) void;
    pub extern fn heap_init(address: [*c]u8, size: usize) bool;
    pub extern fn heap_extend(address: [*c]u8, size: usize) bool;
    pub extern fn heap_onerror(handler: ErrorHandler) void;
    pub extern fn usable_size(ptr: ?*anyopaque) usize;
    pub extern fn malloc(size: c_ulong) ?*anyopaque;
    pub extern fn calloc(nmemb: c_ulong, size: c_ulong) ?*anyopaque;
    pub extern fn aligned_alloc(alignment: c_ulong, size: c_ulong) ?*anyopaque;
    pub extern fn free(ptr: ?*anyopaque) void;
    pub extern fn realloc(ptr: ?*anyopaque, size: c_ulong) ?*anyopaque;
};

const RacaAllocator = struct {
    pub fn new(ptr: *const u8, size: usize) RacaAllocator {
        if (!alloc.heap_init(@constCast(ptr), size)) {
            @panic("Failed to initialize heap");
        }
        alloc.heap_onerror(error_handler);
        return .{};
    }

    fn error_handler(err: alloc.HeapError, ptr: ?*anyopaque) callconv(.c) void {
        std.log.debug("Error {} at 0x{x:0>16}", .{ err, @intFromPtr(ptr) });
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
        const ptr = alloc.aligned_alloc(std.math.pow(u64, 2, @intFromEnum(ptr_align)), len) orelse return null;
        return @ptrCast(ptr);
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
