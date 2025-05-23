#!/bin/bash

# XSLT Transformation Pipeline Script
# Usage: ./cl-validate.sh <input.xml> <first.xsl> <second.xsl> [output.html]

# Check if we have the minimum required arguments
if [ $# -lt 3 ]; then
    echo "Usage: $0 <input.xml> <first.xsl> <second.xsl> [output.html]"
    echo ""
    echo "Arguments:"
    echo "  input.xml   - Source XML file to transform"
    echo "  first.xsl   - First XSLT stylesheet (XML to XML transformation)"
    echo "  second.xsl  - Second XSLT stylesheet (XML to HTML transformation)"
    echo "  output.html - Optional output filename (default: output.html)"
    echo ""
    echo "Example:"
    echo "  $0 data.xml transform1.xsl transform2.xsl result.html"
    exit 1
fi

# Set variables
INPUT_XML="$1"
FIRST_XSL="$2"
SECOND_XSL="$3"
OUTPUT_HTML="${4:-output.html}"

# Temporary file for intermediate XML
TEMP_XML=$(mktemp /tmp/saxon_temp_XXXXXX.xml)

# Function to find Saxon JAR
find_saxon_jar() {
    # Common locations where Saxon might be installed
    local saxon_locations=(
        "./saxon-he-*.jar"
        "./saxonj-he/saxon-he-*.jar"
        "/usr/local/lib/saxon-he-*.jar"
        "/opt/saxon/saxon-he-*.jar"
        "~/saxon/saxon-he-*.jar"
        "./lib/saxon-he-*.jar"
    )
    
    for location in "${saxon_locations[@]}"; do
        if ls $location 1> /dev/null 2>&1; then
            echo $location
            return 0
        fi
    done
    
    echo ""
    return 1
}

# Function to find XML Resolver JAR
find_xmlresolver_jar() {
    local resolver_locations=(
        "./xmlresolver-*.jar"
        "./lib/xmlresolver-*.jar"
        "/usr/local/lib/xmlresolver-*.jar"
        "~/saxon/xmlresolver-*.jar"
    )
    
    for location in "${resolver_locations[@]}"; do
        if ls $location 1> /dev/null 2>&1; then
            echo $location
            return 0
        fi
    done
    
    echo ""
    return 1
}

# Function to build classpath
build_classpath() {
    local saxon_jar="$1"
    local resolver_jar="$2"
    
    if [ -n "$resolver_jar" ]; then
        echo "${saxon_jar}:${resolver_jar}"
    else
        echo "${saxon_jar}"
    fi
}

# Function to cleanup temporary files
cleanup() {
    if [ -f "$TEMP_XML" ]; then
        rm "$TEMP_XML"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Find Saxon JAR file
SAXON_JAR=$(find_saxon_jar)

if [ -z "$SAXON_JAR" ]; then
    echo "Error: Saxon JAR file not found!"
    echo "Please ensure saxon-he-*.jar is in one of these locations:"
    echo "  - Current directory"
    echo "  - ./saxonj-he/ subdirectory"
    echo "  - /usr/local/lib/"
    echo "  - /opt/saxon/"
    echo "  - ~/saxon/"
    echo "  - ./lib/"
    echo ""
    echo "Or modify the script to include the correct path."
    exit 1
fi

# Find XML Resolver JAR (optional but recommended for Saxon 12+)
XMLRESOLVER_JAR=$(find_xmlresolver_jar)

if [ -z "$XMLRESOLVER_JAR" ]; then
    echo "Warning: XML Resolver JAR not found. This may cause issues with Saxon 12+."
    echo "Consider downloading xmlresolver-5.2.2.jar from:"
    echo "https://repo1.maven.org/maven2/org/xmlresolver/xmlresolver/5.2.2/xmlresolver-5.2.2.jar"
    echo "and placing it in ./lib/ directory"
    echo ""
fi

# Build classpath
CLASSPATH=$(build_classpath "$SAXON_JAR" "$XMLRESOLVER_JAR")

# Verify input files exist
for file in "$INPUT_XML" "$FIRST_XSL" "$SECOND_XSL"; do
    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found!"
        exit 1
    fi
done

echo "Using Saxon JAR: $SAXON_JAR"
if [ -n "$XMLRESOLVER_JAR" ]; then
    echo "Using XML Resolver JAR: $XMLRESOLVER_JAR"
fi
echo "Starting transformation pipeline..."

# Function to determine transformation command based on file extension
get_transform_params() {
    local stylesheet="$1"
    local input="$2"
    local output="$3"
    
    if [[ "$stylesheet" == *.sef.json ]]; then
        # For compiled stylesheets (SEF)
        echo "-s:\"$input\" -xsl:\"$stylesheet\" -o:\"$output\" -target:JS"
    else
        # For regular XSLT stylesheets
        echo "-s:\"$input\" -xsl:\"$stylesheet\" -o:\"$output\""
    fi
}

# Step 1: First transformation (XML to XML)
echo "Step 1: Applying first stylesheet ($FIRST_XSL)..."
TRANSFORM_PARAMS1=$(get_transform_params "$FIRST_XSL" "$INPUT_XML" "$TEMP_XML")

if [[ "$FIRST_XSL" == *.sef.json ]]; then
    echo "Note: Using compiled stylesheet (SEF) - requires XML Resolver"
    if [ -z "$XMLRESOLVER_JAR" ]; then
        echo "Error: SEF files require XML Resolver. Please download xmlresolver-5.2.2.jar"
        echo "curl -O https://repo1.maven.org/maven2/org/xmlresolver/xmlresolver/5.2.2/xmlresolver-5.2.2.jar"
        exit 1
    fi
fi

eval "java -cp \"$CLASSPATH\" net.sf.saxon.Transform $TRANSFORM_PARAMS1"

if [ $? -ne 0 ]; then
    echo "Error: First transformation failed!"
    exit 1
fi

echo "✓ First transformation completed"

# Step 2: Second transformation (XML to HTML)
echo "Step 2: Applying second stylesheet ($SECOND_XSL)..."
TRANSFORM_PARAMS2=$(get_transform_params "$SECOND_XSL" "$TEMP_XML" "$OUTPUT_HTML")

if [[ "$SECOND_XSL" == *.sef.json ]]; then
    echo "Note: Using compiled stylesheet (SEF) - requires XML Resolver"
    if [ -z "$XMLRESOLVER_JAR" ]; then
        echo "Error: SEF files require XML Resolver. Please download xmlresolver-5.2.2.jar"
        echo "curl -O https://repo1.maven.org/maven2/org/xmlresolver/xmlresolver/5.2.2/xmlresolver-5.2.2.jar"
        exit 1
    fi
fi

eval "java -cp \"$CLASSPATH\" net.sf.saxon.Transform $TRANSFORM_PARAMS2"

if [ $? -ne 0 ]; then
    echo "Error: Second transformation failed!"
    exit 1
fi

echo "✓ Second transformation completed"
echo "✓ Output written to: $OUTPUT_HTML"

# Step 3: Open in default browser
echo "Opening $OUTPUT_HTML in default browser..."
if command -v open >/dev/null 2>&1; then
    # macOS
    open "$OUTPUT_HTML"
elif command -v xdg-open >/dev/null 2>&1; then
    # Linux
    xdg-open "$OUTPUT_HTML"
elif command -v start >/dev/null 2>&1; then
    # Windows (if running in Git Bash or similar)
    start "$OUTPUT_HTML"
else
    echo "Could not detect command to open browser. Please open $OUTPUT_HTML manually."
fi

echo "✓ Pipeline completed successfully!"