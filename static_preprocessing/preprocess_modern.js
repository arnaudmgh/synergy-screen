#!/usr/bin/env node

/**
 * Modern preprocessing script to convert the dynamic Node.js app to static files
 * This script reads the large CSV file and generates individual JSON files
 * for each drug combination that can be served statically.
 */

console.log("Static preprocessing starting...");

const fs = require("fs");
const path = require("path");
const csv = require('csv-parser');
const createCsvWriter = require('csv-writer').createObjectCsvWriter;

// Configuration
const INPUT_CSV = './combo_all_combos2.csv';
const OUTPUT_DIR = '../hugo-site/static/data/combinations';
const RANKING_CSV = './combo_ranking_n.syn_score_web.csv';
const RANKING_OUTPUT = '../hugo-site/static/data/combo_ranking_n.syn_score_web.csv';

// Alternative input files to check
const ALTERNATIVE_INPUTS = [
    './combo_all_combos2.csv',
    '../publish_R/combo_web/combo_all_combos2.csv'
];

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

// Convert array of objects to CSV string
function arrayToCsvString(data) {
    if (data.length === 0) return '';
    
    const headers = Object.keys(data[0]);
    const csvRows = [headers.join(',')];
    
    for (const row of data) {
        const values = headers.map(header => {
            const value = row[header];
            // Handle values that might contain commas or quotes
            if (typeof value === 'string' && (value.includes(',') || value.includes('"'))) {
                return `"${value.replace(/"/g, '""')}"`;
            }
            return value;
        });
        csvRows.push(values.join(','));
    }
    
    return csvRows.join('\n');
}

// Find available input file
function findInputFile() {
    for (const file of ALTERNATIVE_INPUTS) {
        if (fs.existsSync(file)) {
            console.log(`Found input file: ${file}`);
            return file;
        }
    }
    return null;
}

// Main preprocessing function
async function preprocessData() {
    try {
        // Find input file
        const inputFile = findInputFile();
        if (!inputFile) {
            console.error("Error: No input CSV file found.");
            console.log("Looked for files:");
            ALTERNATIVE_INPUTS.forEach(file => console.log(`  - ${file}`));
            console.log("\nPlease ensure one of these CSV files exists.");
            
            // Create a sample file for testing
            console.log("\nCreating a sample CSV file for testing...");
            const sampleData = [
                { Drug1: 'Aspirin', Drug2: 'Ibuprofen', Dose1: '100', Dose2: '50', Score: '0.85' },
                { Drug1: 'Aspirin', Drug2: 'Acetaminophen', Dose1: '100', Dose2: '75', Score: '0.72' },
                { Drug1: 'Metformin', Drug2: 'Insulin', Dose1: '500', Dose2: '10', Score: '0.91' }
            ];
            const csvContent = arrayToCsvString(sampleData);
            fs.writeFileSync('./sample_combos.csv', csvContent);
            console.log("Created sample_combos.csv for testing");
            return;
        }

        console.log("Loading CSV file...");
        const data = [];
        
        return new Promise((resolve, reject) => {
            fs.createReadStream(inputFile)
                .pipe(csv())
                .on('data', (row) => {
                    data.push(row);
                })
                .on('end', () => {
                    console.log(`File parsed. Number of rows: ${data.length}`);
                    
                    if (data.length === 0) {
                        console.warn("Warning: No data found in CSV file");
                        resolve();
                        return;
                    }

                    // Create the same indexing structure as the original server
                    const indar = {};
                    console.log("Creating drug combination index...");
                    
                    for (let k = 0; k < data.length; k++) {
                        const row = data[k];
                        // Try different possible column names for drugs
                        const drug1 = row.Drug1 || row.drug1 || row.Drug_1 || row['Drug 1'] || row.compound1 || Object.values(row)[0];
                        const drug2 = row.Drug2 || row.drug2 || row.Drug_2 || row['Drug 2'] || row.compound2 || Object.values(row)[1];
                        
                        if (drug1 && drug2) {
                            const key = `${drug1}_${drug2}`;
                            if (indar[key] !== undefined) {
                                indar[key].push(row);
                            } else {
                                indar[key] = [row];
                            }
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
                        const csvFormat = arrayToCsvString(combData);
                        
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
                    const rankingSources = [
                        RANKING_CSV,
                        '../publish_R/combo_web/combo_ranking_n.syn_score_web.csv'
                    ];
                    
                    let rankingFound = false;
                    for (const rankingSource of rankingSources) {
                        if (fs.existsSync(rankingSource)) {
                            console.log(`Copying ranking CSV file from ${rankingSource}...`);
                            ensureDirectoryExists(path.dirname(RANKING_OUTPUT));
                            fs.copyFileSync(rankingSource, RANKING_OUTPUT);
                            console.log(`Ranking file copied to ${RANKING_OUTPUT}`);
                            rankingFound = true;
                            break;
                        }
                    }
                    
                    if (!rankingFound) {
                        console.warn(`Warning: Ranking file not found. Looked for:`);
                        rankingSources.forEach(src => console.warn(`  - ${src}`));
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
                    resolve();
                })
                .on('error', (error) => {
                    console.error("Error reading CSV file:", error);
                    reject(error);
                });
        });
        
    } catch (error) {
        console.error("Error during preprocessing:", error);
        process.exit(1);
    }
}

// Run the preprocessing
if (require.main === module) {
    preprocessData().catch(console.error);
}

module.exports = { preprocessData, createSafeFilename };
