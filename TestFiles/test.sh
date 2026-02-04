#!/bin/bash
# Sample shell script for E2E testing

set -e

# Variables
APP_NAME="dotViewer"
VERSION="1.1.0"

# Function to build
build() {
    echo "Building $APP_NAME v$VERSION..."
    xcodebuild -scheme "$APP_NAME" -configuration Release build
}

# Function to clean
clean() {
    echo "Cleaning build artifacts..."
    rm -rf build/
}

# Main
case "$1" in
    build)
        build
        ;;
    clean)
        clean
        ;;
    *)
        echo "Usage: $0 {build|clean}"
        exit 1
        ;;
esac
