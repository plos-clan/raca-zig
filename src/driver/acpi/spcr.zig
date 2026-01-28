const SdtHeader = @import("sdt.zig").SdtHeader;
const GenericAddr = @import("generic_addr.zig").GenericAddr;

pub const Spcr = packed struct {
    header: SdtHeader,
    interface_type: u8,
    reserved: [3]u8,
    base_addr: GenericAddr,

    pub fn init(addr: *anyopaque) *@This() {
        return @ptrCast(addr);
    }
};
