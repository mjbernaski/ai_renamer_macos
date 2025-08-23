#!/bin/bash

echo "🚀 AI Image Renamer Installation Script"
echo "======================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please don't run this script as root (without sudo)${NC}"
   echo "The script will ask for sudo password when needed."
   exit 1
fi

echo "This script will:"
echo "1. Copy the AI Image Renamer app to /Applications"
echo "2. Install the 'ai-renamer' command to /usr/local/bin"
echo ""
echo -e "${YELLOW}You will be prompted for your password.${NC}"
echo ""

# Step 1: Copy app to Applications
echo "📦 Installing AI Image Renamer.app to /Applications..."
if [ -d "AI Image Renamer.app" ]; then
    # Remove old version if it exists
    if [ -d "/Applications/AI Image Renamer.app" ]; then
        echo "   Removing old version..."
        sudo rm -rf "/Applications/AI Image Renamer.app"
    fi
    
    # Copy new version
    sudo cp -R "AI Image Renamer.app" /Applications/
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✅ App installed successfully!${NC}"
    else
        echo -e "${RED}   ❌ Failed to install app${NC}"
        exit 1
    fi
else
    echo -e "${RED}   ❌ AI Image Renamer.app not found in current directory${NC}"
    echo "   Please run this script from the project directory."
    exit 1
fi

# Step 2: Install CLI command
echo ""
echo "🔧 Installing 'ai-renamer' command..."
if [ -f "ai-renamer" ]; then
    sudo cp ai-renamer /usr/local/bin/
    sudo chmod +x /usr/local/bin/ai-renamer
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✅ CLI command installed successfully!${NC}"
    else
        echo -e "${RED}   ❌ Failed to install CLI command${NC}"
        exit 1
    fi
else
    echo -e "${RED}   ❌ ai-renamer script not found${NC}"
    exit 1
fi

# Step 3: Verify installation
echo ""
echo "🔍 Verifying installation..."
if [ -d "/Applications/AI Image Renamer.app" ] && [ -f "/usr/local/bin/ai-renamer" ]; then
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo ""
    echo "📝 Usage:"
    echo "   GUI Mode:"
    echo "      • Open from Applications folder"
    echo "      • Or run: open '/Applications/AI Image Renamer.app'"
    echo "      • Or run: ai-renamer"
    echo ""
    echo "   CLI Mode:"
    echo "      • ai-renamer --cli file1.jpg file2.png"
    echo "      • ai-renamer --cli *.jpg --dry-run"
    echo "      • ai-renamer --help"
    echo ""
    echo "🎉 Enjoy using AI Image Renamer!"
else
    echo -e "${RED}❌ Installation verification failed${NC}"
    exit 1
fi