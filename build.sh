#!/bin/bash

# Build script for the static synergy screen website

echo "🔬 Synergy Screen - Static Website Builder"
echo "=========================================="

# Check if required files exist
echo "📋 Checking prerequisites..."

if [ ! -f "static_preprocessing/combo_all_combos2.csv" ]; then
    echo "❌ Error: combo_all_combos2.csv not found in static_preprocessing/"
    echo "   Please copy this file from your R analysis output"
    exit 1
fi

if [ ! -f "static_preprocessing/combo_ranking_n.syn_score_web.csv" ]; then
    echo "⚠️  Warning: combo_ranking_n.syn_score_web.csv not found in static_preprocessing/"
    echo "   The heatmap may not work without this file"
fi

# Check for Hugo
if ! command -v hugo &> /dev/null; then
    echo "❌ Error: Hugo is not installed"
    echo "   Please install Hugo: https://gohugo.io/installation/"
    exit 1
fi

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js is not installed"
    echo "   Please install Node.js: https://nodejs.org/"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Step 1: Install preprocessing dependencies
echo ""
echo "📦 Installing preprocessing dependencies..."
cd static_preprocessing/
npm install

# Step 2: Run preprocessing
echo ""
echo "🔄 Running data preprocessing..."
npm run preprocess

if [ $? -ne 0 ]; then
    echo "❌ Preprocessing failed"
    exit 1
fi

cd ..

# Step 3: Build Hugo site
echo ""
echo "🏗️  Building Hugo site..."
cd hugo-site/

if [ "$1" = "dev" ]; then
    echo "🚀 Starting development server..."
    hugo server --buildDrafts --bind 0.0.0.0
else
    echo "📦 Building production site..."
    hugo --minify
    echo "✅ Build complete! Static site is in hugo-site/public/"
    echo ""
    echo "🚀 To preview locally, run:"
    echo "   cd hugo-site && hugo server"
    echo ""
    echo "📤 To deploy, upload the contents of hugo-site/public/ to your web server"
fi
