#!/usr/bin/env node

// Ensure output directory exists
async function ensureOutputDirectory(outputDir) {
    try {
        await fs.mkdir(outputDir, { recursive: true });
        console.log(`✓ Output directory ready: ${path.relative(process.cwd(), outputDir)}`);
    } catch (error) {
        console.error(`Error creating output directory: ${error.message}`);
        throw error;
    }
}

// validation-transform.js - DIGGS validation with HTML report generation
const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

// Import Saxon-JS
let SaxonJS;
try {
    SaxonJS = require('saxonjs-he');
} catch (error) {
    console.error('Saxon-JS not found. Please install it with: npm install saxonjs-he', error.message);
    process.exit(1);
}

// Configuration - relative to script location
const SCRIPT_DIR = path.dirname(path.resolve(__filename));
const FIRST_STYLESHEET = path.join(SCRIPT_DIR, 'diggs-validation-debug.sef.json');

// Parse command line arguments
function parseArguments() {
    const args = process.argv.slice(2);
    
    if (args.length < 2) {
        console.log(`
Usage: node diggs-validate.js <input.xml> <html-transform.sef.json> [options]

Arguments:
  input.xml              - Source XML file to validate
  html-transform.sef     - Compiled XSLT stylesheet for HTML output (SEF format)

Options:
  --no-browser          - Don't open browser automatically
  --keep-intermediate   - Keep intermediate validation-report.xml file
  --output-dir <dir>    - Output directory (absolute or relative path, default: script directory)

Examples:
  node diggs-validate.js data.xml format-html.sef.json
  node diggs-validate.js data.xml format-html.sef.json --no-browser
  node diggs-validate.js data.xml format-html.sef.json --keep-intermediate
  node diggs-validate.js data.xml format-html.sef.json --output-dir ./reports
  node diggs-validate.js data.xml format-html.sef.json --output-dir /absolute/path/reports

Files used:
  First transform:  ./diggs-validation.sef.json (hardcoded, in script directory)
  Default output:   ./validation-report.xml and ./validation-report.html (in script directory)
  Custom output:    <output-dir>/validation-report.xml and <output-dir>/validation-report.html
        `);
        process.exit(1);
    }
    
    const config = {
        inputXml: args[0],
        firstStylesheet: FIRST_STYLESHEET,
        secondStylesheet: args[1],
        openBrowser: true,
        keepIntermediate: true,
        outputDir: SCRIPT_DIR,  // Default to script directory
        scriptDir: SCRIPT_DIR
    };
    
    // Parse options
    for (let i = 2; i < args.length; i++) {
        switch (args[i]) {
            case '--no-browser':
                config.openBrowser = false;
                break;
            case '--keep-intermediate':
                config.keepIntermediate = true;
                break;
            case '--output-dir':
                if (i + 1 < args.length) {
                    const outputPath = args[++i];
                    // Handle both absolute and relative paths
                    config.outputDir = path.isAbsolute(outputPath) 
                        ? outputPath 
                        : path.resolve(process.cwd(), outputPath);
                } else {
                    console.error('--output-dir requires a directory path');
                    process.exit(1);
                }
                break;
            default:
                console.warn(`Unknown option: ${args[i]}`);
        }
    }
    
    // Set file paths based on output directory
    config.intermediateXml = path.join(config.outputDir, 'validation-report.xml');
    config.htmlFile = path.join(config.outputDir, 'validation-report.html');
    
    return config;
}

// Validate input files
async function validateInputs(config) {
    const files = [
        { path: config.inputXml, description: 'Input XML file' },
        { path: config.firstStylesheet, description: 'DIGGS validation stylesheet' },
        { path: config.secondStylesheet, description: 'HTML transform stylesheet' }
    ];
    
    for (const file of files) {
        try {
            await fs.access(file.path);
            console.log(`✓ Found ${file.description}: ${path.relative(process.cwd(), file.path)}`);
        } catch (error) {
            console.error(`✗ ${file.description} not found: ${file.path}`);
            if (file.path === config.firstStylesheet) {
                console.error(`  Make sure 'diggs-validation.sef.json' is in the same directory as this script`);
            }
            process.exit(1);
        }
    }
}

