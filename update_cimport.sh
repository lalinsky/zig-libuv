#!/bin/sh
zig translate-c -target aarch64-linux -lc -Ivendor/libuv/include vendor/libuv/include/uv.h > src/cimport_linux.zig 
patch -p1 < cimport_linux_fix.patch
