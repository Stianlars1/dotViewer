#!/bin/sh
# Explicit custom-compiler route for the Xcode 26.6 discovery-pipe hang.
# All real compilation is delegated unchanged to the active Apple toolchain.
exec /usr/bin/xcrun clang "$@"
