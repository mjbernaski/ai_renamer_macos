#!/bin/bash
set -e

# AI Image Renamer - DMG Creation Script
# This script builds the app and creates a distributable DMG file

echo "🚀 AI Image Renamer - DMG Builder"
echo "=================================="

# Configuration
APP_NAME="AI Image Renamer"
APP_BUNDLE_NAME="AI Image Renamer.app"
DMG_NAME="AI-Image-Renamer-macOS"
VERSION="1.0.0"
BUILD_DIR="build"
DMG_DIR="dmg_temp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Clean previous builds
echo ""
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
rm -rf "$DMG_DIR"
rm -f "${DMG_NAME}.dmg"
rm -f "${DMG_NAME}-${VERSION}.dmg"

# Create build directory
mkdir -p "$BUILD_DIR"

# Build the Swift binary
echo ""
echo "🔨 Building Swift binary (Release mode)..."

# Check if binary already exists
if [ -f ".build/release/AIImageRenamer" ]; then
    echo -e "${YELLOW}⚠️  Using existing release build${NC}"
    echo "   To rebuild, run: swift build -c release"
else
    swift build -c release

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Build failed!${NC}"
        exit 1
    fi
fi

if [ ! -f ".build/release/AIImageRenamer" ]; then
    echo -e "${RED}❌ Binary not found!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Binary ready!${NC}"

# Create app bundle structure
echo ""
echo "📦 Creating app bundle..."
APP_BUNDLE="$BUILD_DIR/$APP_BUNDLE_NAME"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy the binary
echo "   Copying binary..."
cp .build/release/AIImageRenamer "$APP_BUNDLE/Contents/MacOS/"
chmod +x "$APP_BUNDLE/Contents/MacOS/AIImageRenamer"

# Create Info.plist
echo "   Creating Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>AIImageRenamer</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.aitools.imagerenamer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>AI Image Renamer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Image Files</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.image</string>
                <string>public.jpeg</string>
                <string>public.png</string>
            </array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>PDF Files</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.adobe.pdf</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

# Copy or create app icon if it exists
if [ -f "ain.app/Contents/Resources/AppIcon.icns" ]; then
    echo "   Copying existing app icon..."
    cp "ain.app/Contents/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
else
    echo -e "   ${YELLOW}⚠️  No app icon found, app will use default icon${NC}"
fi

echo -e "${GREEN}✅ App bundle created!${NC}"

# Create DMG staging directory
echo ""
echo "💿 Creating DMG..."
mkdir -p "$DMG_DIR"

# Copy app to DMG directory
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create a symlink to Applications folder
ln -s /Applications "$DMG_DIR/Applications"

# Create a README for the DMG
cat > "$DMG_DIR/README.txt" << 'EOF'
AI Image Renamer for macOS
===========================

Installation:
1. Drag "AI Image Renamer.app" to the Applications folder
2. Install LM Studio from https://lmstudio.ai
3. Load a vision-capable model in LM Studio (e.g., qwen2.5-vl-7b)
4. Start the LM Studio local server
5. Launch AI Image Renamer from Applications

Usage:
- GUI Mode: Double-click the app
- CLI Mode: Use Terminal with command "ai-renamer"

For more information, visit:
https://github.com/yourusername/ai_renamer_macos

Requirements:
- macOS 14.0 (Sonoma) or later
- LM Studio with vision-capable model

Copyright © 2024. All rights reserved.
EOF

# Create the DMG
echo "   Building DMG file..."
DMG_FILE="${DMG_NAME}-${VERSION}.dmg"

# Use hdiutil to create the DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "$DMG_FILE"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ DMG creation failed!${NC}"
    exit 1
fi

# Clean up temporary directories
echo ""
echo "🧹 Cleaning up temporary files..."
rm -rf "$DMG_DIR"

# Get DMG size
DMG_SIZE=$(du -h "$DMG_FILE" | cut -f1)

echo ""
echo "=================================="
echo -e "${GREEN}✅ DMG created successfully!${NC}"
echo ""
echo "📦 File: $DMG_FILE"
echo "📏 Size: $DMG_SIZE"
echo ""
echo "To test the DMG:"
echo "  1. Double-click $DMG_FILE to mount it"
echo "  2. Drag the app to Applications"
echo "  3. Launch from Applications folder"
echo ""
echo "To distribute:"
echo "  Upload $DMG_FILE to GitHub Releases or your website"
echo ""
echo -e "${YELLOW}Note:${NC} The app is not code-signed. Users may need to:"
echo "  1. Right-click the app and select 'Open'"
echo "  2. Or go to System Settings > Privacy & Security to allow it"
echo ""
echo "To code-sign the app (requires Apple Developer account):"
echo "  codesign --deep --force --sign \"Your Identity\" \"$APP_BUNDLE\""
echo "=================================="
