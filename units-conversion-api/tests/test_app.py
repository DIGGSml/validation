"""
Unit tests for the Units Conversion API
"""

import unittest
import json
from unittest.mock import patch, MagicMock
import xml.etree.ElementTree as ET
import sys
import os

# More reliable way to add the parent directory to the path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Rest of your imports
from app import app, fetch_units_dictionary, convert_to_base_unit, convert_from_base_unit

class TestUnitsConversionAPI(unittest.TestCase):
    """Test cases for the Units Conversion API"""

    def setUp(self):
        """Set up test client and mock data"""
        self.app = app.test_client()
        self.app.testing = True
        
        # Create mock XML data for testing
        self.mock_xml = """
        <unitsDictionary>
            <quantityClass>
                <name>pressure</name>
                <dimension>M/LT2</dimension>
                <baseForConversion>Pa</baseForConversion>
                <memberUnit>psi</memberUnit>
                <memberUnit>MPa</memberUnit>
                <memberUnit>Pa</memberUnit>
            </quantityClass>
            <unit>
                <symbol>psi</symbol>
                <name>pound-force per square inch</name>
                <dimension>M/LT2</dimension>
                <isSI>false</isSI>
                <category>atom-special</category>
                <baseUnit>Pa</baseUnit>
                <conversionRef>DEFINITION</conversionRef>
                <isExact>true</isExact>
                <A>0</A>
                <B>4.4482216152605</B>
                <C>6.4516E-4</C>
                <D>0</D>
            </unit>
            <unit>
                <symbol>MPa</symbol>
                <name>megapascal</name>
                <dimension>M/LT2</dimension>
                <isSI>true</isSI>
                <category>prefixed</category>
                <baseUnit>Pa</baseUnit>
                <conversionRef>DERIVED</conversionRef>
                <isExact>true</isExact>
                <A>0</A>
                <B>1E6</B>
                <C>1</C>
                <D>0</D>
            </unit>
            <unit>
                <symbol>Pa</symbol>
                <name>pascal</name>
                <dimension>M/LT2</dimension>
                <isSI>true</isSI>
                <category>atom-special</category>
                <isBase/>
            </unit>
        </unitsDictionary>
        """
        
        # Parse the mock XML
        self.mock_root = ET.fromstring(self.mock_xml)

    @patch('app.fetch_units_dictionary')
    def test_convert_endpoint(self, mock_fetch):
        """Test the /api/convert endpoint"""
        # Set up the mock to return our test data
        mock_fetch.return_value = self.mock_root
        
        # Test data
        test_data = {
            'sourceValue': '50',
            'sourceUnit': 'psi',
            'targetUnit': 'MPa'
        }
        
        # Make the request
        response = self.app.post('/api/convert', 
                                json=test_data,
                                content_type='application/json')
        
        # Check response
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        
        # We expect approximately 0.345 MPa for 50 psi
        self.assertAlmostEqual(data['targetValue'], 0.345, places=2)
        self.assertEqual(data['sourceUnit'], 'psi')
        self.assertEqual(data['targetUnit'], 'MPa')
        self.assertEqual(data['quantityClass'], 'pressure')
        
    @patch('app.fetch_units_dictionary')
    def test_incompatible_units(self, mock_fetch):
        """Test conversion with incompatible units"""
        # Set up the mock
        mock_fetch.return_value = self.mock_root
        
        # Add a new incompatible quantity class to our mock
        temp_class = ET.SubElement(self.mock_root, 'quantityClass')
        ET.SubElement(temp_class, 'name').text = 'temperature'
        ET.SubElement(temp_class, 'memberUnit').text = 'C'
        
        # Test data with incompatible units
        test_data = {
            'sourceValue': '50',
            'sourceUnit': 'psi',
            'targetUnit': 'C'  # Not in same quantity class
        }
        
        # Make the request
        response = self.app.post('/api/convert', 
                                json=test_data,
                                content_type='application/json')
        
        # Check response - should be a 400 error
        self.assertEqual(response.status_code, 400)
        data = json.loads(response.data)
        self.assertIn('error', data)
        self.assertIn('not compatible', data['error'])
        
    def test_convert_to_base_unit(self):
        """Test the convert_to_base_unit function"""
        # Test parameters for psi to Pa conversion
        params = {
            'isBase': False,
            'A': 0,
            'B': 4.4482216152605,
            'C': 6.4516E-4,
            'D': 0
        }
        
        # Convert 50 psi to Pa
        result = convert_to_base_unit(50, params)
        
        # Expected result: approximately 344737.9 Pa
        self.assertAlmostEqual(result, 344737.9, places=1)
        
    def test_convert_from_base_unit(self):
        """Test the convert_from_base_unit function"""
        # Test parameters for Pa to MPa conversion
        params = {
            'isBase': False,
            'A': 0,
            'B': 1E6,
            'C': 1,
            'D': 0
        }
        
        # Convert 344737.9 Pa to MPa
        result = convert_from_base_unit(344737.9, params)
        
        # Expected result: approximately 0.345 MPa
        self.assertAlmostEqual(result, 0.345, places=3)
        
    def test_health_endpoint(self):
        """Test the health check endpoint"""
        response = self.app.get('/api/health')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'healthy')
        
    @patch('app.fetch_units_dictionary')
    def test_quantity_classes_endpoint(self, mock_fetch):
        """Test the quantity classes endpoint"""
        # Set up the mock
        mock_fetch.return_value = self.mock_root
        
        # Make the request
        response = self.app.get('/api/quantityclasses')
        
        # Check response
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        
        # We should have at least our pressure class
        self.assertGreaterEqual(len(data), 1)
        self.assertTrue(any(item['name'] == 'pressure' for item in data))

    @patch('app.requests.get')
    def test_fetch_units_dictionary_exception(self, mock_get):
        """Test exception handling in fetch_units_dictionary"""
        # Make the request raise an exception
        mock_get.side_effect = Exception("Test exception")
        
        # Check that the function raises an exception
        with self.assertRaises(Exception):
            fetch_units_dictionary()

if __name__ == '__main__':
    unittest.main()