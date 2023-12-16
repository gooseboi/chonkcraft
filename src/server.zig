const std = @import("std");

const StreamServer = std.net.StreamServer;
const Address = std.net.Address;

const Thread = std.Thread;

const ArrayList = std.ArrayList;

const ClientList = ArrayList(StreamServer.Connection);

pub const Server = struct {
    server: StreamServer,
    clients: ClientList,

    const Self = @This();

    pub fn init(addr: Address) !Self {
        var server = StreamServer.init(.{ .reuse_address = true });
        try server.listen(addr);
        var _server = Server{
            .server = server,
            .clients = ClientList.init(std.heap.page_allocator),
        };
        return _server;
    }

    pub fn deinit(self: *Self) void {
        self.server.deinit();
    }

    pub fn run(self: *Self) !void {
        _ = self;
        //while (true) {
        //    var buf: [1024]u8 = undefined;
        //    const msg_size = try conn.stream.read(buf[0..]);
        //    print("Read {} bytes from stream\n", .{msg_size});

        //    var msg = buf[0..msg_size];
        //    const msg_len = try read_varint(&msg);
        //    print("Read msg_len {}\n", .{msg_len});

        //    const packet_id = try read_varint(&msg);
        //    print("Read packet id {}\n", .{packet_id});
        //    const ver = try read_varint(&msg);
        //    print("Read version {}\n", .{ver});

        //    const addr = try read_string(&msg);
        //    print("Addr len `{}`\n", .{addr.len});
        //    print("Addr `{s}`\n", .{addr});
        //    const port = try read_short(&msg);
        //    print("Port `{}`\n", .{port});

        //    const next_state = try read_varint(&msg);
        //    print("Next state was `{}`\n", .{next_state});

        //    print("Leftover(bytes) `{any}`\n", .{msg});
        //    print("Leftover(str) `{s}`\n", .{msg});
        //    print("\n", .{});
        //}
    }
};
