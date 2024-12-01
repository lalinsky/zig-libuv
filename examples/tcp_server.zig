const std = @import("std");
const log = std.log;
const uv = @import("uv");

const Connection = struct {
    allocator: std.mem.Allocator,

    pub fn create(allocator: std.mem.Allocator) !*Connection {
        const self = try allocator.create(Connection);
        self.* = .{
            .allocator = allocator,
        };
        return self;
    }

    pub fn destroy(self: *Connection) void {
        self.allocator.destroy(self);
    }

    pub fn readStart(self: *Connection, stream: *uv.Tcp) !void {
        stream.setData(self);
        try stream.readStart(onAlloc, onRead);
    }

    fn onClose(stream: *uv.Tcp) void {
        log.info("onClose", .{});
        const self = stream.getData(Connection) orelse @panic("no connection data");
        stream.deinit(self.allocator);
        self.destroy();
    }

    fn onAlloc(stream: *uv.Tcp, size: usize) ?[]u8 {
        log.info("onAlloc {}", .{size});
        const ctx = stream.getData(Connection) orelse @panic("no connection data");
        return ctx.allocator.alloc(u8, size) catch null;
    }

    fn onRead(socket: *uv.Tcp, nread: isize, buf: []const u8) void {
        const ctx = socket.getData(Connection) orelse @panic("no connection data");
        //defer ctx.allocator.free(buf);

        log.info("onRead {}", .{nread});

        if (nread < 0) {
            uv.convertError(@intCast(nread)) catch |err| {
                if (err == error.EOF) {
                    socket.close(onClose);
                    return;
                }
                log.err("read failed: {any}", .{err});
                return;
            };
        }
        const data = buf[0..@as(usize, @intCast(nread))];

        const write_req = uv.WriteReq.init(ctx.allocator) catch unreachable;
        // write_req.setData(@ptrCast(@constCast(buf)));
        socket.write(write_req, &.{data}, onWrite) catch unreachable;
    }

    fn onWrite(req: *uv.WriteReq, status: i32) void {
        const self = req.handle(uv.Tcp).?.getData(Connection).?;
        log.info("onWrite {} {}", .{ status, req.req.nbufs });
        // const buf = req.getData(u8).?;
        defer req.deinit(self.allocator);
        // self.allocator.free(buf);
    }
};

const Server = struct {
    allocator: std.mem.Allocator,

    fn onConnection(socket: *uv.Tcp, status: i32) void {
        log.info("onConnection {}", .{status});
        if (status != 0) {
            return;
        }

        const self = socket.getData(Server) orelse @panic("no server data");

        const connection = Connection.create(self.allocator) catch unreachable;

        var client = socket.accept(self.allocator) catch unreachable;
        connection.readStart(&client) catch unreachable;
    }

    pub fn listen(self: *Server, socket: *uv.Tcp, backlog: i32) !void {
        socket.setData(self);
        try socket.listen(backlog, onConnection);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var loop = try uv.Loop.init(allocator);
    defer loop.deinit(allocator);

    var server_socket = try uv.Tcp.init(loop, allocator);
    defer server_socket.deinit(allocator);

    const addr = try std.net.Address.parseIp4("127.0.0.1", 7000);

    try server_socket.bind(addr, .{});

    var server = Server{
        .allocator = allocator,
    };
    server_socket.setData(&server);

    try server.listen(&server_socket, 100);

    _ = try loop.run(.default);
}
