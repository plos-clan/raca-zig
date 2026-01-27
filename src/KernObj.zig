const std = @import("std");
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;
const Atomic = std.atomic.Value;

ptr: [*]u8,
size: usize,
ty: [*]const u8,
alignment: Alignment,

count: *Atomic(usize),

pub fn init(comptime T: anytype, value: T, allocator: Allocator) !@This() {
    const ptr = try allocator.create(T);
    const count = try allocator.create(Atomic(usize));
    count.*.store(1, .unordered);
    ptr.* = value;
    return .{
        .ptr = @ptrCast(ptr),
        .size = @sizeOf(T),
        .ty = @typeName(T),
        .alignment = Alignment.of(T),
        .count = count,
    };
}

pub fn deinit(self: *const @This(), allocator: Allocator) void {
    if (self.count.fetchSub(1, .seq_cst) == 1) {
        allocator.rawFree(self.ptr[0..self.size], self.alignment, 0);
        allocator.destroy(self.count);
    }
}

pub fn downcast_const(self: *const @This(), comptime T: type) !*const T {
    if (self.ty != @typeName(T)) return error.TypeMismatch;
    return @ptrCast(@alignCast(self.ptr));
}

pub fn downcast_mut(self: *const @This(), comptime T: type) !*T {
    if (self.ty != @typeName(T)) return error.TypeMismatch;
    return @ptrCast(self.ptr);
}

pub fn ref_count(self: *const @This()) usize {
    return self.count.load(.seq_cst);
}

pub fn clone(self: *const @This()) !@This() {
    _ = self.count.fetchAdd(1, .seq_cst);
    return .{
        .ptr = self.ptr,
        .size = self.size,
        .ty = self.ty,
        .alignment = self.alignment,
        .count = self.count,
    };
}

test "create kernel obj" {
    const allocator = std.testing.allocator;
    const obj = try init(i32, 42, allocator);
    defer obj.deinit(allocator);
    try std.testing.expectEqual(obj.ty, "i32");
}

test "downcast kernel obj" {
    const allocator = std.testing.allocator;
    const obj = try init(i32, 42, allocator);
    defer obj.deinit(allocator);
    const i32_ptr = try obj.downcast_const(i32);
    try std.testing.expectEqual(i32_ptr.*, 42);
}

test "clone kernel obj" {
    const allocator = std.testing.allocator;
    const obj = try init(i32, 42, allocator);
    defer obj.deinit(allocator);
    const cloned_obj = try obj.clone();
    defer cloned_obj.deinit(allocator);
    try std.testing.expectEqual(cloned_obj.ty, "i32");
}
