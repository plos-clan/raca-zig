pub const max_align_t = extern struct {
    __clang_max_align_nonce1: c_longlong align(8) = @import("std").mem.zeroes(c_longlong),
    __clang_max_align_nonce2: c_longdouble align(16) = @import("std").mem.zeroes(c_longdouble),
};
pub const struct_TerminalPalette = extern struct {
    foreground: u32 = @import("std").mem.zeroes(u32),
    background: u32 = @import("std").mem.zeroes(u32),
    ansi_colors: [16]u32 = @import("std").mem.zeroes([16]u32),
};
pub const TerminalPalette = struct_TerminalPalette;
pub extern fn terminal_init(width: usize, height: usize, screen: [*]u8, font_size: f32, malloc: ?*const fn (usize) callconv(.C) ?*anyopaque, free: ?*const fn (?*anyopaque) callconv(.C) void, serial_print: ?*const fn ([*c]const u8) void) bool;
pub extern fn terminal_destroy() void;
pub extern fn terminal_flush() void;
pub extern fn terminal_set_auto_flush(auto_flush: usize) void;
pub extern fn terminal_advance_state(s: [*]const u8) void;
pub extern fn terminal_advance_state_single(c: u8) void;
pub extern fn terminal_set_color_scheme(palette_index: usize) void;
pub extern fn terminal_set_custom_color_scheme(palette: struct_TerminalPalette) void;
pub extern fn terminal_handle_keyboard(scancode: u8, buffer: [*]u8) bool;
