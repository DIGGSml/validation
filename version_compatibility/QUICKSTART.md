# Quick Start Guide

Get up and running with the DIGGS Compatibility Analyzer in 5 minutes!

## 1. Install Python (if needed)

Check if Python 3 is installed:
```bash
python3 --version
```

If not installed, download from: https://www.python.org/downloads/

## 2. Install Required Packages

```bash
pip3 install openpyxl lxml
```

Or use the requirements file:
```bash
pip3 install -r requirements.txt
```

## 3. Organize Your Schema Files

Create a folder structure like this:
```
my_analysis/
├── diggs_compatibility_analyzer.py
├── fixed_resolver.py
├── schemas/
│   ├── v2.6/
│   │   ├── Kernel.xsd
│   │   ├── Geophysics.xsd
│   │   └── ... (more .xsd files)
│   └── v3.0/
│       ├── Core.xsd
│       ├── Common.xsd
│       └── ... (more .xsd files)
└── type_mappings.txt (optional)
```

## 4. Create Type Mappings File (Optional)

If types have been renamed, create a tab-separated file:

```bash
nano type_mappings.txt
```

Add mappings (use TAB key between columns):
```
AbstractProgramPropertyType	ProgramPropertyType
BearingType	BearingMeasureType
```

Save and exit (Ctrl+O, Enter, Ctrl+X)

## 5. Run the Analyzer

```bash
python3 diggs_compatibility_analyzer.py \
  --old-dir schemas/v2.6 \
  --new-dir schemas/v3.0 \
  --mappings type_mappings.txt \
  --output compatibility_report.xlsx
```

## 6. Open the Report

```bash
open compatibility_report.xlsx
```

The Excel file will open with three sheets:
1. **ComplexTypes** - Detailed compatibility analysis
2. **Type Lists** - Added/removed types
3. **Type Mappings** - Mappings that were applied

## Common Issues

### "No module named 'openpyxl'"
**Fix:** `pip3 install openpyxl`

### "Permission denied"
**Fix:** `chmod +x diggs_compatibility_analyzer.py`

### "No .xsd files found"
**Fix:** Check your directory paths are correct

### Tab vs Spaces in Mappings File
Make sure to use TAB character (not spaces) in your mappings file!

## Example Session

```bash
# Navigate to your project folder
cd ~/Documents/DIGGS_Analysis

# Run analysis
python3 diggs_compatibility_analyzer.py \
  --old-dir ./v2.6_schemas \
  --new-dir ./v3.0_schemas \
  --output my_analysis.xlsx

# Output:
# ================================================================================
# DIGGS SCHEMA COMPATIBILITY ANALYZER
# ================================================================================
# 
# Detecting versions...
#   Old version: 2.6
#   New version: 3.0
# 
# Loading schemas from: v2.6_schemas
#   ✓ Kernel.xsd (diggs)
#   ✓ Geophysics.xsd (diggs)
#   ...
#   Total: 731 complexTypes, 52 attributes
# 
# Loading schemas from: v3.0_schemas
#   ✓ Core.xsd (diggs)
#   ✓ Common.xsd (diggs)
#   ...
#   Total: 999 complexTypes, 59 attributes
# 
# Comparing 731 types...
#   Progress: 100/731
#   Progress: 200/731
#   ...
# 
# Results:
#   Compatible: 583 (78.9%)
#   Incompatible: 117 (15.8%)
#   Renamed: 32
#   Removed: 39 (5.3%)
# 
# Generating Excel report: my_analysis.xlsx
#   ✓ Report saved: my_analysis.xlsx
# 
# ================================================================================
# ✓ Analysis complete!
# ================================================================================
```

## Next Steps

1. Open the Excel report
2. Review the ComplexTypes sheet
3. Filter by "Backward Compatible" = No to see issues
4. Check the "Notes" column for specific problems
5. Update your schemas or document breaking changes

## Need Help?

See the full README.md for detailed documentation!
