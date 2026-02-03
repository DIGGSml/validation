# DIGGS Compatibility Analyzer Package
## Complete Standalone Tool for Schema Compatibility Analysis

### Package Contents

This package contains everything you need to run DIGGS schema compatibility analysis on your Mac (or any system with Python 3.7+):

#### Core Files
1. **diggs_compatibility_analyzer.py** (30 KB)
   - Main application script
   - Command-line interface
   - All analysis logic included

2. **fixed_resolver.py** (15 KB)
   - Schema parsing utilities
   - Content model resolution
   - Inheritance chain handling

#### Documentation
3. **README.md** (9 KB)
   - Comprehensive documentation
   - Installation instructions for Mac
   - Usage examples
   - Troubleshooting guide
   - Technical details

4. **QUICKSTART.md** (4 KB)
   - 5-minute setup guide
   - Step-by-step instructions
   - Common issues and fixes

#### Supporting Files
5. **requirements.txt**
   - Python package dependencies
   - openpyxl (Excel generation)
   - lxml (XML parsing)

6. **example_type_mappings.txt** (4 KB)
   - Example type mappings file
   - v2.6 to v3.0 mappings included
   - Shows proper tab-separated format

7. **verify_installation.py**
   - Installation verification script
   - Checks Python version
   - Verifies required packages
   - Confirms files are present

### Key Features

✅ **Automatic Version Detection** - Reads version from schema files
✅ **Recursive Directory Scanning** - Finds all .xsd files automatically
✅ **Deep Content Model Analysis** - Resolves full inheritance chains
✅ **Type Mapping Support** - Handles renamed types between versions
✅ **Recursive Type Compatibility** - Checks nested type changes
✅ **Comprehensive Excel Reports** - Three detailed worksheets
✅ **No "Review Needed" Category** - Definitive compatibility verdicts

### Quick Start (3 Steps)

1. **Install Python packages:**
   ```bash
   pip3 install openpyxl lxml
   ```

2. **Organize your schemas:**
   ```
   my_analysis/
   ├── diggs_compatibility_analyzer.py
   ├── fixed_resolver.py
   └── schemas/
       ├── v2.6/  (put old schemas here)
       └── v3.0/  (put new schemas here)
   ```

3. **Run analysis:**
   ```bash
   python3 diggs_compatibility_analyzer.py \
     --old-dir schemas/v2.6 \
     --new-dir schemas/v3.0 \
     --output report.xlsx
   ```

### Command-Line Interface

```bash
python3 diggs_compatibility_analyzer.py \
  --old-dir <path_to_old_schemas> \
  --new-dir <path_to_new_schemas> \
  [--mappings <type_mappings_file>] \
  [--output <output_filename.xlsx>]
```

**Arguments:**
- `--old-dir`: Directory with old version schemas (required)
- `--new-dir`: Directory with new version schemas (required)
- `--mappings`: Tab-separated type mappings file (optional)
- `--output`: Output Excel filename (default: diggs_compatibility_analysis.xlsx)

### Type Mappings File Format

Create a plain text file with tab-separated values:

```
OldTypeName<TAB>NewTypeName
AbstractProgramPropertyType<TAB>ProgramPropertyType
BearingType<TAB>BearingMeasureType
eml:LengthMeasure<TAB>LengthMeasureType
```

**Important:** Use actual TAB characters (not spaces) between columns!

### Output Excel Workbook

The generated Excel file contains three worksheets:

#### 1. ComplexTypes Sheet
Detailed analysis for each type:
- Type name and namespace
- Removal/rename status
- Base type changes
- New/missing elements and attributes
- Cardinality changes
- Element type changes with compatibility markers
- Compatibility verdict (color-coded: green=compatible, red=incompatible)

#### 2. Type Lists Sheet
- Old types not in new version
- New types not in old version

#### 3. Type Mappings Sheet
- All mappings applied during analysis

### Compatibility Logic

The tool performs deep analysis by:

1. **Resolving full content models** including all inherited elements/attributes
2. **Checking for breaking changes:**
   - Removed elements or attributes
   - New required elements or attributes
   - Cardinality restrictions
   - Incompatible type changes
3. **Recursively analyzing type changes** by comparing content models
4. **Reporting specific reasons** for incompatibilities

