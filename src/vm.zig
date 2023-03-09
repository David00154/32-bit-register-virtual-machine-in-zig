const std = @import("std");
const meta = std.meta;
const Opcode = @import("./instruction.zig").Opcode;
const print = std.debug.print;
// const Vector = meta.Vector;
pub const Vm = struct {
    const Self = @This();
    registers: [32]i32,
    pc: usize,
    program: std.ArrayList(u8),
    remainder: u32,
    equal_tag: bool,
    pub fn new(allocator: std.mem.Allocator) Vm {
        return Vm{
            .registers = @splat(32, @as(i32, 0)),
            .pc = 0,
            .program = std.ArrayList(u8).init(allocator),
            .remainder = 0,
            .equal_tag = false,
        };
    }
    /// Loops as long as instructions can be executed.
    pub fn run(self: *Self) !void {
        defer self.program.deinit();
        var is_done = false;
        while (!is_done) {
            is_done = self.execute_instruction();
        }
        // try self.program.append(0);

        // std.debug.print("{}\n", .{std.mem.len(self.program.items)});

    }

    fn decode_opcode(self: *Self) Opcode {
        // var opcode = @intToEnum(Opcode, self.program.items[self.pc]);
        var opcode = Opcode.intToEnum(self.program.items[self.pc]);

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
    pub fn run_once(self: *Self) void {
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
                print("LOAD encountered!\n", .{});
            },
            Opcode.ADD => {
                var register1 = self.registers[@as(usize, self.next_8_bits())];
                var register2 = self.registers[@as(usize, self.next_8_bits())];
                self.registers[@as(usize, self.next_8_bits())] = register1 + register2;
                print("ADD encountered!\n", .{});
            },
            Opcode.SUB => {
                var register1 = self.registers[@as(usize, self.next_8_bits())];
                var register2 = self.registers[@as(usize, self.next_8_bits())];
                self.registers[@as(usize, self.next_8_bits())] = register1 - register2;
                print("SUB encountered!\n", .{});
            },
            Opcode.MUL => {
                var register1 = self.registers[@as(usize, self.next_8_bits())];
                var register2 = self.registers[@as(usize, self.next_8_bits())];
                self.registers[@as(usize, self.next_8_bits())] = register1 * register2;
                print("MUL encountered!\n", .{});
            },
            Opcode.DIV => {
                var register1 = self.registers[@intCast(usize, self.next_8_bits())];
                var register2 = self.registers[@intCast(usize, self.next_8_bits())];
                self.registers[@intCast(usize, self.next_8_bits())] = @divFloor(register1, register2);
                self.remainder = @intCast(u32, @mod(register1, register2));
                print("DIV encountered!\n", .{});
            },
            Opcode.HLT => {
                print("HLT encountered!\n", .{});
                return false;
            },
            Opcode.JMP => {
                const target = self.registers[@intCast(usize, self.next_8_bits())];
                self.pc = @intCast(usize, target);
                print("JMP encountered!\n", .{});
            },
            Opcode.JMPF => {
                const target = self.registers[@intCast(usize, self.next_8_bits())];
                self.pc += @intCast(usize, target);
                print("JMPF encountered!\n", .{});
            },
            Opcode.JMPB => {
                const target = self.registers[@intCast(usize, self.next_8_bits())];
                self.pc -= @intCast(usize, target);
                print("JMPB encountered!\n", .{});
            },
            Opcode.EQ => {
                const register1 = self.registers[@intCast(usize, self.next_8_bits())];
                const register2 = self.registers[@intCast(usize, self.next_8_bits())];
                self.equal_tag = register1 == register2;
                _ = self.next_8_bits();
                print("EQ encountered!\n", .{});
            },
            Opcode.NEQ => {
                const register1 = self.registers[@intCast(usize, self.next_8_bits())];
                const register2 = self.registers[@intCast(usize, self.next_8_bits())];
                self.equal_tag = register1 != register2;
                _ = self.next_8_bits();
                print("NEQ encountered!\n", .{});
            },
            Opcode.GTE => {
                const register1 = self.registers[@intCast(usize, self.next_8_bits())];
                const register2 = self.registers[@intCast(usize, self.next_8_bits())];
                self.equal_tag = register1 >= register2;
                _ = self.next_8_bits();
                print("GTE encountered!\n", .{});
            },
            Opcode.LTE => {
                const register1 = self.registers[@intCast(usize, self.next_8_bits())];
                const register2 = self.registers[@intCast(usize, self.next_8_bits())];
                self.equal_tag = register1 <= register2;
                _ = self.next_8_bits();
                print("LTE encountered!\n", .{});
            },
            Opcode.LT => {
                const register1 = self.registers[@intCast(usize, self.next_8_bits())];
                const register2 = self.registers[@intCast(usize, self.next_8_bits())];
                self.equal_tag = register1 < register2;
                _ = self.next_8_bits();
                print("LT encountered!\n", .{});
            },
            Opcode.GT => {
                const register1 = self.registers[@intCast(usize, self.next_8_bits())];
                const register2 = self.registers[@intCast(usize, self.next_8_bits())];
                self.equal_tag = register1 > register2;
                _ = self.next_8_bits();
                print("GT encountered!\n", .{});
            },
            Opcode.JMPE => {
                const register = @intCast(usize, self.next_8_bits());
                const target = self.registers[register];
                if (self.equal_tag) {
                    self.pc = @intCast(usize, target);
                }
                print("JMPE encountered!\n", .{});
            },
            Opcode.IGL => {
                print("Unrecognized opcode found! Terminating!\n", .{});
                return false;
            },
        }
        return true;
    }
};

