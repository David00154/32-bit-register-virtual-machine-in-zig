const std = @import("std");
const meta = std.meta;
const Vm = @import("./vm.zig");

pub const Opcode = enum(u8) {
    //
    LOAD = 0,
    ADD,
    SUB,
    MUL,
    DIV,
    HLT,
    JMP,
    JMPF,
    JMPB,
    EQ, // ==
    NEQ, // !=
    GTE, // >=
    LTE, // <=
    LT, // <
    GT, // >
    JMPE,
    // NOP,
    // ALOC,
    // INC,
    // DEC,
    // DJMPE,
    IGL,
    // PRTS,
    // LOADF64,
    // ADDF64,
    // SUBF64,
    // MULF64,
    // DIVF64,
    // EQF64,
    // NEQF64,
    // GTF64,
    // GTEF64,
    // LTF64,
    // LTEF64,
    // SHL,
    // SHR,
    // AND,
    // OR,
    // XOR,
    // NOT,
    // LUI,
    // CLOOP,
    // LOOP,
    // LOADM,
    // SETM,
    // PUSH,
    // POP,
    // CALL,
    // RET,
    //
    pub fn intToEnum(value: u8) Opcode {
        return switch (value) {
            0 => Opcode.LOAD,
            1 => Opcode.ADD,
            2 => Opcode.SUB,
            3 => Opcode.MUL,
            4 => Opcode.DIV,
            5 => Opcode.HLT,
            6 => Opcode.JMP,
            7 => Opcode.JMPF,
            8 => Opcode.JMPB,
            9 => Opcode.EQ,
            10 => Opcode.NEQ,
            11 => Opcode.GTE,
            12 => Opcode.LTE,
            13 => Opcode.LT,
            14 => Opcode.GT,
            15 => Opcode.JMPE,
            else => Opcode.IGL,
        };
    }
};

pub const Instruction = struct {
    opcode: Opcode,
    pub fn new(opcode: Opcode) Instruction {
        return Instruction{
            .opcode = opcode,
        };
    }
};

test "create hlt" {
    var opcode = Opcode.HLT;
    try std.testing.expectEqual(opcode, Opcode.HLT);
}

test "create instruction" {
    var instruction: Instruction = Instruction.new(Opcode.HLT);

    try std.testing.expectEqual(instruction.opcode, Opcode.HLT);
}
