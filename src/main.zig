const std = @import("std");
const Vm = @import("./vm.zig");
const utils = @import("./utls.zig");
const log = std.log;
const debug = std.debug;
const repl = @import("./repl/repl.zig");

pub fn main() !void {
    // var i = "00 01 03 E8";
    // var split = std.mem.split(u8, i, " ");
    // var result = std.ArrayList([]const u8).init(std.heap.page_allocator);
    // defer result.deinit();

    // var split = std.mem.split(u8, std.mem.trim(u8, i, " "), " ");

    // while (split.next()) |s| {
    //     debug.print("{s}\n", .{s});
    //     // try result.append(s);
    // }
    // debug.print("{!}\n", .{std.fmt.parseInt(u8, "A", 16)});

    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var _repl = repl.REPL.new(allocator);
    defer _repl.command_buffer.deinit();
    try _repl.run();

    // debug.print("{any}\n", .{split.buffer});

}

test {
    // _ = Vm;
    // try std.testing.expect(std.mem.eql(u8, "H", &"H"[0..]));
}
