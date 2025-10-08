#!/bin/bash
set -e

echo "Installing Flutter..."
# Clone Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
export PATH="$PATH:`pwd`/_flutter/bin"

# Verify Flutter
flutter --version

echo "Current directory: $(pwd)"
echo "Listing files:"
ls -la

echo "Getting dependencies..."
flutter pub get

echo "Building web app..."
flutter build web --release --base-href /

echo "Build complete!"

