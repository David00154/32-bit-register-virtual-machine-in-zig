const std = @import("std");
const meta = std.meta;
const Opcode = @import("./instruction.zig").Opcode;
const log = std.debug.print;
// const Vector = meta.Vector;

pub const Vm = struct {
    const Self = @This();
    registers: [32]i32,
    pc: usize,
    program: std.ArrayList(u8),
    pub fn new(allocator: std.mem.Allocator) Vm {
        return Vm{
            .registers = @splat(32, @as(i32, 0)),
            .pc = 0,
            .program = std.ArrayList(u8).init(allocator),
        };
    }
    /// Loops as long as instructions can be executed.
    pub fn run(self: *Self) !void {
        defer self.program.deinit();
        // var is_done = false;
        // while (!is_done) {
        //     is_done = self.execute_instruction();
        // }
        // try self.program.append(0);

        // std.debug.print("{}\n", .{std.mem.len(self.program.items)});

        while (true) {
            if (self.pc >= std.mem.len(self.program.items)) {
                break;
            }
            switch (self.decode_opcode()) {
                Opcode.LOAD => {
                    var register = @as(usize, self.next_8_bits()); // We cast to usize so we can use it as an index into the array
                    var number = @as(u16, self.next_16_bits());

                    self.registers[register] = @as(i32, number); // Our registers are i32s, so we need to cast it. We'll cover that later.
                    //continue;  Start another iteration of the loop. The next 8 bits waiting to be read should be an opcode.
                    log("LOAD encountered!\n", .{});
                },
                Opcode.HLT => {
                    log("HLT encountered!\n", .{});
                    return;
                },
                else => {
                    log("Unrecognized opcode found! Terminating!\n", .{});
                    return;
                },
            }
        }
    }

    fn decode_opcode(self: *Self) Opcode {
        var opcode = Opcode.fromU8(self.program.items[self.pc]);
        self.pc += 1;
        return opcode;
    }

    fn next_8_bits(self: *Self) u8 {
        const result = self.program.items[self.pc];
        self.pc += 1;
        return result;
    }
    fn next_16_bits(self: *Self) u16 {
        // (@as(u16, self.program.items[self.pc])<< 8)
        const result = @as(u16, self.program.items[self.pc]) << 8 | @as(u16, self.program.items[self.pc + 1]); // 8 bit = (256 == 1 << 8) + / | 8bit
        self.pc += 2;
        return result;
    }
    pub fn run_once(self: *Self) !void {
        _ = self.execute_instruction();
    }
    fn execute_instruction(self: *Self) bool {
        if (self.pc >= std.mem.len(self.program.items)) {
            return false;
        }
        switch (self.decode_opcode()) {
            Opcode.LOAD => {
                var register = @as(usize, self.next_8_bits()); // We cast to usize so we can use it as an index into the array
                var number = @as(u16, self.next_16_bits());

                self.registers[register] = @as(i32, number); // Our registers are i32s, so we need to cast it. We'll cover that later.
                //continue;  Start another iteration of the loop. The next 8 bits waiting to be read should be an opcode.
                log("LOAD encountered!\n", .{});
            },
            Opcode.HLT => {
                log("HLT encountered!\n", .{});
                return false;
            },
            else => {
                log("Unrecognized opcode found! Terminating!\n", .{});
                return false;
            },
        }
        return true;
    }
};

test "create vm" {
    var test_vm: Vm = Vm.new(std.testing.allocator);
    //
    try std.testing.expectEqual(@as(i32, 0), test_vm.registers[0]);
}

test "opcode htl" {
    var test_vm = Vm.new(std.testing.allocator);
    const program = [_]u8{ 5, 0, 0, 0 };
    try test_vm.program.appendSlice(program[0..]);
    try test_vm.run();
    try std.testing.expectEqual(test_vm.pc, 1);
}

test "opcode idl" {
    var test_vm = Vm.new(std.testing.allocator);
    const program = [_]u8{ 200, 0, 0, 0 };
    try test_vm.program.appendSlice(program[0..]);
    try test_vm.run();
    try std.testing.expectEqual(test_vm.pc, 1);
}

test "opcode load" {
    var test_vm = Vm.new(std.testing.allocator);
    const program = [_]u8{ 0, 0, 1, 44 }; // load register <- [number in split 16bit]
    try test_vm.program.appendSlice(program[0..]);
    try test_vm.run();
    try std.testing.expectEqual(test_vm.registers[0], 300);
}
