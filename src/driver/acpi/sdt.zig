pub const SdtHeader = packed struct(u288) {
    signature: u32,
    length: u32,
    revision: u8,
    checksum: u8,
    oem_id: u48,
    oem_table_id: u64,
    oem_revision: u32,
    creator_id: u32,
    creator_revision: u32,

    pub inline fn sig(self: *align(1) const @This()) [4]u8 {
        return @bitCast(self.signature);
    }
};
