#!/bin/bash

# Development script for testing the static synergy screen website with sample data

echo "🧪 Synergy Screen - Development Mode"
echo "====================================="

# Create sample data files for testing
echo "📋 Creating sample data files for testing..."

mkdir -p static_preprocessing/

# Create a minimal sample CSV file for testing
cat > static_preprocessing/combo_all_combos2.csv << 'EOF'
Drug1,Drug2,cell.line2,viab,conc,padj,est.log.sing1,est.log.sing2,sd.log.sing1,sd.log.sing2,noise.control.log
Drug_A,Drug_B,Cell_Line_1,0.75,high,0.02,-0.5,-0.3,0.1,0.15,0.05
Drug_A,Drug_B,Cell_Line_1,0.80,low,0.08,-0.4,-0.25,0.12,0.18,0.06
Drug_A,Drug_B,Cell_Line_2,0.65,high,0.01,-0.6,-0.4,0.09,0.14,0.04
Drug_A,Drug_B,Cell_Line_2,0.70,low,0.15,-0.45,-0.35,0.11,0.16,0.05
Drug_C,Drug_D,Cell_Line_1,0.85,high,0.20,-0.2,-0.1,0.08,0.12,0.03
Drug_C,Drug_D,Cell_Line_1,0.90,low,0.50,-0.15,-0.05,0.10,0.14,0.04
Drug_C,Drug_D,Cell_Line_2,0.80,high,0.12,-0.25,-0.15,0.09,0.13,0.035
Drug_C,Drug_D,Cell_Line_2,0.85,low,0.30,-0.20,-0.10,0.11,0.15,0.045
EOF

# Create sample ranking CSV
cat > static_preprocessing/combo_ranking_n.syn_score_web.csv << 'EOF'
Drug1,Drug2,Drug.num1,Drug.num2,Drug1.target,Drug2.target,absolute.synergy.score,specificity.score
Drug_A,Drug_B,1,2,Target_A,Target_B,15,0.75
Drug_C,Drug_D,2,1,Target_C,Target_D,8,0.45
EOF

echo "✅ Sample data created"

# Check for Hugo
if ! command -v hugo &> /dev/null; then
    echo "❌ Error: Hugo is not installed"
    echo "   Please install Hugo: https://gohugo.io/installation/"
    echo "   macOS: brew install hugo"
    echo "   Linux: sudo apt install hugo"
    exit 1
fi

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js is not installed"
    echo "   Please install Node.js: https://nodejs.org/"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Install dependencies and run preprocessing
echo ""
echo "📦 Installing dependencies and preprocessing data..."
cd static_preprocessing/
npm install
npm run preprocess

if [ $? -ne 0 ]; then
    echo "❌ Preprocessing failed"
    exit 1
fi

cd ..

# Start development server
echo ""
echo "🚀 Starting Hugo development server..."
echo "   Site will be available at: http://localhost:1313"
echo "   Press Ctrl+C to stop"
echo ""

cd hugo-site/
hugo server --buildDrafts --bind 0.0.0.0
