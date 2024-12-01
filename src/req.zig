const c = @import("c.zig");

pub fn Req(comptime T: type) type {
    return struct {
        /// Sets req->data to data.
        pub fn setData(self: T, pointer: ?*anyopaque) void {
            c.uv_req_set_data(
                @as(*c.uv_req_t, @ptrCast(self.req)),
                pointer,
            );
        }

        /// Returns req->data.
        pub fn getData(self: T, comptime DT: type) ?*DT {
            return if (c.uv_req_get_data(@as(*c.uv_req_t, @ptrCast(self.req)))) |ptr|
                @as(?*DT, @alignCast(@ptrCast(ptr)))
            else
                null;
        }
    };
}