// TESTS

test "create vm" {
    var test_vm: Vm = Vm.new(std.testing.allocator);
    //
    try std.testing.expectEqual(@as(i32, 0), test_vm.registers[0]);
}

test "opcode hlt" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    const program = [_]u8{
        5, 0, 0, 0, //
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.pc, 1);
}

test "opcode igl" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    const program = [_]u8{
        200, 0, 0, 0, //
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.pc, 1);
}

test "opcode load" {
    var test_vm = Vm.new(std.testing.allocator);
    const program = [_]u8{
        0, 0, 1, 44, //
    }; // load register <- [number in split 16bit]
    try test_vm.program.appendSlice(program[0..]);
    try test_vm.run();
    try std.testing.expectEqual(test_vm.registers[0], 300);
}

test "opcode add" {
    var test_vm = Vm.new(std.testing.allocator);
    test_vm.registers[0] = 4;
    test_vm.registers[1] = 4;
    var program = [_]u8{
        1, 0, 1, 2, //
    };
    try test_vm.program.appendSlice(program[0..]);
    try test_vm.run();
    try std.testing.expectEqual(test_vm.registers[2], 8);
}
test "opcode sub" {
    var test_vm = Vm.new(std.testing.allocator);
    test_vm.registers[0] = 4;
    test_vm.registers[1] = 2;
    var program = [_]u8{
        2, 0, 1, 2, //
    };
    try test_vm.program.appendSlice(program[0..]);
    try test_vm.run();
    try std.testing.expectEqual(test_vm.registers[2], 2);
}
test "opcode mul" {
    var test_vm = Vm.new(std.testing.allocator);
    test_vm.registers[0] = 4;
    test_vm.registers[1] = 2;
    var program = [_]u8{
        3, 0, 1, 2, //
    };
    try test_vm.program.appendSlice(program[0..]);
    try test_vm.run();
    try std.testing.expectEqual(test_vm.registers[2], 8);
}
test "opcode div" {
    var test_vm = Vm.new(std.testing.allocator);
    test_vm.registers[0] = 20;
    test_vm.registers[1] = 7;
    var program = [_]u8{
        4, 0, 1, 2, //
    };
    try test_vm.program.appendSlice(program[0..]);
    try test_vm.run();
    try std.testing.expectEqual(test_vm.registers[2], 2);
}

test "opcode jmp" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    test_vm.registers[0] = 1;
    var program = [_]u8{
        6, 0, 0, 0, //
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.pc, 1);
}
test "opcode jmpf" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    test_vm.registers[0] = 2;
    test_vm.registers[1] = 2;
    test_vm.registers[2] = 4;
    var program = [_]u8{
        7, 0, 0, 0, //
        1, 1, 2, 20,
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.pc, 4);
}

test "opcode jmpb" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    var program = [_]u8{
        0, 0, 0, 6, //
        0, 0, 0, 2,
        8, 0, 0, 0,
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once(); // 4
    test_vm.run_once(); // 8
    test_vm.run_once(); // 8
    try std.testing.expectEqual(test_vm.pc, 8);
}

test "opcode eq" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    var program = [_]u8{
        0, 0, 0, 10,
        0, 1, 0, 10,
        9, 0, 1, 0,
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.equal_tag, true);
    var program2 = [_]u8{
        0, 0, 0, 20, //
        9, 0, 1, 0,
    };
    try test_vm.program.appendSlice(program2[0..]);
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.equal_tag, false);
}

test "opcode neq" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    var program = [_]u8{
        0,  0, 0, 1, //
        0,  1, 0, 2,
        10, 0, 1, 0,
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.equal_tag, true);
    var program2 = [_]u8{
        0,  0, 0, 2, //
        10, 0, 1, 0,
    };
    try test_vm.program.appendSlice(program2[0..]);
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.equal_tag, false);
}

test "opcode gte" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    var program = [_]u8{
        0,  0, 0, 10, //
        0,  1, 0, 2,
        11, 0, 1, 0,
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.equal_tag, true);
    var program2 = [_]u8{
        0,  0, 0, 2, //
        11, 0, 1, 0,
    };
    try test_vm.program.appendSlice(program2[0..]);
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.equal_tag, true);
}
test "opcode lte" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    var program = [_]u8{
        0,  0, 0, 5, //
        0,  1, 0, 3,
        12, 1, 0, 0,
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.equal_tag, true);
    var program2 = [_]u8{
        0,  0, 0, 2, //
        12, 1, 0, 0,
    };
    try test_vm.program.appendSlice(program2[0..]);
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.equal_tag, false);
}
test "opcode lt" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    var program = [_]u8{
        0,  0, 0, 4, //
        0,  1, 0, 12,
        13, 0, 1, 0,
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.equal_tag, true);
}
test "opcode gt" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    var program = [_]u8{
        0,  0, 0, 8, //
        0,  1, 0, 6,
        14, 0, 1, 0,
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.equal_tag, true);
}

test "opcode jmpe" {
    var test_vm = Vm.new(std.testing.allocator);
    defer test_vm.program.deinit();
    var program = [_]u8{
        0,  0, 0, 8, //
        0,  1, 0, 8,
        9,  0, 1, 0,
        15, 1, 0, 0,
    };
    try test_vm.program.appendSlice(program[0..]);
    test_vm.run_once();
    test_vm.run_once();
    test_vm.run_once();
    test_vm.run_once();
    try std.testing.expectEqual(test_vm.pc, 8);
}
