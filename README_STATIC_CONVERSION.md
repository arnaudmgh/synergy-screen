# Static Website Conversion for Synergy Screen

This branch converts the dynamic Node.js web application to a static Hugo website.

## Structure

- `static_preprocessing/` - Scripts to convert dynamic data to static files
- `hugo-site/` - Hugo static site source code
- `publish_R/combo_web/` - Original Node.js application (preserved for reference)

## Prerequisites

1. **Hugo** - Install Hugo static site generator:
   ```bash
   # macOS (with Homebrew)
   brew install hugo
   
   # Linux (with apt)
   sudo apt install hugo
   
   # Or download from https://gohugo.io/installation/
   ```

2. **Node.js and npm** - For running the preprocessing script:
   ```bash
   # Install Node.js from https://nodejs.org/
   # Or use a package manager like nvm, brew, etc.
   ```

## Setup Instructions

### Step 1: Prepare the Data Files

The original application requires two CSV files that are not included in this repository:
- `combo_all_combos2.csv` - The main combination data (referenced in server.js)
- `combo_ranking_n.syn_score_web.csv` - The ranking data for the heatmap

You'll need to:
1. Locate or generate these CSV files from your R analysis
2. Place `combo_all_combos2.csv` in the `static_preprocessing/` directory
3. Place `combo_ranking_n.syn_score_web.csv` in the `static_preprocessing/` directory

### Step 2: Run the Preprocessing Script

```bash
cd static_preprocessing/
npm install
npm run preprocess
```

This will:
- Read the large CSV file
- Create individual JSON files for each drug combination
- Generate a manifest file with all available combinations
- Copy the ranking CSV to the Hugo static directory

### Step 3: Build and Serve the Hugo Site

```bash
cd hugo-site/
hugo server --buildDrafts
```

The site will be available at `http://localhost:1313`

To build for production:
```bash
hugo --minify
```

The built site will be in the `public/` directory.

## How the Conversion Works

### Original Dynamic App
- Loaded ~500,000 rows of data into memory on server startup
- Created an index (`indar`) for fast lookup by drug combination
- Served specific combinations via API endpoints `/q` and `/seecsv`
- Frontend made AJAX requests to get combination data

### New Static App
- Preprocessing script creates individual JSON files for each drug combination
- Files are named using sanitized drug names: `Drug1_name_Drug2_name.json`
- Each file contains both CSV and JSON formats of the combination data
- Frontend loads files directly using D3.js without server requests
- Ranking data is served as a static CSV file

### File Structure After Processing
```
hugo-site/
├── static/
│   ├── data/
│   │   ├── combinations/          # Individual drug combination files
│   │   │   ├── Drug1_Drug2.json
│   │   │   └── ...
│   │   ├── combinations_manifest.json
│   │   └── combo_ranking_n.syn_score_web.csv
│   └── js/
│       ├── d3.v3.js
│       └── synergy_plots_static.js
```

## Key Changes from Original

1. **Data Loading**: Instead of server API calls, data is loaded from static JSON files
2. **Error Handling**: Frontend tries both `Drug1_Drug2.json` and `Drug2_Drug1.json` filenames
3. **File Naming**: Drug names are sanitized to create valid filenames
4. **Preprocessing**: One-time conversion of large dataset to individual files
5. **No Server**: Pure static site that can be hosted on any web server or CDN

## Deployment

The built Hugo site can be deployed to:
- GitHub Pages
- Netlify
- Vercel  
- AWS S3 + CloudFront
- Any static web hosting service

## Troubleshooting

1. **Missing CSV files**: Ensure `combo_all_combos2.csv` and `combo_ranking_n.syn_score_web.csv` are in the `static_preprocessing/` directory before running the preprocessing script.

2. **Hugo not found**: Install Hugo using the instructions above.

3. **Large file sizes**: The preprocessing will generate many small files. Consider compression and CDN usage for production deployment.

4. **CORS issues in development**: Use `hugo server` rather than opening files directly in browser.

## Development

To modify the visualization:
1. Edit `hugo-site/layouts/_default/baseof.html` for the main layout
2. Edit `hugo-site/static/js/synergy_plots_static.js` for plotting logic
3. Edit `hugo-site/content/_index.md` for page content
4. Rebuild with `hugo server` to see changes
