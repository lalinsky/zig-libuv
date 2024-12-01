const std = @import("std");
const c = @import("c.zig");
const Loop = @import("Loop.zig");
const errors = @import("error.zig");
const stream = @import("stream.zig");
const handle = @import("handle.zig");

pub const Udp = struct {
    handle: *c.uv_udp_t,

    // Add shared handle and stream functionality
    pub usingnamespace handle.Handle(@This());
    pub usingnamespace stream.Stream(@This());

    pub fn init(loop: *Loop, allocator: std.mem.Allocator) !Udp {
        const udp_handle = try allocator.create(c.uv_udp_t);
        errdefer allocator.destroy(udp_handle);
        try errors.convertError(c.uv_udp_init(loop.loop, udp_handle));
        return Udp{ .handle = udp_handle };
    }

    pub fn deinit(self: *Udp, allocator: std.mem.Allocator) void {
        allocator.destroy(self.handle);
        self.* = undefined;
    }

    pub fn bind(self: *Udp, addr: std.net.Address) !void {
        var sockaddr = addr.any;
        try errors.convertError(c.uv_udp_bind(
            self.handle,
            @ptrCast(&sockaddr),
            0,
        ));
    }

    // TODO complete
};

test "Udp" {
    const testing = std.testing;

    var loop = try Loop.init(testing.allocator);
    defer loop.deinit(testing.allocator);

    var socket = try Udp.init(&loop, testing.allocator);
    defer socket.deinit(testing.allocator);

    // TODO complete
    _ = try loop.run(.once);

    socket.close(null);
    _ = try loop.run(.default);
}
