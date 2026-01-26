pub const ptrdiff_t = c_long;
pub const TerminalDisplay = extern struct {
    width: usize,
    height: usize,
    buffer: [*c]u32,
    pitch: usize,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
};
pub const TerminalPalette = extern struct {
    foreground: u32,
    background: u32,
    ansi_colors: [16]u32,
};
const malloc = ?*const fn (usize) callconv(.c) ?*anyopaque;
const free = ?*const fn (?*anyopaque) callconv(.c) void;
pub extern fn terminal_new(display: [*c]const TerminalDisplay, font_size: f32, malloc: malloc, free: free) ?*anyopaque;
pub extern fn terminal_destroy(terminal: ?*anyopaque) void;
pub extern fn terminal_flush(terminal: ?*anyopaque) void;
pub extern fn terminal_process(terminal: ?*anyopaque, s: [*c]const u8) void;
pub extern fn terminal_process_byte(terminal: ?*anyopaque, c: u8) void;
pub extern fn terminal_handle_keyboard(terminal: ?*anyopaque, scancode: u8) void;
pub extern fn terminal_handle_mouse_scroll(terminal: ?*anyopaque, delta: ptrdiff_t) void;
pub extern fn terminal_set_history_size(terminal: ?*anyopaque, size: usize) void;
pub extern fn terminal_set_color_cache_size(terminal: ?*anyopaque, size: usize) void;
pub extern fn terminal_set_scroll_speed(terminal: ?*anyopaque, speed: usize) void;
pub extern fn terminal_set_auto_flush(terminal: ?*anyopaque, auto_flush: bool) void;
pub extern fn terminal_set_crnl_mapping(terminal: ?*anyopaque, auto_crnl: bool) void;
pub extern fn terminal_set_custom_color_scheme(terminal: ?*anyopaque, palette: [*c]const TerminalPalette) void;
pub extern fn terminal_set_pty_writer(terminal: ?*anyopaque, writer: ?*const fn ([*c]const u8, usize) callconv(.c) void) void;
pub extern fn terminal_set_clipboard(terminal: ?*anyopaque, get_fn: ?*const fn () callconv(.c) [*c]const u8, set_fn: ?*const fn ([*c]const u8) callconv(.c) void) void;
pub extern fn terminal_set_color_scheme(terminal: ?*anyopaque, palette_index: usize) void;
pub extern fn terminal_set_bell_handler(terminal: ?*anyopaque, handler: ?*const fn () callconv(.c) void) void;
