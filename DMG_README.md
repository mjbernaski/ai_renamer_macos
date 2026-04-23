# DMG Distribution Guide

## What Was Created

A complete DMG (disk image) installer for AI Image Renamer that includes:

- **AI Image Renamer.app** - The native macOS application bundle
- **Applications symlink** - For easy drag-and-drop installation
- **README.txt** - Installation instructions included in the DMG

## Files Created

1. **create_dmg.sh** - Script to build and package the DMG
2. **AI-Image-Renamer-macOS-1.0.0.dmg** - The distributable installer (1.7MB)
3. **INSTALL.md** - Comprehensive installation guide for users
4. **Makefile updates** - Added `make dmg` and `make dmg-clean` targets

## Quick Usage

### Create a DMG

```bash
# Create DMG with existing build
make dmg

# Or run the script directly
./create_dmg.sh
```

### Test the DMG

```bash
# Mount the DMG
open AI-Image-Renamer-macOS-1.0.0.dmg

# Or double-click in Finder
```

### Clean up

```bash
# Remove DMG and build artifacts
make dmg-clean
```

## Distribution Checklist

When you're ready to distribute the DMG:

- [ ] Test the DMG on a clean Mac
- [ ] Verify the app launches correctly
- [ ] Test the LM Studio connection
- [ ] Update version number in create_dmg.sh if needed
- [ ] Create a GitHub Release
- [ ] Upload the DMG file
- [ ] Add release notes with:
  - What's new
  - System requirements
  - Installation instructions
  - Link to LM Studio

## Important Notes

### Code Signing

The app is **not code-signed** by default. Users will see a security warning on first launch.

**For personal/internal use:**
- This is fine - users can right-click > Open to bypass the warning
- See INSTALL.md for detailed instructions

**For public distribution:**
- Consider getting an Apple Developer account ($99/year)
- Sign the app with your Developer ID certificate
- Optionally notarize the app for better user experience

### Updating the Version

Edit `create_dmg.sh` and change:
```bash
VERSION="1.0.0"
```

### Customizing the DMG

The DMG includes:
- App bundle in `build/AI Image Renamer.app/`
- README.txt shown when DMG is mounted
- Applications folder symlink for easy installation

To customize the README.txt, edit the heredoc in `create_dmg.sh` starting at line ~176.

## Building from Scratch

If you need to rebuild everything:

```bash
# Clean everything
make clean
make dmg-clean

# Build fresh
swift build -c release

# Create DMG
make dmg
```

## Troubleshooting

### "Build failed" error
The script now uses existing builds if available. To force a rebuild:
```bash
swift build -c release
make dmg
```

### "Binary not found" error
Make sure you're in the project root directory and run:
```bash
swift build -c release
```

### DMG creation fails
Make sure you have enough disk space and proper permissions. The script needs to:
- Create temporary directories
- Copy files
- Run `hdiutil` to create the DMG

### Testing the DMG
1. Mount: `open AI-Image-Renamer-macOS-1.0.0.dmg`
2. In the opened window, drag the app to Applications
3. Eject the DMG
4. Launch from Applications
5. First time: Right-click > Open (security requirement)

## Next Steps

### For Users
Share the **INSTALL.md** file along with the DMG. It contains:
- Step-by-step installation instructions
- LM Studio setup guide
- Troubleshooting tips
- Usage examples

### For Developers
See **CLAUDE.md** for:
- Architecture details
- Development workflow
- Build commands
- Code structure

### For Distribution
Consider creating:
- GitHub Release with the DMG attached
- Website with download link
- Homebrew formula for easy installation
- Screenshots and demo video

## Support Information

Include this information when distributing:

**System Requirements:**
- macOS 14.0 (Sonoma) or later
- 8GB RAM minimum (16GB recommended)
- ~10GB storage for LM Studio and models

**External Dependencies:**
- LM Studio (free from https://lmstudio.ai)
- Vision-capable AI model (e.g., qwen2.5-vl-7b)

**Getting Help:**
- Documentation: README.md and INSTALL.md
- Issues: GitHub Issues page
- LM Studio support: https://lmstudio.ai/docs

---

**Created with the create_dmg.sh script**
**Copyright © 2024. All rights reserved.**
