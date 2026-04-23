# Installation Guide - AI Image Renamer for macOS

This guide covers different installation methods for AI Image Renamer.

## Method 1: DMG Installer (Recommended for End Users)

### Step 1: Download the DMG
1. Download `AI-Image-Renamer-macOS-1.0.0.dmg` from the [Releases page](https://github.com/yourusername/ai_renamer_macos/releases)
2. Double-click the downloaded DMG file to mount it

### Step 2: Install the Application
1. A Finder window will open showing the "AI Image Renamer.app"
2. Drag "AI Image Renamer.app" to the Applications folder shortcut
3. Eject the DMG by clicking the eject button in Finder

### Step 3: First Launch
Since the app is not code-signed with an Apple Developer certificate:

**Option A - Right-click method:**
1. Navigate to Applications folder
2. Right-click (or Control+click) "AI Image Renamer.app"
3. Select "Open" from the menu
4. Click "Open" in the security dialog

**Option B - System Settings method:**
1. Try to open the app normally (double-click)
2. macOS will show a security warning
3. Go to System Settings > Privacy & Security
4. Scroll down to find the security message about "AI Image Renamer"
5. Click "Open Anyway"

After the first launch, you can open the app normally.

### Step 4: Install LM Studio
1. Download LM Studio from [https://lmstudio.ai](https://lmstudio.ai)
2. Install LM Studio
3. Launch LM Studio and download a vision-capable model:
   - Recommended: `qwen/qwen2.5-vl-7b-gguf`
   - Alternatives: `llava-v1.6-vicuna-7b`, `llava-v1.5-7b`
4. Load the model in LM Studio
5. Start the local server (usually on port 1234)

### Step 5: Start Using
- Launch "AI Image Renamer" from your Applications folder
- The app will automatically connect to LM Studio
- Drag and drop images/PDFs or click Browse to select files

---

## Method 2: Build from Source (For Developers)

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Build and Create DMG

```bash
# Clone the repository
git clone https://github.com/yourusername/ai_renamer_macos.git
cd ai_renamer_macos

# Create the DMG (this will build and package the app)
make dmg

# The DMG file will be created: AI-Image-Renamer-macOS-1.0.0.dmg
```

### Build and Install to /usr/local/bin

```bash
# Build and install
make install

# Now you can use it from anywhere:
ai-renamer                    # Launch GUI
ai-renamer --cli *.jpg        # Use CLI mode
```

### Build and Run Directly

```bash
# Build release version
make build

# Run GUI mode
make run

# Run CLI mode
make run-cli FILES="*.jpg *.png"
```

---

## Method 3: Quick Development Setup

For contributors and developers who want to work on the code:

```bash
# Clone the repository
git clone https://github.com/yourusername/ai_renamer_macos.git
cd ai_renamer_macos

# Check development environment
make setup

# Build and run in debug mode
make dev

# Or run directly with Swift
swift run AIImageRenamer
```

---

## Command Line Usage

Once installed (either via DMG or `make install`), you can use the CLI:

```bash
# Process specific files
ai-renamer --cli image1.jpg document.pdf

# Process with wildcards
ai-renamer --cli *.jpg *.png

# Dry run (preview without renaming)
ai-renamer --cli *.jpg --dry-run

# Auto-approve all suggestions
ai-renamer --cli *.jpg --auto-approve

# Custom LM Studio host/port
ai-renamer --cli *.jpg --host 192.168.1.100 --port 8080
```

---

## Uninstallation

### If installed via DMG:
1. Open Applications folder
2. Drag "AI Image Renamer.app" to Trash
3. Empty Trash

### If installed via `make install`:
```bash
make uninstall
```

---

## Troubleshooting

### "App can't be opened because it is from an unidentified developer"
- Follow the First Launch instructions above (Method 1, Step 3)

### "Cannot connect to LM Studio"
- Make sure LM Studio is running
- Verify the local server is enabled in LM Studio
- Check that a model is loaded
- Default connection: `127.0.0.1:1234`

### Build Errors
```bash
# Clean and rebuild
make clean
make build

# Or with Swift directly
swift package clean
swift build -c release
```

### "Command not found: ai-renamer"
- If installed via DMG, the CLI won't be available automatically
- Run `make install` from the source directory to add CLI support
- Or use the full path: `/Applications/AI\ Image\ Renamer.app/Contents/MacOS/AIImageRenamer --cli`

---

## System Requirements

- **OS**: macOS 14.0 (Sonoma) or later
- **Architecture**: Apple Silicon (M1/M2/M3) or Intel
- **RAM**: 8GB minimum (16GB recommended for large models)
- **Storage**: ~10GB for LM Studio and models
- **LM Studio**: Required for AI functionality

---

## Getting Help

- **Documentation**: See [README.md](README.md) for features and usage
- **Issues**: Report bugs on [GitHub Issues](https://github.com/yourusername/ai_renamer_macos/issues)
- **Development**: See [CLAUDE.md](CLAUDE.md) for architecture details

---

## Code Signing (Optional - For Distribution)

If you want to distribute your own signed version:

```bash
# Build the app
make dmg

# Sign the app bundle
codesign --deep --force --sign "Developer ID Application: Your Name" \
  "build/AI Image Renamer.app"

# Verify signature
codesign --verify --verbose "build/AI Image Renamer.app"

# Create DMG with signed app
# (Re-run make dmg after signing)
```

For notarization (required for distribution outside the App Store):
1. Get an Apple Developer account
2. Create a Developer ID certificate
3. Use `xcrun notarytool` to notarize the DMG
4. Staple the notarization ticket: `xcrun stapler staple "AI-Image-Renamer-macOS-1.0.0.dmg"`

---

**Copyright © 2024. All rights reserved.**
