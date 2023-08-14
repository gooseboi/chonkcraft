const std = @import("std");
const net = std.net;

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
    var str = (buf.*)[0..str_len];
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

    var server = net.StreamServer.init(.{ .reuse_address = true });
    defer server.deinit();
    try server.listen(address);
    print("Server listening on {}\n", .{address});

    const conn = try server.accept();
    defer conn.stream.close();

    while (true) {
        var buf: [1024]u8 = undefined;
        const msg_size = try conn.stream.read(buf[0..]);
        print("Read {} bytes from stream\n", .{msg_size});

        var msg = buf[0..msg_size];
        const msg_len = try read_varint(&msg);
        print("Read msg_len {}\n", .{msg_len});

        const packet_id = try read_varint(&msg);
        print("Read packet id {}\n", .{packet_id});
        const ver = try read_varint(&msg);
        print("Read version {}\n", .{ver});

        const addr = try read_string(&msg);
        print("Addr len `{}`\n", .{addr.len});
        print("Addr `{s}`\n", .{addr});
        const port = try read_short(&msg);
        print("Port `{}`\n", .{port});

        const next_state = try read_varint(&msg);
        print("Next state was `{}`\n", .{next_state});

        print("Leftover(bytes) `{any}`\n", .{msg});
        print("Leftover(str) `{s}`\n", .{msg});
        print("\n", .{});
    }
}
