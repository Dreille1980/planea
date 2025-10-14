#!/bin/bash

# Planea Setup Script
# This script helps set up and run the Planea iOS app

set -e

echo "🍽️  Planea Setup Script"
echo "======================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip first."
    exit 1
fi

echo "✅ pip3 found"

# Install Python dependencies
echo ""
echo "📦 Installing Python dependencies..."
cd mock-server
pip3 install -r requirements.txt
cd ..

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Start the mock server:"
echo "   cd mock-server && uvicorn main:app --reload --port 8000"
echo ""
echo "2. Open Xcode:"
echo "   - Open Xcode"
echo "   - Create a new iOS App project named 'Planea'"
echo "   - Set minimum deployment target to iOS 16.0"
echo "   - Add all files from Planea-iOS/ to the project"
echo "   - Add Localizable.strings files to the project"
echo "   - Build and run (Cmd+R)"
echo ""
echo "3. Or if you have the .xcodeproj:"
echo "   open Planea-iOS/Planea.xcodeproj"
echo ""
echo "📖 See README.md for detailed instructions"
echo ""
