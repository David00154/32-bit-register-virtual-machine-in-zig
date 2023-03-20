const std = @import("std");
const meta = std.meta;
const Opcode = @import("./instruction.zig").Opcode;
const print = std.debug.print;
// const Vector = meta.Vector;
pub const VM = struct {
    const Self = @This();
    registers: [32]i32,
    pc: usize,
    program: std.ArrayList(u8),
    remainder: u32,
    equal_tag: bool,
    pub fn new(allocator: std.mem.Allocator) VM {
        return VM{
            .registers = @splat(32, @intCast(i32, 0)),
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
        // (@intCast(u16, self.program.items[self.pc])<< 8)
        const result = @intCast(u16, self.program.items[self.pc]) << 8 | @intCast(u16, self.program.items[self.pc + 1]); // 8 bit = (256 == 1 << 8) + / | 8bit
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
                var register = @intCast(usize, self.next_8_bits()); // We cast to usize so we can use it as an index into the array
                var number = @intCast(u16, self.next_16_bits());

                self.registers[register] = @intCast(i32, number); // Our registers are i32s, so we need to cast it. We'll cover that later.
                //continue;  Start another iteration of the loop. The next 8 bits waiting to be read should be an opcode.
                print("LOAD encountered!\n", .{});
            },
            Opcode.ADD => {
                var register1 = self.registers[@intCast(usize, self.next_8_bits())];
                var register2 = self.registers[@intCast(usize, self.next_8_bits())];
                self.registers[@intCast(usize, self.next_8_bits())] = register2 + register1;
                print("ADD encountered!\n", .{});
            },
            Opcode.SUB => {
                var register1 = self.registers[@intCast(usize, self.next_8_bits())];
                var register2 = self.registers[@intCast(usize, self.next_8_bits())];
                self.registers[@intCast(usize, self.next_8_bits())] = register2 - register1;
                print("SUB encountered!\n", .{});
            },
            Opcode.MUL => {
                var register1 = self.registers[@intCast(usize, self.next_8_bits())];
                var register2 = self.registers[@intCast(usize, self.next_8_bits())];
                self.registers[@intCast(usize, self.next_8_bits())] = register2 * register1;
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

test "create VM" {
    var test_VM: VM = VM.new(std.testing.allocator);
    //
    try std.testing.expectEqual(@intCast(i32, 0), test_VM.registers[0]);
}

test "opcode hlt" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    const program = [_]u8{
        5, 0, 0, 0, //
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.pc, 1);
}

test "opcode igl" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    const program = [_]u8{
        200, 0, 0, 0, //
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.pc, 1);
}

test "opcode load" {
    var test_VM = VM.new(std.testing.allocator);
    const program = [_]u8{
        0, 0, 1, 44, //
    }; // load register <- [number in split 16bit]
    try test_VM.program.appendSlice(program[0..]);
    try test_VM.run();
    try std.testing.expectEqual(test_VM.registers[0], 300);
}

test "opcode add" {
    var test_VM = VM.new(std.testing.allocator);
    test_VM.registers[0] = 4;
    test_VM.registers[1] = 4;
    var program = [_]u8{
        1, 0, 1, 2, //
    };
    try test_VM.program.appendSlice(program[0..]);
    try test_VM.run();
    try std.testing.expectEqual(test_VM.registers[2], 8);
}
test "opcode sub" {
    var test_VM = VM.new(std.testing.allocator);
    test_VM.registers[0] = 4;
    test_VM.registers[1] = 2;
    var program = [_]u8{
        2, 0, 1, 2, //
    };
    try test_VM.program.appendSlice(program[0..]);
    try test_VM.run();
    try std.testing.expectEqual(test_VM.registers[2], 2);
}
test "opcode mul" {
    var test_VM = VM.new(std.testing.allocator);
    test_VM.registers[0] = 4;
    test_VM.registers[1] = 2;
    var program = [_]u8{
        3, 0, 1, 2, //
    };
    try test_VM.program.appendSlice(program[0..]);
    try test_VM.run();
    try std.testing.expectEqual(test_VM.registers[2], 8);
}
test "opcode div" {
    var test_VM = VM.new(std.testing.allocator);
    test_VM.registers[0] = 20;
    test_VM.registers[1] = 7;
    var program = [_]u8{
        4, 0, 1, 2, //
    };
    try test_VM.program.appendSlice(program[0..]);
    try test_VM.run();
    try std.testing.expectEqual(test_VM.registers[2], 2);
}

test "opcode jmp" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    test_VM.registers[0] = 1;
    var program = [_]u8{
        6, 0, 0, 0, //
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.pc, 1);
}
test "opcode jmpf" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    test_VM.registers[0] = 2;
    test_VM.registers[1] = 2;
    test_VM.registers[2] = 4;
    var program = [_]u8{
        7, 0, 0, 0, //
        1, 1, 2, 20,
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.pc, 4);
}

test "opcode jmpb" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    var program = [_]u8{
        0, 0, 0, 6, //
        0, 0, 0, 2,
        8, 0, 0, 0,
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once(); // 4
    test_VM.run_once(); // 8
    test_VM.run_once(); // 8
    try std.testing.expectEqual(test_VM.pc, 8);
}

test "opcode eq" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    var program = [_]u8{
        0, 0, 0, 10,
        0, 1, 0, 10,
        9, 0, 1, 0,
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.equal_tag, true);
    var program2 = [_]u8{
        0, 0, 0, 20, //
        9, 0, 1, 0,
    };
    try test_VM.program.appendSlice(program2[0..]);
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.equal_tag, false);
}

test "opcode neq" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    var program = [_]u8{
        0,  0, 0, 1, //
        0,  1, 0, 2,
        10, 0, 1, 0,
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.equal_tag, true);
    var program2 = [_]u8{
        0,  0, 0, 2, //
        10, 0, 1, 0,
    };
    try test_VM.program.appendSlice(program2[0..]);
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.equal_tag, false);
}

test "opcode gte" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    var program = [_]u8{
        0,  0, 0, 10, //
        0,  1, 0, 2,
        11, 0, 1, 0,
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.equal_tag, true);
    var program2 = [_]u8{
        0,  0, 0, 2, //
        11, 0, 1, 0,
    };
    try test_VM.program.appendSlice(program2[0..]);
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.equal_tag, true);
}
test "opcode lte" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    var program = [_]u8{
        0,  0, 0, 5, //
        0,  1, 0, 3,
        12, 1, 0, 0,
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.equal_tag, true);
    var program2 = [_]u8{
        0,  0, 0, 2, //
        12, 1, 0, 0,
    };
    try test_VM.program.appendSlice(program2[0..]);
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.equal_tag, false);
}
test "opcode lt" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    var program = [_]u8{
        0,  0, 0, 4, //
        0,  1, 0, 12,
        13, 0, 1, 0,
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.equal_tag, true);
}
test "opcode gt" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    var program = [_]u8{
        0,  0, 0, 8, //
        0,  1, 0, 6,
        14, 0, 1, 0,
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.equal_tag, true);
}

test "opcode jmpe" {
    var test_VM = VM.new(std.testing.allocator);
    defer test_VM.program.deinit();
    var program = [_]u8{
        0,  0, 0, 8, //
        0,  1, 0, 8,
        9,  0, 1, 0,
        15, 1, 0, 0,
    };
    try test_VM.program.appendSlice(program[0..]);
    test_VM.run_once();
    test_VM.run_once();
    test_VM.run_once();
    test_VM.run_once();
    try std.testing.expectEqual(test_VM.pc, 8);
}
