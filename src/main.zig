const std = @import("std");
const net = std.net;

const Server = @import("server.zig").Server;

fn print(comptime fmt: []const u8, args: anytype) void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    stdout.print(fmt, args) catch return;
    bw.flush() catch return;
}

const ReadError = error{ VarIntTooLong, UnexpectedEOF };

fn read_varint(buf: *[]u8) ReadError!usize {
    var val: usize = 0;
    var bytes_read: usize = 0;
    var pos: usize = 0;

    const VAL_MASK = 0x7F;
    const CONTINUE_MASK = 0x80;

    while (true) {
        if (pos >= buf.len) return ReadError.UnexpectedEOF;
        const curr_byte = (buf.*)[pos];
        val <<= 7;
        val |= (curr_byte & VAL_MASK);

        bytes_read += 7;
        if (bytes_read >= 32) return ReadError.VarIntTooLong;
        pos += 1;
        if (curr_byte & CONTINUE_MASK == 0) break;
    }

    buf.* = (buf.*)[pos..];

    return val;
}

fn read_string(buf: *[]u8) ReadError![]u8 {
    const str_len = try read_varint(buf);
    const str = (buf.*)[0..str_len];
    buf.* = (buf.*)[str_len..];
    return str;
}

fn read_short(buf: *[]u8) ReadError!i16 {
    const slice = buf.*;
    const top_half = @as(u16, slice[0]);
    const low_half = @as(u16, slice[1]);
    const val: i16 = @bitCast((top_half << 8) + low_half);
    buf.* = (buf.*)[2..];
    return val;
}

pub fn main() !void {
    const address = net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 8080);

    var server = try Server.init(address);
    print("Server listening on {}\n", .{address});
    defer server.deinit();

    try server.run();
}
