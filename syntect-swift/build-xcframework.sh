#!/bin/bash
set -e

cd "$(dirname "$0")"

# Ensure cargo is available
export PATH="$HOME/.cargo/bin:$PATH"

# Build for both architectures
echo "Building for x86_64..."
cargo build --release --target x86_64-apple-darwin

echo "Building for aarch64..."
cargo build --release --target aarch64-apple-darwin

# Generate Swift bindings using the built-in uniffi-bindgen binary
echo "Generating Swift bindings..."
mkdir -p ./generated
cargo run --release --bin uniffi-bindgen -- generate \
    --library target/aarch64-apple-darwin/release/libsyntect_swift.dylib \
    --language swift \
    --out-dir ./generated

# Create universal binary
echo "Creating universal binary..."
mkdir -p target/universal/release
lipo -create \
    target/x86_64-apple-darwin/release/libsyntect_swift.a \
    target/aarch64-apple-darwin/release/libsyntect_swift.a \
    -output target/universal/release/libsyntect_swift.a

# Create headers directory with proper structure for FFI module
echo "Preparing headers..."
mkdir -p ./headers
cp ./generated/SyntectSwiftFFI.h ./headers/
cp ./generated/SyntectSwiftFFI.modulemap ./headers/module.modulemap

# Create XCFramework with proper FFI module name
echo "Creating XCFramework..."
rm -rf SyntectSwiftFFI.xcframework
xcodebuild -create-xcframework \
    -library target/universal/release/libsyntect_swift.a \
    -headers headers/ \
    -output SyntectSwiftFFI.xcframework

echo "Done! XCFramework created at syntect-swift/SyntectSwiftFFI.xcframework"
echo ""
echo "Generated Swift binding file: generated/SyntectSwift.swift"
echo "Copy this to your Shared folder: cp generated/SyntectSwift.swift ../Shared/SyntectBridge.swift"
echo ""
echo "XCFramework structure:"
ls -laR SyntectSwiftFFI.xcframework/
