#!/bin/bash

# Static preprocessing script for synergy-screen
# This script must be run before starting Hugo to generate the static data files

set -e  # Exit on any error

echo "🔄 Starting static preprocessing for synergy-screen..."

# Check if we're in the right directory
if [ ! -f "preprocess_modern.js" ]; then
    echo "❌ Error: preprocess_modern.js not found. Please run this script from the static_preprocessing directory."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
else
    echo "✅ Dependencies already installed"
fi

# Run the preprocessing
echo "⚙️  Running data preprocessing..."
npm run preprocess

echo "✅ Static preprocessing completed successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Navigate to the hugo-site directory: cd ../hugo-site"
echo "   2. Start Hugo development server: hugo server"
echo "   3. Or build static site: hugo"
