#!/usr/bin/env python3
"""
Test script for the DIGGS Units Conversion API
This script can be run on any server to test the Units API functionality
"""

import requests
import json
import argparse
import sys

def print_response(response, verbose=False):
    """Pretty print API response"""
    print(f"Status code: {response.status_code}")
    if verbose:
        print("Headers:")
        for header, value in response.headers.items():
            print(f"  {header}: {value}")
    
    try:
        data = response.json()
        print("Response body:")
        print(json.dumps(data, indent=2))
    except:
        print("Response body (raw):")
        print(response.text)
    print("-" * 80)

def test_convert_units_post(base_url, api_key, source_value, source_unit, target_unit, verbose=False):
    """Test the POST /api/units/convert endpoint"""
    print("\n=== Testing POST /api/units/convert ===")
    url = f"{base_url}/api/units/convert"
    headers = {"X-API-Key": api_key, "Content-Type": "application/json"}
    payload = {
        "sourceValue": source_value,
        "sourceUnit": source_unit,
        "targetUnit": target_unit
    }
    
    print(f"POST {url}")
    print(f"Request payload: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        print_response(response, verbose)
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_convert_units_get(base_url, api_key, source_value, source_unit, target_unit, verbose=False):
    """Test the GET /api/units/convert endpoint"""
    print("\n=== Testing GET /api/units/convert ===")
    url = f"{base_url}/api/units/convert"
    headers = {"X-API-Key": api_key}
    params = {
        "sourceValue": source_value,
        "sourceUnit": source_unit,
        "targetUnit": target_unit
    }
    
    print(f"GET {url}")
    print(f"Query parameters: {params}")
    
    try:
        response = requests.get(url, params=params, headers=headers)
        print_response(response, verbose)
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_get_units_by_class(base_url, api_key, quantity_class, verbose=False):
    """Test the GET /api/units/classes/{quantity_class_name} endpoint"""
    print(f"\n=== Testing GET /api/units/classes/{quantity_class} ===")
    url = f"{base_url}/api/units/classes/{quantity_class}"
    headers = {"X-API-Key": api_key}
    
    print(f"GET {url}")
    
    try:
        response = requests.get(url, headers=headers)
        print_response(response, verbose)
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_list_quantity_classes(base_url, api_key, verbose=False):
    """Test the GET /api/units/classes endpoint"""
    print("\n=== Testing GET /api/units/classes ===")
    url = f"{base_url}/api/units/classes"
    headers = {"X-API-Key": api_key}
    
    print(f"GET {url}")
    
    try:
        response = requests.get(url, headers=headers)
        print_response(response, verbose)
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_health_check(base_url, api_key, verbose=False):
    """Test the GET /api/units/health endpoint"""
    print("\n=== Testing GET /api/units/health ===")
    url = f"{base_url}/api/units/health"
    headers = {"X-API-Key": api_key}
    
    print(f"GET {url}")
    
    try:
        response = requests.get(url, headers=headers)
        print_response(response, verbose)
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def run_all_tests(base_url, api_key, verbose=False):
    """Run all API tests"""
    results = {}
    
    # Test health check
    results["health_check"] = test_health_check(base_url, api_key, verbose)
    
    # Test unit conversion (both POST and GET methods)
    results["convert_post"] = test_convert_units_post(base_url, api_key, 10.0, "ft", "m", verbose)
    results["convert_get"] = test_convert_units_get(base_url, api_key, 10.0, "ft", "m", verbose)
    
    # Test listing quantity classes
    results["list_classes"] = test_list_quantity_classes(base_url, api_key, verbose)
    
    # Test getting units by class
    # First try to get the classes to find one to use
    try:
        response = requests.get(f"{base_url}/api/units/classes", headers={"X-API-Key": api_key})
        if response.status_code == 200:
            classes = response.json()
            if classes and len(classes) > 0:
                test_class = classes[0]["name"]
                results["get_units"] = test_get_units_by_class(base_url, api_key, test_class, verbose)
            else:
                results["get_units"] = False
                print("No quantity classes found for testing")
        else:
            results["get_units"] = False
            print("Could not retrieve quantity classes for testing")
    except Exception as e:
        results["get_units"] = False
        print(f"Error while retrieving quantity classes: {e}")
    
    # Print summary
    print("\n=== Test Results Summary ===")
    all_passed = True
    for test, passed in results.items():
        print(f"{test}: {'PASS' if passed else 'FAIL'}")
        if not passed:
            all_passed = False
    
    print(f"\nOverall result: {'ALL TESTS PASSED' if all_passed else 'SOME TESTS FAILED'}")
    return all_passed

def main():
    parser = argparse.ArgumentParser(description="Test the DIGGS Units Conversion API")
    parser.add_argument("base_url", help="Base URL of the API (e.g. http://example.com)")
    parser.add_argument("api_key", help="API key for authentication")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose output")
    parser.add_argument("--test", choices=["all", "convert", "classes", "units", "health"], 
                        default="all", help="Specific test to run")
    
    args = parser.parse_args()
    
    # Remove trailing slash from base URL if present
    base_url = args.base_url.rstrip("/")
    
    if args.test == "all":
        success = run_all_tests(base_url, args.api_key, args.verbose)
    elif args.test == "convert":
        success = test_convert_units_post(base_url, args.api_key, 10.0, "ft", "m", args.verbose)
        success = test_convert_units_get(base_url, args.api_key, 10.0, "ft", "m", args.verbose) and success
    elif args.test == "classes":
        success = test_list_quantity_classes(base_url, args.api_key, args.verbose)
    elif args.test == "units":
        success = test_get_units_by_class(base_url, args.api_key, "Length", args.verbose)
    elif args.test == "health":
        success = test_health_check(base_url, args.api_key, args.verbose)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()