// Perform DIGGS validation transformation
async function diggsValidation(config) {
    try {
        console.log('\n--- Stage 1: DIGGS Validation ---');
        console.log(`Input: ${path.relative(process.cwd(), config.inputXml)}`);
        console.log(`Stylesheet: ${path.relative(process.cwd(), config.firstStylesheet)}`);
        
        // Read the input XML
        const inputXml = await fs.readFile(config.inputXml, 'utf8');
        
        // Perform the validation transformation
        const result = SaxonJS.transform({
            stylesheetFileName: config.firstStylesheet,
            sourceText: inputXml,
            destination: 'serialized'
        }, 'sync');
        
        // Handle the result
        let xmlOutput;
        if (typeof result === 'string') {
            xmlOutput = result;
        } else if (result.principalResult) {
            xmlOutput = result.principalResult;
        } else {
            xmlOutput = result.toString();
        }
        
        // Write validation report XML
        await fs.writeFile(config.intermediateXml, xmlOutput, 'utf8');
        console.log(`✓ Validation report generated: ${path.relative(process.cwd(), config.intermediateXml)}`);
        
        return xmlOutput;
    } catch (error) {
        console.error('Error in DIGGS validation:', error.message);
        throw error;
    }
}

// Perform HTML report transformation
async function htmlReportTransformation(config, validationXml) {
    try {
        console.log('\n--- Stage 2: HTML Report Generation ---');
        console.log(`Input: validation-report.xml`);
        console.log(`Stylesheet: ${path.relative(process.cwd(), config.secondStylesheet)}`);
        
        // Perform the transformation to HTML
        const result = SaxonJS.transform({
            stylesheetFileName: config.secondStylesheet,
            sourceText: validationXml,
            destination: 'serialized'
        }, 'sync');
        
        // Handle the result
        let htmlOutput;
        if (typeof result === 'string') {
            htmlOutput = result;
        } else if (result.principalResult) {
            htmlOutput = result.principalResult;
        } else {
            htmlOutput = result.toString();
        }
        
        // Write final HTML report
        await fs.writeFile(config.htmlFile, htmlOutput, 'utf8');
        console.log(`✓ HTML report generated: ${path.relative(process.cwd(), config.htmlFile)}`);
        
        return htmlOutput;
    } catch (error) {
        console.error('Error in HTML report generation:', error.message);
        throw error;
    }
}

// Open file in default browser
async function openInBrowser(filePath) {
    const fullPath = path.resolve(filePath);
    const fileUrl = `file://${fullPath}`;
    
    try {
        console.log(`\n--- Opening Validation Report ---`);
        console.log(`URL: ${fileUrl}`);
        
        // Determine the appropriate command based on platform
        let command;
        switch (process.platform) {
            case 'darwin':  // macOS
                command = `open "${fileUrl}"`;
                break;
            case 'win32':   // Windows
                command = `start "" "${fileUrl}"`;
                break;
            default:        // Linux and others
                command = `xdg-open "${fileUrl}"`;
                break;
        }
        
        await execAsync(command);
        console.log('✓ Browser opened successfully');
    } catch (error) {
        console.error('Error opening browser:', error.message);
        console.log(`You can manually open: ${fileUrl}`);
    }
}

// Cleanup intermediate files
async function cleanup(config) {
    if (!config.keepIntermediate) {
        try {
            await fs.unlink(config.intermediateXml);
            console.log(`✓ Cleaned up intermediate file: ${path.relative(process.cwd(), config.intermediateXml)}`);
        } catch (error) {
            // Ignore cleanup errors
            console.log(`Note: Could not clean up ${path.relative(process.cwd(), config.intermediateXml)}`);
        }
    } else {
        console.log(`✓ Keeping intermediate file: ${path.relative(process.cwd(), config.intermediateXml)}`);
    }
}

// Display summary
function displaySummary(config) {
    console.log('\n=== Validation Complete ===');
    console.log(`Input file:        ${path.relative(process.cwd(), config.inputXml)}`);
    console.log(`Output directory:  ${path.relative(process.cwd(), config.outputDir)}`);
    console.log(`Validation report: ${path.relative(process.cwd(), config.htmlFile)}`);
    if (config.keepIntermediate) {
        console.log(`Intermediate XML:  ${path.relative(process.cwd(), config.intermediateXml)}`);
    }
}

// Main execution function
async function main() {
    try {
        console.log('=== DIGGS Validation Tool ===\n');
        
        // Parse command line arguments
        const config = parseArguments();
        
        // Validate inputs
        await validateInputs(config);
        
        // Ensure output directory exists
        await ensureOutputDirectory(config.outputDir);
        
        // Perform DIGGS validation
        const validationXml = await diggsValidation(config);
        
        // Generate HTML report
        await htmlReportTransformation(config, validationXml);
        
        // Open in browser if requested
        if (config.openBrowser) {
            await openInBrowser(config.htmlFile);
        }
        
        // Cleanup
        await cleanup(config);
        
        // Display summary
        displaySummary(config);
        
    } catch (error) {
        console.error('\n=== Validation Failed ===');
        console.error('Error:', error.message);
        process.exit(1);
    }
}

// Export for testing or require usage
module.exports = {
    parseArguments,
    validateInputs,
    diggsValidation,
    htmlReportTransformation,
    openInBrowser
};

// Run if called directly
if (require.main === module) {
    main();
}