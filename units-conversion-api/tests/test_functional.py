"""
Functional tests for the Units Conversion API using the real online dictionary
"""

import unittest
import json
import sys
import os
import logging
import requests
from typing import Dict, Any, List

# Configure logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Import from your application
from app import app, fetch_units_dictionary

class TestUnitsConversionAPIFunctional(unittest.TestCase):
    """Functional test cases for the Units Conversion API using real dictionary"""

    @classmethod
    def setUpClass(cls):
        """Set up test client and validate dictionary access once for all tests"""
        cls.app = app.test_client()
        cls.app.testing = True
        
        # Try to fetch the real dictionary once to validate connectivity
        try:
            logger.info("Attempting to fetch the real dictionary...")
            cls.dictionary = fetch_units_dictionary()
            cls.test_enabled = True
            logger.info("Successfully fetched the real dictionary")
            
            # Extract available quantity classes and units for dynamic testing
            cls.available_quantity_classes = cls._extract_quantity_classes(cls.dictionary)
            logger.info(f"Found quantity classes: {cls.available_quantity_classes.keys()}")
            
        except Exception as e:
            logger.error(f"Could not fetch the online dictionary: {e}")
            cls.test_enabled = False
            cls.available_quantity_classes = {}
    
    @staticmethod
    def _extract_quantity_classes(dictionary):
        """Extract quantity classes and their units from the dictionary"""
        quantity_classes = {}
        
        for qc in dictionary.findall('.//quantityClass'):
            name = qc.find('name').text
            base_unit = qc.find('baseForConversion').text if qc.find('baseForConversion') is not None else None
            member_units = [mu.text for mu in qc.findall('memberUnit')]
            
            quantity_classes[name] = {
                'base_unit': base_unit,
                'member_units': member_units
            }
            
        return quantity_classes
    
    def setUp(self):
        """Set up for each test"""
        if not self.test_enabled:
            self.skipTest("Online dictionary not available")
    
    def test_health_endpoint(self):
        """Test the health check endpoint"""
        response = self.app.get('/api/health')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'healthy')

    def test_quantity_classes_endpoint(self):
        """Test the quantity classes endpoint with real dictionary"""
        response = self.app.get('/api/quantityclasses')
        
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        
        # Verify we got some quantity classes
        self.assertGreater(len(data), 0)
        
        # Log the response for debugging
        logger.info(f"Quantity classes response: {data[:5]}...")  # Show first 5 classes
        
        # Get the quantity class names from the response
        found_classes = [item['name'] for item in data]
        
        # Check that there's some overlap with expected classes
        expected_common_classes = ['pressure', 'length', 'mass', 'temperature', 'time']
        found_expected = [cls for cls in expected_common_classes if cls in found_classes]
        
        self.assertGreater(len(found_expected), 0,
                          f"None of the expected classes {expected_common_classes} were found in {found_classes}")
        
        logger.info(f"Found expected classes: {found_expected}")

    def get_valid_conversion_test_cases(self):
        """Dynamically generate valid test cases based on available units"""
        test_cases = []
        
        # Define test cases based on available quantity classes
        class_specific_cases = {
            'pressure': [
                {'source': 'psi', 'target': 'Pa', 'value': '50', 'expected_approx': 344738, 'tolerance': 10}
            ],
            'length': [
                {'source': 'ft', 'target': 'm', 'value': '100', 'expected_approx': 30.48, 'tolerance': 0.01}
            ],
            'mass': [
                {'source': 'lb', 'target': 'kg', 'value': '10', 'expected_approx': 4.54, 'tolerance': 0.01}
            ],
            'temperature': [
                {'source': 'F', 'target': 'C', 'value': '32', 'expected_approx': 0, 'tolerance': 0.1}
            ],
            'time': [
                {'source': 'h', 'target': 's', 'value': '1', 'expected_approx': 3600, 'tolerance': 0.1}
            ]
        }
        
        # Add only test cases for available quantity classes
        for qc_name, qc_data in self.available_quantity_classes.items():
            if qc_name in class_specific_cases:
                for case in class_specific_cases[qc_name]:
                    # Check if both source and target units are available
                    if (case['source'] in qc_data['member_units'] and 
                        case['target'] in qc_data['member_units']):
                        
                        test_cases.append({
                            'sourceValue': case['value'],
                            'sourceUnit': case['source'],
                            'targetUnit': case['target'],
                            'expected_approx': case['expected_approx'],
                            'tolerance': case['tolerance'],
                            'quantity_class': qc_name
                        })
                        
                        logger.info(f"Added test case: {case['source']} to {case['target']} in {qc_name}")
        
        # If we couldn't find any of our predefined test cases, create some generic ones
        if not test_cases:
            logger.warning("No predefined test cases matched available units, creating generic tests")
            
            for qc_name, qc_data in self.available_quantity_classes.items():
                if len(qc_data['member_units']) >= 2 and qc_data['base_unit']:
                    # Find two different units that aren't the base unit
                    avail_units = [u for u in qc_data['member_units'] if u != qc_data['base_unit']]
                    
                    if len(avail_units) >= 2:
                        test_cases.append({
                            'sourceValue': '1',
                            'sourceUnit': avail_units[0],
                            'targetUnit': avail_units[1],
                            'quantity_class': qc_name,
                            'dynamic': True  # Flag that we don't have expected values
                        })
                        
                        logger.info(f"Added generic test: {avail_units[0]} to {avail_units[1]} in {qc_name}")
        
        return test_cases

    def test_convert_common_units(self):
        """Test conversion of common units using real dictionary"""
        test_cases = self.get_valid_conversion_test_cases()
        
        if not test_cases:
            self.skipTest("No suitable test cases found with available units")
        
        for test_case in test_cases:
            with self.subTest(f"Converting {test_case['sourceValue']} {test_case['sourceUnit']} to {test_case['targetUnit']}"):
                logger.info(f"Testing conversion: {test_case['sourceValue']} {test_case['sourceUnit']} to {test_case['targetUnit']}")
                
                response = self.app.post(
                    '/api/convert',
                    json={
                        'sourceValue': test_case['sourceValue'],
                        'sourceUnit': test_case['sourceUnit'],
                        'targetUnit': test_case['targetUnit']
                    },
                    content_type='application/json'
                )
                
                # Log the response for debugging
                if response.status_code != 200:
                    logger.error(f"Failed conversion response: {response.data}")
                
                self.assertEqual(response.status_code, 200, 
                               f"Failed to convert {test_case['sourceUnit']} to {test_case['targetUnit']}")
                
                data = json.loads(response.data)
                logger.info(f"Conversion result: {data}")
                
                # Verify the proper units and quantity class in response
                self.assertEqual(data['sourceUnit'], test_case['sourceUnit'])
                self.assertEqual(data['targetUnit'], test_case['targetUnit'])
                
                # For dynamic test cases, we don't verify the result value
                if 'dynamic' not in test_case:
                    # Verify the conversion result is approximately as expected
                    tolerance = test_case.get('tolerance', 0.01)
                    actual_value = float(data['targetValue'])
                    expected_value = test_case['expected_approx']
                    
                    self.assertAlmostEqual(
                        actual_value, 
                        expected_value,
                        delta=tolerance,
                        msg=f"Conversion result for {test_case['sourceUnit']} to {test_case['targetUnit']} is off: got {actual_value}, expected {expected_value} ± {tolerance}"
                    )
                
                # Sometimes the API might return a slightly different quantity class name
                # (e.g., "pressure" vs "Pressure"), so we check with case insensitivity
                if 'quantity_class' in test_case and 'quantityClass' in data:
                    self.assertEqual(
                        data['quantityClass'].lower(), 
                        test_case['quantity_class'].lower()
                    )

    def test_incompatible_units(self):
        """Test conversion with incompatible units using real dictionary"""
        # Find two units from different quantity classes
        if len(self.available_quantity_classes) < 2:
            self.skipTest("Need at least two quantity classes for incompatible units test")
        
        # Get the first two quantity classes
        qc_names = list(self.available_quantity_classes.keys())
        qc1, qc2 = qc_names[0], qc_names[1]
        
        # Get a unit from each class
        unit1 = self.available_quantity_classes[qc1]['member_units'][0]
        unit2 = self.available_quantity_classes[qc2]['member_units'][0]
        
        logger.info(f"Testing incompatible units: {unit1} ({qc1}) and {unit2} ({qc2})")
        
        # Test data with incompatible units
        test_data = {
            'sourceValue': '50',
            'sourceUnit': unit1,
            'targetUnit': unit2
        }
        
        # Make the request
        response = self.app.post(
            '/api/convert', 
            json=test_data,
            content_type='application/json'
        )
        
        # Log response for debugging
        logger.info(f"Incompatible units response: {response.data}")
        
        # Check response - should be a 400 error or contain an error message
        data = json.loads(response.data)
        
        if response.status_code == 400:
            self.assertIn('error', data)
        else:
            # Some APIs might return a 200 but include an error message
            self.assertTrue(
                'error' in data or 
                (data.get('success') == False) or
                (data.get('compatible') == False),
                "Response doesn't indicate incompatible units error"
            )

    def test_invalid_units(self):
        """Test conversion with invalid units using real dictionary"""
        # Test with an invalid unit
        test_data = {
            'sourceValue': '50',
            'sourceUnit': list(self.available_quantity_classes.values())[0]['member_units'][0],
            'targetUnit': 'nonexistentunit_xyz123'
        }
        
        logger.info(f"Testing invalid unit: {test_data}")
        
        response = self.app.post(
            '/api/convert', 
            json=test_data,
            content_type='application/json'
        )
        
        # Log response for debugging
        logger.info(f"Invalid unit response: {response.data}")
        
        # Should return an error (400) or a 200 with error info
        data = json.loads(response.data)
        
        if response.status_code != 200:
            self.assertIn('error', data)
        else:
            # Some APIs might return 200 but include an error indicator
            self.assertTrue(
                'error' in data or 
                (data.get('success') == False),
                "Response doesn't indicate invalid unit error"
            )

    def test_invalid_value(self):
        """Test conversion with invalid value using real dictionary"""
        if not self.available_quantity_classes:
            self.skipTest("No quantity classes available for testing")
            
        # Get a valid unit for testing
        qc_name = list(self.available_quantity_classes.keys())[0]
        valid_unit = self.available_quantity_classes[qc_name]['member_units'][0]
        
        # Test with an invalid value
        test_data = {
            'sourceValue': 'not-a-number',
            'sourceUnit': valid_unit,
            'targetUnit': valid_unit
        }
        
        logger.info(f"Testing invalid value: {test_data}")
        
        response = self.app.post(
            '/api/convert', 
            json=test_data,
            content_type='application/json'
        )
        
        # Log response for debugging
        logger.info(f"Invalid value response: {response.data}")
        
        # Should return an error or error indicator
        data = json.loads(response.data)
        
        if response.status_code != 200:
            self.assertIn('error', data)
        else:
            # Some APIs might return 200 but include an error indicator
            self.assertTrue(
                'error' in data or 
                (data.get('success') == False),
                "Response doesn't indicate invalid value error"
            )

if __name__ == '__main__':
    unittest.main()