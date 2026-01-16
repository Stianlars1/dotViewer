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

# Create module.modulemap for the XCFramework
cat > generated/module.modulemap << 'EOF'
framework module SyntectSwift {
    umbrella header "syntect_swiftFFI.h"
    export *
    module * { export * }
}
EOF

# Create XCFramework
echo "Creating XCFramework..."
rm -rf SyntectSwift.xcframework
xcodebuild -create-xcframework \
    -library target/universal/release/libsyntect_swift.a \
    -headers generated/ \
    -output SyntectSwift.xcframework

echo "Done! XCFramework created at syntect-swift/SyntectSwift.xcframework"
echo ""
echo "Generated files:"
ls -la generated/
echo ""
echo "XCFramework structure:"
ls -la SyntectSwift.xcframework/
