#!/usr/bin/env python3
"""
Installation Verification Script
Tests that all required components are properly installed
"""

import sys

def check_python_version():
    """Check Python version"""
    version = sys.version_info
    if version.major >= 3 and version.minor >= 7:
        print(f"✓ Python version: {version.major}.{version.minor}.{version.micro}")
        return True
    else:
        print(f"✗ Python version: {version.major}.{version.minor}.{version.micro}")
        print("  Required: Python 3.7 or higher")
        return False

def check_module(module_name):
    """Check if a module is installed"""
    try:
        __import__(module_name)
        print(f"✓ {module_name} is installed")
        return True
    except ImportError:
        print(f"✗ {module_name} is NOT installed")
        print(f"  Install with: pip3 install {module_name}")
        return False

def check_files():
    """Check if required files exist"""
    import os
    files = [
        'diggs_compatibility_analyzer.py',
        'fixed_resolver.py',
        'README.md'
    ]
    
    all_exist = True
    for filename in files:
        if os.path.exists(filename):
            print(f"✓ {filename} found")
        else:
            print(f"✗ {filename} NOT found")
            all_exist = False
    
    return all_exist

def main():
    print("="*60)
    print("DIGGS Compatibility Analyzer - Installation Check")
    print("="*60)
    print()
    
    checks = []
    
    print("Checking Python version...")
    checks.append(check_python_version())
    print()
    
    print("Checking required modules...")
    checks.append(check_module('openpyxl'))
    checks.append(check_module('lxml'))
    print()
    
    print("Checking required files...")
    checks.append(check_files())
    print()
    
    print("="*60)
    if all(checks):
        print("✓ All checks passed! Ready to analyze DIGGS schemas.")
        print()
        print("Next steps:")
        print("  1. Organize your schema files into old/new directories")
        print("  2. Run: python3 diggs_compatibility_analyzer.py --help")
        print("  3. See QUICKSTART.md for detailed instructions")
    else:
        print("✗ Some checks failed. Please install missing components.")
        print()
        print("To install required packages:")
        print("  pip3 install -r requirements.txt")
    print("="*60)

if __name__ == '__main__':
    main()