### Example Output

```
================================================================================
DIGGS SCHEMA COMPATIBILITY ANALYZER
================================================================================

Detecting versions...
  Old version: 2.6
  New version: 3.0

Loading schemas from: schemas/v2.6
  ✓ Kernel.xsd (diggs)
  ✓ Geophysics.xsd (diggs)
  ✓ Construction.xsd (diggs)
  ...
  Total: 739 complexTypes, 52 attributes

Loading schemas from: schemas/v3.0
  ✓ Core.xsd (diggs)
  ✓ Common.xsd (diggs)
  ✓ AbstractTypes.xsd (diggs)
  ...
  Total: 1001 complexTypes, 59 attributes

Comparing 739 types with recursive compatibility checking...
  Progress: 100/739
  Progress: 200/739
  ...

Results:
  Compatible: 583 (78.9%)
  Incompatible: 117 (15.8%)
  Renamed: 32
  Removed: 39 (5.3%)

Generating Excel report: report.xlsx
  ✓ Report saved: report.xlsx

================================================================================
✓ Analysis complete!
================================================================================
```

### System Requirements

- **Operating System:** macOS, Linux, or Windows
- **Python:** 3.7 or higher
- **Memory:** 512 MB minimum (2 GB recommended for large schemas)
- **Disk Space:** 50 MB for tool + space for schema files

### Installation on Mac

1. **Check Python:**
   ```bash
   python3 --version
   ```
   Should show Python 3.7 or higher.

2. **Install packages:**
   ```bash
   pip3 install openpyxl lxml
   ```

3. **Verify installation:**
   ```bash
   python3 verify_installation.py
   ```

### Advanced Usage

#### Batch Analysis
Analyze multiple version pairs:
```bash
#!/bin/bash
for old in v2.4 v2.5 v2.6; do
  for new in v2.5 v2.6 v3.0; do
    if [[ "$old" < "$new" ]]; then
      python3 diggs_compatibility_analyzer.py \
        --old-dir schemas/$old \
        --new-dir schemas/$new \
        --output analysis_${old}_to_${new}.xlsx
    fi
  done
done
```

#### Custom Namespace Inference
The tool infers namespaces from filenames:
- Files with "geotechnical" or "geo" + "deprecated" → diggs_geo namespace
- Files with "gml" → gml namespace
- Files with "glr" → glr namespace
- All others → diggs namespace

### Troubleshooting

**Q: "No module named 'openpyxl'"**
A: Install with `pip3 install openpyxl`

**Q: "Permission denied"**
A: Make executable with `chmod +x diggs_compatibility_analyzer.py`

**Q: "Multiple versions found in directory"**
A: Check that all schemas in a directory have consistent version attributes

**Q: Tool runs but no output**
A: Check that output directory is writable

**Q: "No .xsd files found"**
A: Verify directory paths and that .xsd files exist

### Technical Notes

#### Version Detection
The tool reads the `version` attribute from schema files:
```xml
<schema version="2.6" ...>
```

All schemas in a directory should have the same version. If multiple versions are found, the tool uses the first one alphabetically but warns you.

#### Namespace Dictionaries
The tool uses two namespace dictionaries:
- `NS_26` for old schemas
- `NS_3` for new schemas

These are defined in `fixed_resolver.py` and work for DIGGS 2.x and 3.x schemas.

#### Content Model Resolution
For each type, the tool:
1. Finds the complexType definition
2. Resolves the base type (if any)
3. Recursively resolves the base type's content model
4. Combines all elements and attributes from the inheritance chain
5. Returns the complete content model

This ensures accurate comparison even when types inherit from abstract base types.

### Support and Feedback

For issues or suggestions:
1. Check the documentation (README.md)
2. Review troubleshooting section
3. Verify your Python and package versions
4. Contact the DIGGS Technical Committee

### License

This tool is provided for use by the DIGGS community for schema compatibility analysis and version migration planning.

### Version

**Version:** 1.0.0
**Date:** January 14, 2025
**Author:** Dan Ponti / DIGGS Technical Committee (with Claude/Anthropic assistance)

---

## Ready to Go!

You now have everything needed to analyze DIGGS schema compatibility. Start with QUICKSTART.md and refer to README.md for detailed documentation.

Happy analyzing! 🎉
