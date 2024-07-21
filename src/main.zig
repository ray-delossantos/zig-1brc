const std = @import("std");

const Stats = struct { min: f32, max: f32, sum: f64, count: u64 };

pub fn main() !void {
    var gpa_array_list = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator_array_list = gpa_array_list.allocator();

    var gpa_string_hash_map = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator_string_hash_map = gpa_string_hash_map.allocator();

    var file = try std.fs.cwd().openFile("weather_stations.csv", .{});
    defer file.close();

    // Things are _a lot_ slower if we don't use a BufferedReader
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    // lines will get read into this
    var arr = std.ArrayList(u8).init(allocator_array_list);
    defer arr.deinit();

    var line_count: usize = 0;
    var byte_count: usize = 0;

    var stats_map = std.StringHashMap(Stats).init(allocator_string_hash_map);
    defer stats_map.deinit();

    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        line_count += 1;
        byte_count += arr.items.len;
        var line_parts_iter = std.mem.splitSequence(u8, arr.items, ";");
        var i: i4 = 0;
        var line_part_key: []const u8 = "";
        var line_part_value: f32 = 0;

        while (line_parts_iter.next()) |x| {
            switch (i) {
                0 => {
                    line_part_key = x;
                },
                1 => {
                    line_part_value = std.fmt.parseFloat(f32, x) catch 0;
                },
                else => {},
            }
            i += 1;
        }
        const stats = Stats{ .min = line_part_value, .max = line_part_value, .sum = 0, .count = 0 };
        try stats_map.put(line_part_key, stats);
        std.debug.print("{d}, {d}, {d}, {d} \n", stats);

        arr.clearRetainingCapacity();
    }
    std.debug.print("{d} lines, {d} bytes", .{ line_count, byte_count });
}
