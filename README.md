# AI Image Renamer for macOS

A native macOS application written in Swift that uses AI to intelligently rename image and PDF files based on their content. This is a complete rewrite of the original Python version, optimized for macOS with native performance and UI.

## 🚀 Features

- **Native macOS App**: Built with SwiftUI for optimal performance and native look & feel
- **AI-Powered Renaming**: Uses LM Studio's local API to analyze content and suggest meaningful filenames
- **Dual Interface**: Both GUI and command-line interfaces available
- **File Support**: Images (JPG, PNG, GIF, BMP, TIFF) and PDFs
- **Drag & Drop**: Native macOS drag-and-drop support
- **Batch Processing**: Process multiple files at once
- **Smart Filename Generation**: Sanitized filenames that work well on macOS
- **Sequence Numbering**: Automatic handling of duplicate filenames
- **Dry Run Mode**: Preview changes before applying them

## 📋 Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9 or later
- Xcode 15.0 or later (for building from source)
- [LM Studio](https://lmstudio.ai) running locally with a vision-capable model

## 🛠️ Installation

### Option 1: Build from Source

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd ai_renamer_macos
   ```

2. **Build the application:**
   ```bash
   swift build -c release
   ```

3. **Run the application:**
   ```bash
   # GUI mode (default)
   ./.build/release/AIImageRenamer
   
   # CLI mode
   ./.build/release/AIImageRenamer --cli file1.jpg file2.png
   ```

### Option 2: Using Swift Package Manager

You can also run directly with SPM:
```bash
swift run AIImageRenamer
```

## 🎮 Usage

### GUI Mode (Default)

Launch the application without any arguments to open the graphical interface:

```bash
./AIImageRenamer
```

**How to use:**
1. Launch the application
2. Drag and drop files onto the drop zone, or click "Select Files"
3. Click "🤖 Get AI Suggestions" to analyze your files
4. Review the suggested filenames and reasoning
5. Click "✅ Rename Files" to apply the changes
6. Confirm the rename operation

### CLI Mode

Use the `--cli` flag for command-line operation:

```bash
# Process specific files
./AIImageRenamer --cli image1.jpg document.pdf

# Process with wildcards
./AIImageRenamer --cli *.jpg *.png

# Process entire directory
./AIImageRenamer --cli /path/to/images/

# Dry run (preview changes)
./AIImageRenamer --cli *.jpg --dry-run

# Auto-approve all suggestions
./AIImageRenamer --cli *.* --auto-approve

# Custom LM Studio connection
./AIImageRenamer --cli *.jpg --host 192.168.1.100 --port 8080
```

### Command Line Options

```
USAGE: ai-renamer [<files> ...] [--cli] [--host <host>] [--port <port>] [--dry-run] [--auto-approve]

ARGUMENTS:
  <files>                 Files to process (CLI mode only)

OPTIONS:
  -c, --cli               Run in command-line mode (no GUI)
  -h, --host <host>       LM Studio host (default: 127.0.0.1)
  -p, --port <port>       LM Studio port (default: 1234)
  --dry-run               Show what would be renamed without actually renaming
  --auto-approve          Auto-approve all suggestions (CLI mode only)
  --help                  Show help information.
```

## 🧠 AI Models

The application works with vision-capable models in LM Studio such as:
- `qwen/qwen2.5-vl-7b` (recommended)
- `llava` variants
- Other multimodal models that support image analysis

For PDF processing, any text-capable model will work.

## 🔧 Configuration

### LM Studio Setup

1. **Install LM Studio**: Download from [lmstudio.ai](https://lmstudio.ai)
2. **Load a Model**: Choose a vision-capable model
3. **Start Local Server**: Enable the local server (usually runs on port 1234)
4. **Verify Connection**: The app will show connection status on startup

### Custom Host/Port

If LM Studio is running on a different host or port:

```bash
# GUI mode
./AIImageRenamer --host 192.168.1.100 --port 8080

# CLI mode
./AIImageRenamer --cli *.jpg --host localhost --port 1235
```

## 📁 Project Structure

```
ai_renamer_macos/
├── Package.swift                 # Swift Package Manager configuration
├── Sources/
│   ├── main.swift               # Main entry point and argument parsing
│   ├── LMStudioClient.swift     # HTTP client for LM Studio API
│   ├── FileProcessor.swift      # CLI file processing logic
│   ├── AppDelegate.swift        # macOS app delegate
│   └── ContentView.swift        # SwiftUI main interface
└── README.md                    # This file
```

## 🎯 Key Improvements over Python Version

- **Native Performance**: Swift compilation provides better performance
- **Native UI**: SwiftUI provides authentic macOS look and feel
- **Better File Handling**: Uses native macOS file APIs
- **Improved Drag & Drop**: Native macOS drag-and-drop implementation
- **Memory Efficiency**: Better memory management than Python version
- **No Dependencies**: Minimal external dependencies, easier deployment
- **Code Signing Ready**: Can be easily code-signed for distribution

## 🔍 Troubleshooting

**Connection Issues:**
- Ensure LM Studio is running and the local server is enabled
- Check that the correct host/port is being used (default: 127.0.0.1:1234)
- Verify a vision-capable model is loaded for image processing

**Build Issues:**
- Ensure you have Xcode 15.0+ installed
- Make sure you're running macOS 13.0+
- Try cleaning and rebuilding: `swift package clean && swift build`

**File Processing Issues:**
- Ensure files have supported extensions (.jpg, .png, .gif, .bmp, .tiff, .pdf)
- Check file permissions - the app needs read/write access
- For PDF processing, ensure the PDF contains extractable text

## 📄 License

This project is open source. Use and modify as needed for your projects.

## 🤝 Contributing

Feel free to submit issues, feature requests, or pull requests to improve this application.

## 🔄 Migration from Python Version

This Swift version provides the same core functionality as the original Python version but with native macOS integration:

- **GUI**: SwiftUI replaces tkinter for better native integration
- **HTTP Client**: Native URLSession replaces requests library
- **File Operations**: Native FileManager replaces Python file operations
- **Image Processing**: Native NSImage replaces PIL
- **PDF Processing**: Native PDFKit replaces pdfplumber
- **CLI**: ArgumentParser replaces argparse

The API compatibility with LM Studio remains the same, so existing LM Studio setups will work without changes.
