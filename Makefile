# AI Image Renamer for macOS - Makefile

.PHONY: build run clean install test help

# Default target
help:
	@echo "AI Image Renamer for macOS - Build System"
	@echo "========================================="
	@echo ""
	@echo "Available targets:"
	@echo "  build       - Build the application in release mode"
	@echo "  debug       - Build the application in debug mode"
	@echo "  run         - Run the application (GUI mode)"
	@echo "  run-cli     - Run the application in CLI mode with sample files"
	@echo "  clean       - Clean build artifacts"
	@echo "  install     - Install to /usr/local/bin"
	@echo "  uninstall   - Remove from /usr/local/bin"
	@echo "  test        - Run tests (when available)"
	@echo "  format      - Format Swift code"
	@echo "  lint        - Lint Swift code"
	@echo "  deps        - Show dependencies"
	@echo "  help        - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make run"
	@echo "  make run-cli FILES='*.jpg *.png'"
	@echo "  make install"

# Build targets
build:
	@echo "🔨 Building AI Image Renamer (Release)..."
	swift build -c release
	@echo "✅ Build complete! Binary: ./.build/release/AIImageRenamer"

debug:
	@echo "🔨 Building AI Image Renamer (Debug)..."
	swift build
	@echo "✅ Debug build complete! Binary: ./.build/debug/AIImageRenamer"

# Run targets
run: build
	@echo "🚀 Launching AI Image Renamer (GUI mode)..."
	./.build/release/AIImageRenamer

run-cli: build
	@echo "🚀 Running AI Image Renamer (CLI mode)..."
	@if [ -n "$(FILES)" ]; then \
		./.build/release/AIImageRenamer --cli $(FILES); \
	else \
		echo "Usage: make run-cli FILES='file1.jpg file2.png'"; \
		echo "Or try: make run-cli FILES='*.jpg'"; \
	fi

run-debug:
	@echo "🚀 Running AI Image Renamer (Debug mode)..."
	swift run AIImageRenamer

# Installation targets
install: build
	@echo "📦 Installing AI Image Renamer to /usr/local/bin..."
	@sudo cp ./.build/release/AIImageRenamer /usr/local/bin/ai-renamer
	@sudo chmod +x /usr/local/bin/ai-renamer
	@echo "✅ Installed! You can now run 'ai-renamer' from anywhere."
	@echo "   GUI mode: ai-renamer"
	@echo "   CLI mode: ai-renamer --cli *.jpg"

uninstall:
	@echo "🗑️  Removing AI Image Renamer from /usr/local/bin..."
	@sudo rm -f /usr/local/bin/ai-renamer
	@echo "✅ Uninstalled!"

# Development targets
clean:
	@echo "🧹 Cleaning build artifacts..."
	swift package clean
	@echo "✅ Clean complete!"

test:
	@echo "🧪 Running tests..."
	swift test

format:
	@echo "🎨 Formatting Swift code..."
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat Sources/; \
		echo "✅ Code formatted!"; \
	else \
		echo "⚠️  swiftformat not found. Install with: brew install swiftformat"; \
	fi

lint:
	@echo "🔍 Linting Swift code..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
		echo "✅ Linting complete!"; \
	else \
		echo "⚠️  swiftlint not found. Install with: brew install swiftlint"; \
	fi

deps:
	@echo "📦 Package dependencies:"
	@swift package show-dependencies

# Utility targets
check-lmstudio:
	@echo "🔍 Checking LM Studio connection..."
	@curl -s http://127.0.0.1:1234/v1/models | jq . || echo "❌ LM Studio not running or jq not installed"

demo: build
	@echo "🎬 Running demo with sample files..."
	@echo "Creating sample files for demo..."
	@mkdir -p demo_files
	@echo "This is a sample PDF content for testing." > demo_files/sample.txt
	@echo "📝 Demo files created in ./demo_files/"
	@echo "🚀 Running AI Image Renamer..."
	./.build/release/AIImageRenamer --cli demo_files/* --dry-run || echo "Add some image files to demo_files/ to test"

# Development setup
setup:
	@echo "🛠️  Setting up development environment..."
	@echo "Checking Swift version..."
	@swift --version
	@echo "Checking for recommended tools..."
	@command -v swiftformat >/dev/null 2>&1 || echo "📝 Consider installing swiftformat: brew install swiftformat"
	@command -v swiftlint >/dev/null 2>&1 || echo "📝 Consider installing swiftlint: brew install swiftlint"
	@command -v jq >/dev/null 2>&1 || echo "📝 Consider installing jq for JSON parsing: brew install jq"
	@echo "✅ Setup check complete!"

# Package and distribution
package: build
	@echo "📦 Creating distribution package..."
	@mkdir -p dist
	@cp ./.build/release/AIImageRenamer dist/
	@cp README.md dist/
	@tar -czf dist/ai-image-renamer-macos.tar.gz -C dist AIImageRenamer README.md
	@echo "✅ Package created: dist/ai-image-renamer-macos.tar.gz"

# Quick development cycle
dev: clean debug run-debug

# Show system info
info:
	@echo "System Information:"
	@echo "=================="
	@echo "macOS Version: $$(sw_vers -productVersion)"
	@echo "Swift Version: $$(swift --version | head -1)"
	@echo "Xcode Version: $$(xcodebuild -version | head -1 2>/dev/null || echo 'Xcode not found')"
	@echo "Architecture: $$(uname -m)"
	@echo ""
	@echo "Build Information:"
	@echo "=================="
	@echo "Build Directory: ./.build"
	@echo "Source Directory: ./Sources"
	@echo "Package File: ./Package.swift"
