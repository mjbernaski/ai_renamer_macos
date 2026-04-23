# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI Image Renamer for macOS - A native Swift application that uses AI to intelligently rename images and PDFs based on their content. It connects to a local LM Studio instance running a vision-capable model.

## Architecture

### Core Components

- **main.swift**: Entry point using ArgumentParser. Special handling: when launched with no arguments, directly instantiates NSApplication for GUI mode (bypassing ArgumentParser). With arguments, uses ParsableCommand to route to CLI/GUI modes
- **LMStudioClient.swift**: HTTP client for LM Studio's local API. Handles both vision model requests (base64-encoded images) and text-based PDF analysis. Uses URLSession for async HTTP requests. Includes JSON response parsing with multiple extraction strategies (markdown code blocks, brace matching, fallback text parsing)
- **FileProcessor.swift**: CLI-only processor with interactive user approval workflow. Handles file collection (including recursive directory scanning), dry-run mode, and auto-approval mode. Uses semaphore for async/sync coordination
- **ContentView.swift**: SwiftUI interface with adaptive layout - switches between compact (200x150) and expanded (400x500) window modes. Uses @StateObject with ContentViewModel for state management. Implements drag-and-drop via NSItemProvider
- **AppDelegate.swift**: NSApplicationDelegate that manages window lifecycle and animated window resizing. Listens for expand/collapse notifications from ContentViewModel

### Key Design Patterns

- **Dual interface with shared backend**: Both CLI (FileProcessor) and GUI (ContentViewModel) use the same LMStudioClient, ensuring consistent AI behavior
- **Entry point routing**: main.swift has special logic - no args = direct GUI launch, any args = ArgumentParser routing
- **Adaptive UI**: ContentView morphs between compact drop zone and full interface based on file selection state. Window animations coordinated via NotificationCenter
- **Filename conflict resolution**: Both processors implement identical sequence numbering logic (_1, _2, etc.) with timestamp fallback
- **JSON extraction resilience**: LMStudioClient tries multiple parsing strategies since LLM responses may include markdown formatting or explanatory text
- **Model selection preference**: Auto-selects qwen2.5-vl-7b if available, falls back to first available model
- **Async/await coordination**: FileProcessor.runCLISync uses DispatchSemaphore to bridge async client calls into synchronous CLI context

## Development Commands

### Building
```bash
# Release build
make build
# or
swift build -c release

# Debug build  
make debug
# or
swift build
```

### Running
```bash
# GUI mode (default)
make run
# or
./.build/release/AIImageRenamer

# CLI mode
make run-cli FILES="*.jpg *.png"
# or
./.build/release/AIImageRenamer --cli file1.jpg file2.pdf

# Development run (debug)
make run-debug
# or
swift run AIImageRenamer
```

### Testing & Quality
```bash
# Run tests
make test
# or
swift test

# Format code (requires swiftformat)
make format

# Lint code (requires swiftlint)  
make lint

# Clean build artifacts
make clean
# or
swift package clean
```

### Installation
```bash
# Install to /usr/local/bin
make install

# Uninstall
make uninstall
```

## LM Studio Integration

The app expects LM Studio running locally on `127.0.0.1:1234` (configurable via `--host` and `--port` flags).

### API Endpoints
- `/v1/models` - Fetched during testConnection() to discover available models and set currentModel
- `/v1/chat/completions` - POST requests for both image and PDF analysis

### Request Flow
1. **Image processing**: NSImage → TIFF → NSBitmapImageRep → JPEG → base64 string, sent in `image_url` content type
2. **PDF processing**: PDFDocument → extract first 3 pages of text (max 2000 chars) → send as text prompt
3. **Response parsing**: Expects JSON with `suggested_filename`, `reasoning`, `confidence`. Parser handles markdown code blocks (```json), plain JSON objects, and fallback text extraction

### Prompt Engineering
- Images: Requests descriptive filenames under 50 chars, letters/numbers/spaces/hyphens/underscores only
- PDFs: Same constraints plus consideration of document type (report, manual, invoice)
- Temperature: 0.3 for consistent, focused responses
- Max tokens: 300

## Dependencies

- **swift-argument-parser**: CLI argument parsing
- **SwiftSoup**: HTML parsing (for potential future features)

Managed via Swift Package Manager in `Package.swift`.

## Platform Requirements

- macOS 14.0+ (Sonoma)
- Swift 5.9+
- Xcode 15.0+ for building
- LM Studio with vision-capable model (e.g., qwen2.5-vl-7b)

## Implementation Notes

### File Type Detection
FileType enum in LMStudioClient.swift maps extensions to .image or .pdf. Supported image formats: jpg, jpeg, png, gif, bmp, tiff. Both processors validate files using the same extension set.

### Filename Sanitization
The sanitizeFilename() method in LMStudioClient.swift:
- Removes invalid chars: `<>:"/\|?*`
- Replaces whitespace with underscores
- Trims leading/trailing dots and spaces
- Limits to 50 characters
- Ensures non-empty (defaults to "renamed_file")

This sanitization is applied to all AI suggestions before the filename reaches the processors.

### State Management
- **GUI**: ContentViewModel uses @Published properties. canProcess requires files AND connection. canRename requires valid suggestions. Window expand/collapse triggered by isExpanded property changes
- **CLI**: FileProcessor is stateless, processes sequentially. Uses Foundation.exit() for error conditions

### Debugging LM Studio Issues
If connection or parsing fails, LMStudioClient prints diagnostic info:
- Connection errors from testConnection()
- Raw response content preview (first 200 chars) when JSON parsing fails
- Request body preview when HTTP requests fail

These print statements are the primary debugging mechanism - no formal logging framework is used.