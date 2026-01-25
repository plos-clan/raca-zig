const std = @import("std");

const HeapError = enum(c_int) {
    InvalidFree = 0,
    LayoutError = 1,
};

const ErrorHandler = ?*const fn (err: HeapError, ptr: ?*anyopaque) callconv(.c) void;

pub const alloc = struct {
    pub extern fn heap_init(ptr: *const u8, size: usize) bool;
    pub extern fn malloc(size: usize) ?*anyopaque;
    pub extern fn aligned_alloc(alignment: usize, size: usize) ?*anyopaque;
    pub extern fn free(ptr: ?*anyopaque) void;
    pub extern fn heap_onerror(err_handler: ErrorHandler) void;
};

const RacaAllocator = struct {
    pub fn new(ptr: *const u8, size: usize) RacaAllocator {
        if (!alloc.heap_init(ptr, size)) {
            @panic("Failed to initialize heap");
        }
        alloc.heap_onerror(error_handler);
        return .{};
    }

    fn error_handler(err: HeapError, ptr: ?*anyopaque) callconv(.c) void {
        std.log.debug("Error at 0x{x:0>16}", .{@intFromPtr(ptr)});
        switch (err) {
            HeapError.InvalidFree => @panic("Invalid free"),
            HeapError.LayoutError => @panic("Layout error"),
        }
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
        const ptr = alloc.aligned_alloc(@intFromEnum(ptr_align), len) orelse return null;
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
