#!/usr/bin/env node

/**
 * Preprocessing script to convert the dynamic Node.js app to static files
 * This script reads the large CSV file and generates individual JSON files
 * for each drug combination that can be served statically.
 */

console.log("Static preprocessing starting...");

const fs = require("fs");
const path = require("path");
const d3 = require("d3");

// Configuration
const INPUT_CSV = './combo_all_combos2.csv';
const OUTPUT_DIR = '../hugo-site/static/data/combinations';
const RANKING_CSV = './combo_ranking_n.syn_score_web.csv';
const RANKING_OUTPUT = '../hugo-site/static/data/combo_ranking_n.syn_score_web.csv';

// Ensure output directory exists
function ensureDirectoryExists(dirPath) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
        console.log(`Created directory: ${dirPath}`);
    }
}

// Function to create a safe filename from drug names
function createSafeFilename(drug1, drug2) {
    const sanitize = (name) => name.replace(/[^a-zA-Z0-9-_]/g, '_');
    return `${sanitize(drug1)}_${sanitize(drug2)}.json`;
}

// Main preprocessing function
function preprocessData() {
    try {
        // Check if input file exists
        if (!fs.existsSync(INPUT_CSV)) {
            console.error(`Error: Input file ${INPUT_CSV} not found.`);
            console.log("Please ensure the combo_all_combos2.csv file is in the same directory as this script.");
            process.exit(1);
        }

        console.log("Loading CSV file...");
        const csvContent = fs.readFileSync(INPUT_CSV, 'utf8');
        console.log(`File loaded. Length in characters: ${csvContent.length}`);
        
        console.log("Parsing CSV (using d3.csv.parse)...");
        const data = d3.csv.parse(csvContent);
        console.log(`File parsed. Number of rows: ${data.length}`);

        // Create the same indexing structure as the original server
        const indar = {};
        console.log("Creating drug combination index...");
        
        for (let k = 0; k < data.length; k++) {
            const key = `${data[k].Drug1}_${data[k].Drug2}`;
            if (indar[key] !== undefined) {
                indar[key].push(data[k]);
            } else {
                indar[key] = [data[k]];
            }
        }

        console.log(`Created index with ${Object.keys(indar).length} unique drug combinations`);

        // Ensure output directory exists
        ensureDirectoryExists(OUTPUT_DIR);

        // Generate static files for each combination
        console.log("Generating static JSON files...");
        let fileCount = 0;
        
        for (const [key, combData] of Object.entries(indar)) {
            const [drug1, drug2] = key.split('_');
            const filename = createSafeFilename(drug1, drug2);
            const filePath = path.join(OUTPUT_DIR, filename);
            
            // Create the same CSV format as the original server would return
            const csvFormat = d3.csv.format(combData);
            
            // Save both CSV format and JSON format
            const outputData = {
                drug1: drug1,
                drug2: drug2,
                csvData: csvFormat,
                jsonData: combData,
                recordCount: combData.length
            };
            
            fs.writeFileSync(filePath, JSON.stringify(outputData, null, 2));
            fileCount++;
            
            if (fileCount % 100 === 0) {
                console.log(`Generated ${fileCount} files...`);
            }
        }

        console.log(`Successfully generated ${fileCount} static files in ${OUTPUT_DIR}`);

        // Copy ranking file if it exists
        if (fs.existsSync(RANKING_CSV)) {
            console.log("Copying ranking CSV file...");
            ensureDirectoryExists(path.dirname(RANKING_OUTPUT));
            fs.copyFileSync(RANKING_CSV, RANKING_OUTPUT);
            console.log(`Ranking file copied to ${RANKING_OUTPUT}`);
        } else {
            console.warn(`Warning: Ranking file ${RANKING_CSV} not found. You may need to copy it manually.`);
        }

        // Generate a manifest file with all available combinations
        const manifestPath = path.join(path.dirname(OUTPUT_DIR), 'combinations_manifest.json');
        const manifest = {
            totalCombinations: Object.keys(indar).length,
            combinations: Object.keys(indar).map(key => {
                const [drug1, drug2] = key.split('_');
                return {
                    key: key,
                    drug1: drug1,
                    drug2: drug2,
                    filename: createSafeFilename(drug1, drug2),
                    recordCount: indar[key].length
                };
            }),
            generatedAt: new Date().toISOString()
        };
        
        fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
        console.log(`Manifest file created at ${manifestPath}`);

        console.log("Preprocessing completed successfully!");
        
    } catch (error) {
        console.error("Error during preprocessing:", error);
        process.exit(1);
    }
}

// Run the preprocessing
if (require.main === module) {
    preprocessData();
}

module.exports = { preprocessData, createSafeFilename };
