# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI Image Renamer for macOS - A native Swift application that uses AI to intelligently rename images and PDFs based on their content. It connects to a local LM Studio instance running a vision-capable model.

## Architecture

### Core Components

- **main.swift**: Entry point using ArgumentParser for CLI handling. Routes to either GUI or CLI mode based on arguments
- **LMStudioClient.swift**: HTTP client for LM Studio's local API. Handles vision model requests for images and text extraction for PDFs
- **FileProcessor.swift**: CLI mode processing logic with dry-run support and user approval workflows
- **ContentView.swift**: SwiftUI interface with drag-and-drop functionality and batch processing
- **AppDelegate.swift**: macOS app lifecycle management

### Key Design Patterns

- Dual interface approach: Both CLI and GUI share the same LMStudioClient backend
- Vision model communication via base64 encoded images sent to LM Studio's `/v1/chat/completions` endpoint
- Automatic duplicate filename handling with sequence numbering
- Sanitized filename generation that removes special characters and spaces

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

Key endpoints used:
- `/v1/models` - Check available models
- `/v1/chat/completions` - Send image/text for analysis

For images, the app sends base64-encoded data with vision model prompts. For PDFs, it extracts text using PDFKit and sends it as regular text content.

## Dependencies

- **swift-argument-parser**: CLI argument parsing
- **SwiftSoup**: HTML parsing (for potential future features)

Managed via Swift Package Manager in `Package.swift`.

## Platform Requirements

- macOS 14.0+ (Sonoma)
- Swift 5.9+
- Xcode 15.0+ for building
- LM Studio with vision-capable model (e.g., qwen2.5-vl-7b)