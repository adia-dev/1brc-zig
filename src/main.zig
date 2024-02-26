const std = @import("std");
const fs = std.fs;
const measurements = @embedFile("./data/measurements_10000000.txt");

const WeatherInfo = struct {
    city: []const u8,
    min: f32 = std.math.inf(f32),
    sum: f32 = 0.0,
    max: f32 = -std.math.inf(f32),
    count: u32 = 0,

    pub fn init(city: []const u8, weather: f32) WeatherInfo {
        return .{ .city = city, .min = weather, .max = weather, .sum = weather, .count = 1 };
    }

    pub fn format(self: WeatherInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try std.fmt.format(writer, "{s};{d:.1};{d:.1};{d:.1}", .{ self.city, self.min, self.sum / @as(f32, @floatFromInt(self.count)), self.max });
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const start = std.time.nanoTimestamp();

    var store = std.StringHashMap(WeatherInfo).init(allocator);
    defer store.deinit();

    var begin: usize = 0;
    var i: usize = 0;
    var line_count: u32 = 0;
    while (i < measurements.len) : (i += 1) {
        while (i < measurements.len and measurements[i] != '\n') : (i += 1) {}
        var j = begin;
        while (j < measurements.len and measurements[j] != ';') : (j += 1) {}

        const city = measurements[begin..j];
        const weather = measurements[(j + 1)..i];
        const weather_f32: f32 = try std.fmt.parseFloat(f32, weather);

        if (store.getPtr(city)) |entry| {
            entry.min = @min(entry.min, weather_f32);
            entry.sum += weather_f32;
            entry.count += 1;
            entry.max = @max(entry.max, weather_f32);
        } else {
            try store.put(city, WeatherInfo.init(city, weather_f32));
        }

        // skip the newline
        i += 1;
        line_count += 1;
        begin = i;
    }

    const end = std.time.nanoTimestamp();
    const elapsed_time = @as(f32, @floatFromInt((end - start))) / 1_000_000_000.0;

    var it = store.iterator();
    var entry_count: u32 = 0;
    while (it.next()) |entry| {
        std.debug.print("{}\n", .{entry.value_ptr.*});
        entry_count += 1;
    }

    std.debug.print("\n\n===============================\n", .{});
    std.debug.print(" - {d} Line parsed\n", .{line_count});
    std.debug.print(" - {d} Entries computed\n", .{entry_count});
    std.debug.print(" - Took: {d:.2} seconds.\n", .{elapsed_time});
}
