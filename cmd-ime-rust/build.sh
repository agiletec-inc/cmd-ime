#!/bin/bash
set -e

# Source Rust environment
. "/Users/kazuki/.local/share/cargo/env"

# Build Next.js app first
echo "Building Next.js frontend..."
cd ../apps/settings
pnpm build

# Build Tauri app
echo "Building Tauri app..."
cd ../../cmd-ime-rust
pnpm tauri build --no-bundle

echo "Build complete!"
