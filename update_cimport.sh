#!/bin/sh

cp vendor/libuv/include/uv.h vendor/libuv/include/uv.h.orig

perl -pi -e 's{^  uv_close_cb close_cb}{  void* close_cb}g' vendor/libuv/include/uv.h
perl -pi -e 's{^  uv_read_cb read_cb}{  void* read_cb}g' vendor/libuv/include/uv.h

zig translate-c -target aarch64-linux -lc -Ivendor/libuv/include vendor/libuv/include/uv.h > src/cimport_linux.zig 
zig translate-c -target aarch64-macos -lc -Ivendor/libuv/include vendor/libuv/include/uv.h > src/cimport_macos.zig 

mv vendor/libuv/include/uv.h.orig vendor/libuv/include/uv.h
