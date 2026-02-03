# DIGGS Schema Compatibility Analyzer

A Python tool for analyzing backward compatibility between different versions of DIGGS (Data Interchange for Geotechnical and GeoEnvironmental Specialists) XML schemas.

## Features

- **Automatic version detection** from schema files
- **Recursive directory scanning** for .xsd files
- **Deep content model analysis** with inheritance resolution
- **Type mapping support** for renamed types between versions
- **Comprehensive Excel reports** with:
  - Detailed compatibility analysis for each type
  - Element/attribute changes tracking
  - Cardinality changes detection
  - Type change compatibility checking
  - Color-coded compatibility status

## Requirements

- Python 3.7 or higher
- macOS, Linux, or Windows

## Installation on Mac

### Step 1: Check Python Version

Open Terminal and check your Python version:

```bash
python3 --version
```

You should see Python 3.7 or higher. If not, install Python from [python.org](https://www.python.org/downloads/).

### Step 2: Install Required Python Packages

Install the required packages using pip:

```bash
pip3 install openpyxl lxml
```

Alternatively, if you have a `requirements.txt` file:

```bash
pip3 install -r requirements.txt
```

### Step 3: Download the Tool

Place these files in the same directory:
- `diggs_compatibility_analyzer.py` (main script)
- `fixed_resolver.py` (schema parsing utilities)

Make the main script executable:

```bash
chmod +x diggs_compatibility_analyzer.py
```

## Usage

### Basic Usage

Compare two versions of DIGGS schemas:

```bash
python3 diggs_compatibility_analyzer.py \
  --old-dir /path/to/diggs_v2.6 \
  --new-dir /path/to/diggs_v3.0 \
  --output compatibility_report.xlsx
```

### With Type Mappings

If types have been renamed between versions, provide a mappings file:

```bash
python3 diggs_compatibility_analyzer.py \
  --old-dir /path/to/diggs_v2.6 \
  --new-dir /path/to/diggs_v3.0 \
  --mappings type_mappings.txt \
  --output compatibility_report.xlsx
```

### Command-Line Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--old-dir` | Yes | Directory containing old version schema files |
| `--new-dir` | Yes | Directory containing new version schema files |
| `--mappings` | No | Path to type mappings file (tab-separated) |
| `--output` | No | Output Excel filename (default: `diggs_compatibility_analysis.xlsx`) |

### Type Mappings File Format

Create a tab-separated text file with old and new type names:

```
AbstractProgramPropertyType	ProgramPropertyType
BearingType	BearingMeasureType
AbstractSurfacePropertyType	SurfacePropertyType
eml:LengthMeasure	LengthMeasureType
witsml:Cost	CostType
```

**Important:** Use TAB character (not spaces) to separate columns.

### Creating a Type Mappings File on Mac

Using TextEdit:
1. Open TextEdit
2. Choose Format → Make Plain Text
3. Type mappings with Tab key between columns
4. Save as `.txt` file

Using Terminal:
```bash
cat > type_mappings.txt << 'EOF'
AbstractProgramPropertyType	ProgramPropertyType
BearingType	BearingMeasureType
AbstractSurfacePropertyType	SurfacePropertyType
EOF
```

## Directory Structure

The tool recursively searches for `.xsd` files in the specified directories:

```
diggs_v2.6/
├── Kernel.xsd
├── Geophysics.xsd
├── Construction.xsd
├── subdirectory/
│   ├── MoreSchemas.xsd
│   └── ...
└── ...

diggs_v3.0/
├── Core.xsd
├── Common.xsd
├── AbstractTypes.xsd
└── ...
```

## Understanding the Output

The Excel workbook contains three worksheets:

### 1. ComplexTypes Sheet

Detailed analysis for each type with columns:

- **Complex Type Name**: Type being analyzed
- **Source Namespace**: Namespace (diggs, diggs_geo, gml, etc.)
- **Type Removed**: Whether type exists in new version
- **BaseType Changed To**: Base type changes
- **New Element/Attr**: New elements or attributes added
- **Missing Element/Attr**: Elements or attributes removed
- **Cardinality Expanded**: Cardinality made less restrictive
- **Cardinality Restricted**: Cardinality made more restrictive ⚠️
- **Type Changed**: Element type changes with compatibility markers
  - `[OK]` = Compatible change
  - `[INCOMPATIBLE: reason]` = Incompatible change
- **Notes**: Summary of compatibility issues
- **Backward Compatible**: Final verdict
  - 🟢 Green = Compatible
  - 🔴 Red = Incompatible

### 2. Type Lists Sheet

Side-by-side comparison:
- Types removed from old version
- New types added in new version

### 3. Type Mappings Sheet

All type mappings that were applied during analysis.

## Compatibility Rules

A type is considered **backward compatible** if:

✅ All old elements/attributes still exist
✅ No cardinality restrictions on existing elements
✅ New elements are optional (minOccurs="0")
✅ New attributes are optional
✅ Element type changes are compatible

A type is **incompatible** if:

❌ Elements or attributes removed
❌ Cardinality made more restrictive
❌ New required elements added
❌ New required attributes added
❌ Element type changes to incompatible type

## Troubleshooting

### "No module named 'openpyxl'"

Install the required package:
```bash
pip3 install openpyxl
```

### "No module named 'lxml'"

Install the required package:
```bash
pip3 install lxml
```

### "Permission denied" when running script

Make the script executable:
```bash
chmod +x diggs_compatibility_analyzer.py
```

### "No .xsd files found"

Check that:
- The directory paths are correct
- The directories contain `.xsd` files
- You have read permissions for the directories

### "Multiple versions found in directory"

The tool detected inconsistent version numbers in the schema files. It will use the first version found, but you should verify your schema files have consistent version attributes.

## Advanced Usage

### Analyzing Specific Schema Subdirectories

If your schemas are organized in subdirectories:

```bash
python3 diggs_compatibility_analyzer.py \
  --old-dir /path/to/diggs/v2.6/schemas \
  --new-dir /path/to/diggs/v3.0/schemas \
  --output analysis.xlsx
```

The tool will recursively search all subdirectories.

### Batch Analysis

Create a shell script to analyze multiple version pairs:

```bash
#!/bin/bash

# Analyze v2.5 to v2.6
python3 diggs_compatibility_analyzer.py \
  --old-dir diggs_v2.5 \
  --new-dir diggs_v2.6 \
  --output v2.5_to_v2.6.xlsx

# Analyze v2.6 to v3.0
python3 diggs_compatibility_analyzer.py \
  --old-dir diggs_v2.6 \
  --new-dir diggs_v3.0 \
  --mappings mappings_v26_v30.txt \
  --output v2.6_to_v3.0.xlsx
```

## Examples

### Example 1: Basic Analysis

```bash
python3 diggs_compatibility_analyzer.py \
  --old-dir ~/Documents/DIGGS/v2.6 \
  --new-dir ~/Documents/DIGGS/v3.0 \
  --output ~/Desktop/diggs_analysis.xlsx
```

### Example 2: With Mappings

```bash
python3 diggs_compatibility_analyzer.py \
  --old-dir ~/Documents/DIGGS/v2.6 \
  --new-dir ~/Documents/DIGGS/v3.0 \
  --mappings ~/Documents/DIGGS/type_mappings.txt \
  --output ~/Desktop/diggs_v26_v30_analysis.xlsx
```

### Example 3: Relative Paths

```bash
cd ~/Documents/DIGGS
python3 diggs_compatibility_analyzer.py \
  --old-dir ./v2.6 \
  --new-dir ./v3.0 \
  --output ./analysis_results.xlsx
```

## Technical Details

### Schema Parsing

The tool:
1. Recursively scans directories for `.xsd` files
2. Parses each schema using lxml
3. Extracts all complex types and attributes
4. Resolves inheritance chains (base types)
5. Builds complete content models for each type

### Compatibility Analysis

For each type, the tool:
1. Checks if type exists in new version (or mapped name)
2. Compares base types
3. Resolves full content models (including inherited elements)
4. Checks for missing elements/attributes
5. Checks for new required elements/attributes
6. Compares cardinality constraints
7. Recursively checks element type changes

### Type Change Compatibility

When element types change, the tool:
1. Checks if types are identical
2. Checks for known mappings
3. If both are complex types:
   - Resolves both content models
   - Recursively compares for compatibility
4. Reports specific incompatibility reasons

## Version History

- **1.0.0** (2025-01-14): Initial release
  - Automatic version detection
  - Recursive directory scanning
  - Deep content model analysis
  - Type mapping support
  - Excel report generation

## Author

Dan Ponti / DIGGS Technical Committee
With assistance from Claude (Anthropic)

## License

This tool is provided for use by the DIGGS community for schema compatibility analysis.

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Verify your Python and package versions
3. Contact the DIGGS Technical Committee

## Contributing

To improve this tool:
1. Test with various DIGGS schema versions
2. Report bugs or compatibility issues
3. Suggest enhancements for analysis logic
4. Contribute additional type mappings

---

**Happy Analyzing!** 🎉
