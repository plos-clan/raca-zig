const limine = @import("../boot/limine.zig");
const alloc = @import("../mem.zig").c_alloc;
const font = @import("terminal/font.zig");

pub export var framebuffer_request: limine.FramebufferRequest = .{};
pub var terminal: Terminal = undefined;

pub fn init() void {
    const framebuffer = framebuffer_request.response.?.framebuffers()[0];

    const buffer = Buffer.new(@ptrCast(@alignCast(framebuffer.address)), framebuffer.width, framebuffer.height);
    const render = font.FontRender.new(buffer, &font.font_data, 8, 16);
    terminal = Terminal.new(render);
}

pub fn print_str(str: []const u8) void {
    for (str) |byte| {
        terminal.write_byte(byte);
    }
}

const Terminal = struct {
    render: FontRender,
    pos_x: u64 = 0,
    pos_y: u64 = 0,

    const Self = @This();

    pub fn new(render: FontRender) Self {
        return Self{
            .render = render,
        };
    }

    pub fn new_line(self: *Self) void {
        self.pos_x = 0;
        self.pos_y += self.render.font_height;
    }

    pub fn roll_screen(self: *Self) void {
        const font_height = self.render.font_height;
        const width = self.render.buffer.width;
        const height = self.render.buffer.height;

        for (0..width) |x| {
            for (0..(height - font_height)) |y| {
                const pixel = self.render.buffer.read_pixel(x, y + font_height);
                self.render.buffer.write_pixel(x, y, pixel);
            }
        }

        self.pos_x = 0;
        self.pos_y = height - font_height;
    }

    pub fn write_byte(self: *Self, byte: u8) void {
        const font_width = self.render.font_width;
        const font_height = self.render.font_height;
        const width = self.render.buffer.width;
        const height = self.render.buffer.height;

        if (self.pos_x > width - font_width) {
            self.new_line();
        }
        if (self.pos_y > height - font_height) {
            self.roll_screen();
        }

        switch (byte) {
            '\n' => self.new_line(),
            else => {
                self.render.rend(byte, self.pos_x, self.pos_y);
                self.pos_x += font_width;
            },
        }
    }
};

const Buffer = struct {
    ptr: [*]volatile u32,
    width: u64,
    height: u64,

    pub fn new(
        ptr: [*]volatile u32,
        width: u64,
        height: u64,
    ) Buffer {
        return Buffer{
            .ptr = ptr,
            .width = width,
            .height = height,
        };
    }

    pub fn write_pixel(self: *Buffer, x: u64, y: u64, pixel: u32) void {
        const pos = self.width * y + x;

        self.ptr[pos] = pixel;
    }

    pub fn read_pixel(self: *Buffer, x: u64, y: u64) u32 {
        const pos = self.width * y + x;

        return self.ptr[pos];
    }
};

const FontRender = struct {
    buffer: Buffer,
    font: [*]const u8,
    font_width: u64,
    font_height: u64,
    color: u32 = 0xffffffff,

    const Self = @This();

    pub fn new(buffer: Buffer, font_buf: [*]const u8, font_width: u64, font_height: u64) Self {
        return Self{
            .buffer = buffer,
            .font = font_buf,
            .font_width = font_width,
            .font_height = font_height,
        };
    }

    pub fn rend(self: *Self, char: u8, x: u64, y: u64) void {
        const width = self.font_width;
        const height = self.font_height;
        if (width > 16) {
            @panic("[Log.rend] Fonts wider than 16 pixels are illegal as of now! \n");
        }

        const multiplicator: u2 = if (width > 8) 2 else 1;
        const char_start = char * height * multiplicator;

        var col: u4 = 0;
        var row: u8 = 0;

        while (row < height) : ({
            row += 1;
            col = 0;
        }) {
            while (col < width) : (col += 1) {
                const value = self.font[char_start + row] & @as(u16, 1) << (8 - col);
                if (value != 0) self.buffer.write_pixel(x + col, y + row, self.color);
            }
        }
    }

    pub fn set_color(self: *Self, color: u32) void {
        self.color = color;
    }
};
