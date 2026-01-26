pos_x: u64 = 0,
pos_y: u64 = 0,
color: u32 = 0xFFFFFF,
font: Font,
buffer: Buffer,

const font_data = @embedFile("terminal/VGA8.F16");

pub fn init(buffer: Buffer, font: Font) @This() {
    return .{
        .buffer = buffer,
        .font = font,
    };
}

pub fn print_str(self: *@This(), str: []const u8) void {
    for (str) |char| {
        self.write_byte(char);
    }
}

fn rend(self: *@This(), char: u8, x: u64, y: u64) void {
    const width = self.font.width;
    const height = self.font.height;
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
            const value = self.font.data[char_start + row] & @as(u16, 1) << (8 - col);
            if (value != 0) self.buffer.write_pixel(x + col, y + row, self.color);
        }
    }
}

pub fn set_color(self: *@This(), color: u32) void {
    self.color = color;
}

pub fn new_line(self: *@This()) void {
    self.pos_x = 0;
    self.pos_y += self.font.height;
}

pub fn roll_screen(self: *@This()) void {
    const font_height = self.font.height;
    const width = self.buffer.width;
    const height = self.buffer.height;

    for (0..width) |x| {
        for (0..(height - font_height)) |y| {
            const pixel = self.buffer.read_pixel(x, y + font_height);
            self.buffer.write_pixel(x, y, pixel);
        }
    }

    self.pos_x = 0;
    self.pos_y = height - font_height;
}

pub fn write_byte(self: *@This(), byte: u8) void {
    const font_width = self.font.width;
    const font_height = self.font.height;
    const width = self.buffer.width;
    const height = self.buffer.height;

    if (self.pos_x > width - font_width) {
        self.new_line();
    }
    if (self.pos_y > height - font_height) {
        self.roll_screen();
    }

    switch (byte) {
        '\n' => self.new_line(),
        else => {
            self.rend(byte, self.pos_x, self.pos_y);
            self.pos_x += font_width;
        },
    }
}

pub const Buffer = struct {
    ptr: [*]volatile u32,
    width: u64,
    height: u64,

    pub fn init(
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

pub const Font = struct {
    width: u64,
    height: u64,
    data: [*]const u8,

    pub fn init(width: u64, height: u64, data: [*]const u8) Font {
        return Font{
            .width = width,
            .height = height,
            .data = data,
        };
    }

    pub fn default() @This() {
        return .{
            .width = 8,
            .height = 16,
            .data = font_data,
        };
    }
};
