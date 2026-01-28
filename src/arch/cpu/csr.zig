pub const Crmd = Csr(0);
pub const Estat = Csr(5);
pub const Era = Csr(6);
pub const Badv = Csr(7);
pub const Pgdh = Csr(0x1a);
pub const EEntry = Csr(0xc);
pub const Tcfg = Csr(0x41);
pub const Ticlr = Csr(0x44);

pub fn Csr(comptime id: usize) type {
    return struct {
        pub fn read() u64 {
            return asm volatile ("csrrd %[value], %[id]"
                : [value] "=&r" (-> u64),
                : [id] "i" (id),
            );
        }

        pub fn write(value: u64) void {
            asm volatile ("csrwr %[value], %[id]"
                :
                : [value] "r" (value),
                  [id] "i" (id),
            );
        }
    };
}
