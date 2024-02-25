const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file_name = "/Users/adiadev/Projects/Dev/zig/1rbc-zig/src/data/weather_stations.csv";
    const file = try fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    const writer = line.writer();
    var line_no: usize = 1;
    while (reader.streamUntilDelimiter(writer, '\n', null)) : (line_no += 1) {
        // Clear the line so we can reuse it.
        defer line.clearRetainingCapacity();

        std.debug.print("{s}\n", .{line.items});
    } else |err| switch (err) {
        error.EndOfStream => {}, // Continue on
        else => return err, // Propagate error
    }
}
