#!/bin/bash

# AI Image Renamer for macOS - Build Script
# ==========================================

set -e  # Exit on any error

echo "🚀 AI Image Renamer for macOS - Build Script"
echo "============================================="
echo ""

# Check Swift version
echo "📋 Checking Swift version..."
swift --version | head -1

# Check macOS version
echo "📋 macOS Version: $(sw_vers -productVersion)"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
swift package clean

# Build the project
echo "🔨 Building AI Image Renamer..."
swift build -c release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📍 Binary location: ./.build/release/AIImageRenamer"
    echo ""
    echo "🎮 Usage:"
    echo "  GUI mode: ./.build/release/AIImageRenamer"
    echo "  CLI mode: ./.build/release/AIImageRenamer --cli *.jpg"
    echo "  Help:     ./.build/release/AIImageRenamer --help"
    echo ""
    echo "📦 To install system-wide:"
    echo "  make install"
    echo ""
    echo "🔍 To test LM Studio connection:"
    echo "  curl -s http://127.0.0.1:1234/v1/models"
    echo ""
else
    echo ""
    echo "❌ Build failed!"
    echo "Please check the error messages above."
    exit 1
fi
