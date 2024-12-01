<hr>

Forked this repo to upgrade the zig version to master. The original repo is [here](https://github.com/mitchellh/zig-libuv).

<hr>

# zig-libuv

zig-libuv contains a `build.zig` that can build libuv using Zig and also
contains a package with Zig bindings. Both can be used together or separately.
Building libuv with Zig enables easy cross-compilation. The bindings allow
you to consume libuv easily whether it is built with Zig or not.

## Example 

There are lots of examples in the tests for each individual handle type.
Below is an example of using a timer, copied exactly from the tests:

```zig
const uv = @import("uv");

var loop = try uv.Loop.init(testing.allocator);
defer loop.deinit(testing.allocator);

var timer = try uv.Timer.init(testing.allocator, loop);
defer timer.deinit(testing.allocator);

var called: bool = false;
timer.setData(&called);
try timer.start((struct {
    fn callback(t: *Timer) void {
        t.getData(bool).?.* = true;
        t.close(null);
    }
}).callback, 10, 1000);

_ = try loop.run(.default);

try std.testing.expect(called);
```

## Usage

To **build libuv:**

```zig
const libuv = @import("path/to/zig-libuv/build.zig");

pub fn build(b: *std.build.Builder) !void {
    // ...

    const exe = b.addExecutable("my-program", "src/main.zig");
    _ = libuv.link(b, exe);
}
```

To **use the Zig bindings**, add the package:

```zig
exe.addPackage(libuv.pkg);
```
