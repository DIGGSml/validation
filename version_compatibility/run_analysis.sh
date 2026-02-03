#!/bin/bash
#
# Example run script for DIGGS Compatibility Analyzer
# Modify the paths below to match your environment
#

# Configuration
OLD_DIR="./schemas/v2.6"
NEW_DIR="./schemas/v3.0"
MAPPINGS_FILE="./type_mappings.txt"
OUTPUT_FILE="./diggs_analysis_$(date +%Y%m%d_%H%M%S).xlsx"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=================================================="
echo "DIGGS Schema Compatibility Analyzer"
echo "=================================================="
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Old schemas: $OLD_DIR"
echo "  New schemas: $NEW_DIR"
echo "  Mappings:    $MAPPINGS_FILE"
echo "  Output:      $OUTPUT_FILE"
echo ""

# Check if directories exist
if [ ! -d "$OLD_DIR" ]; then
    echo "Error: Old schema directory not found: $OLD_DIR"
    exit 1
fi

if [ ! -d "$NEW_DIR" ]; then
    echo "Error: New schema directory not found: $NEW_DIR"
    exit 1
fi

# Build command
CMD="python3 diggs_compatibility_analyzer.py --old-dir \"$OLD_DIR\" --new-dir \"$NEW_DIR\""

# Add mappings if file exists
if [ -f "$MAPPINGS_FILE" ]; then
    CMD="$CMD --mappings \"$MAPPINGS_FILE\""
else
    echo "Note: No mappings file found (optional)"
fi

# Add output file
CMD="$CMD --output \"$OUTPUT_FILE\""

# Run the analysis
echo -e "${BLUE}Running analysis...${NC}"
echo ""
eval $CMD

# Check if successful
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Analysis complete!${NC}"
    echo "  Report saved: $OUTPUT_FILE"
    echo ""
    echo "Opening report..."
    open "$OUTPUT_FILE" 2>/dev/null || echo "  (Open manually: $OUTPUT_FILE)"
else
    echo ""
    echo "Error: Analysis failed"
    exit 1
fi
