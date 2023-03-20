const std = @import("std");
const VM = @import("../vm.zig").VM;
const debug = std.debug;

pub const REPL = struct {
    const Self = @This();
    command_buffer: std.ArrayList([]u8), //
    vm: VM,
    pub fn new(allocator: std.mem.Allocator) REPL {
        return REPL{
            .vm = VM.new(allocator), //
            .command_buffer = std.ArrayList([]u8).init(allocator),
        };
    }
    pub fn run(self: *Self) !void {
        const stdout_file = std.io.getStdOut().writer();
        var stdout = std.io.bufferedWriter(stdout_file);
        const stdin = std.io.getStdIn();
        const eql = std.mem.eql;

        // try stdout.writer().print("Welcome to Wragner VM! Let's be productive!\n", .{});
        // try stdout.flush();
        debug.print("Welcome to Wragner VM! Let's be productive!\n", .{});

        var is_done = false;

        while (!is_done) {
            // This allocates a new String in which to store whatever the user types each iteration.
            // TODO: Figure out how allocate this outside of the loop and re-use it every iteration
            var buf: [1000]u8 = undefined;

            try stdout.writer().writeAll(">>> ");
            try stdout.flush();

            // Here we'll look at the string the user gave us.
            const bytes_read = (try self.nextLine(stdin.reader(), &buf)).?;

            // Create a clone of the buffer
            var clone = try self.command_buffer.allocator.dupe(u8, bytes_read[0..]);

            // This is the line we add to store a copy of each cloned command buffer
            try self.command_buffer.append(clone);

            if (eql(u8, clone, ".quit")) {
                debug.print("Good Bye!\n", .{});
                std.process.exit(0);
            } else if (eql(u8, clone, ".history")) {
                for (self.command_buffer.items) |command| {
                    debug.print("{s}\n", .{command});
                }
            } else if (eql(u8, clone, ".program")) {
                debug.print("Listing instructions currently in VM's program vector:\n", .{});

                for (self.vm.program.items) |instruction| {
                    debug.print("{any}\n", .{instruction});
                }

                debug.print("End of Program Listing\n", .{});
            } else if (eql(u8, clone, ".registers")) {
                debug.print("Listing instructions currently in VM's register:\n", .{});

                debug.print("{any}\n", .{self.vm.registers});

                debug.print("End of Register Listing\n", .{});
            } else {
                // debug.print("Invalid input\n", .{});
                var results = try self.parse_hex(clone, std.heap.page_allocator);
                defer results.deinit();
                var clone2 = try self.vm.program.allocator.dupe(u8, results.items[0..]);
                try self.vm.program.appendSlice(clone2);
                self.vm.run_once();
            }
        }
    }
    fn nextLine(_: *Self, reader: anytype, buffer: []u8) !?[]const u8 {
        var line = (try reader.readUntilDelimiterOrEof(
            buffer,
            '\n',
        )) orelse return null;
        // trim annoying windows-only carriage return character
        if (@import("builtin").os.tag == .windows) {
            return std.mem.trimRight(u8, line, "\r");
        } else {
            return line;
        }
    }

    fn parse_hex(_: *Self, i: []const u8, allocator: std.mem.Allocator) !std.ArrayList(u8) {
        var split = std.mem.split(u8, std.mem.trim(u8, i, " "), " ");
        var result = std.ArrayList(u8).init(allocator);
        while (split.next()) |hex_string| {
            var byte = try std.fmt.parseInt(u8, hex_string, 16);
            try result.append(byte);
        }
        return result;
    }
};
