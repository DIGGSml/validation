"""
Units Conversion API

This API converts values between different units using the DIGGS Units Dictionary.
"""

from flask import Flask, request, jsonify
import requests
import xml.etree.ElementTree as ET
import logging
from functools import lru_cache

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# URL for the DIGGS Units Dictionary
UNITS_DICTIONARY_URL = 'https://diggsml.org/def/units/DiggsUomDictionary.xml'

# Dictionary cache
units_dictionary = None


@lru_cache(maxsize=1)
def fetch_units_dictionary():
    """
    Fetch and parse the units dictionary from the URL
    Returns a parsed XML tree
    """
    global units_dictionary
    if units_dictionary is not None:
        return units_dictionary
    
    try:
        response = requests.get(UNITS_DICTIONARY_URL)
        response.raise_for_status()
        
        # Parse XML
        root = ET.fromstring(response.content)
        units_dictionary = root
        return root
    except requests.RequestException as e:
        logger.error(f"Error fetching units dictionary: {e}")
        raise Exception("Failed to fetch units dictionary")
    except ET.ParseError as e:
        logger.error(f"Error parsing XML dictionary: {e}")
        raise Exception("Failed to parse units dictionary")


def units_in_same_quantity_class(root, source_unit, target_unit):
    """
    Check if source and target units belong to the same quantity class
    Returns the quantity class element if found, None otherwise
    """
    for quantity_class in root.findall('.//quantityClass'):
        member_units = [unit.text for unit in quantity_class.findall('memberUnit')]
        
        if source_unit in member_units and target_unit in member_units:
            return quantity_class
    
    return None


def get_conversion_parameters(root, unit_symbol):
    """
    Get conversion parameters for a unit
    Returns a dictionary with parameters or None if unit not found
    """
    for unit in root.findall('.//unit'):
        symbol = unit.find('symbol')
        if symbol is not None and symbol.text == unit_symbol:
            # Check if this is a base unit
            is_base = unit.find('isBase') is not None
            
            if is_base:
                return {"isBase": True}
            
            # Get conversion parameters
            params = {
                "isBase": False,
                "A": float(unit.find('A').text) if unit.find('A') is not None else 0,
                "B": float(unit.find('B').text) if unit.find('B') is not None else 0,
                "C": float(unit.find('C').text) if unit.find('C') is not None else 0,
                "D": float(unit.find('D').text) if unit.find('D') is not None else 0,
                "isExact": unit.find('isExact').text.lower() == 'true' if unit.find('isExact') is not None else False
            }
            return params
    
    return None


def convert_to_base_unit(value, params):
    """
    Convert value to base unit
    Formula: y = (A + Bx) / (C + Dx)
    """
    if params["isBase"]:
        return value
    
    A, B, C, D = params["A"], params["B"], params["C"], params["D"]
    return (A + B * value) / (C + D * value)


def convert_from_base_unit(base_value, params):
    """
    Convert base unit value to target unit
    Formula: z = (A - Cy) / (Dy - B)
    """
    if params["isBase"]:
        return base_value
    
    A, B, C, D = params["A"], params["B"], params["C"], params["D"]
    
    # Avoid division by zero for zero values of D
    if D == 0 or abs(D) < 1e-10:
        # Alternative formula when D=0: z = (A - Cy) / (-B)
        # This simplifies to z = (Cy - A) / B
        return (A + C * base_value) / B
    
    return (A - C * base_value) / (D * base_value - B)


@app.route('/api/convert', methods=['POST'])
def convert():
    """
    Main conversion endpoint
    """
    try:
        data = request.json
        
        # Validate input
        if not all(k in data for k in ['sourceValue', 'sourceUnit', 'targetUnit']):
            return jsonify({
                'error': 'Missing required parameters. Please provide sourceValue, sourceUnit, and targetUnit'
            }), 400
        
        source_value = data['sourceValue']
        source_unit = data['sourceUnit']
        target_unit = data['targetUnit']
        
        # Convert source value to float
        try:
            numeric_value = float(source_value)
        except ValueError:
            return jsonify({'error': 'Source value must be a valid number'}), 400
        
        # Fetch dictionary
        root = fetch_units_dictionary()
        
        # Check if units are in the same quantity class
        quantity_class = units_in_same_quantity_class(root, source_unit, target_unit)
        if quantity_class is None:
            return jsonify({
                'error': 'Units are not compatible. They must belong to the same quantity class.'
            }), 400
        
        # Get conversion parameters
        source_params = get_conversion_parameters(root, source_unit)
        target_params = get_conversion_parameters(root, target_unit)
        
        if source_params is None or target_params is None:
            return jsonify({'error': 'One or both units not found in dictionary'}), 400
        
        # Convert to base unit
        base_value = convert_to_base_unit(numeric_value, source_params)
        
        # Convert from base unit to target unit
        target_value = convert_from_base_unit(base_value, target_params)
        
        # Determine if conversion is exact
        is_exact = (source_params["isBase"] or target_params["isBase"] or 
                   (source_params.get("isExact", False) and target_params.get("isExact", False)))
        
        # Get quantity class name and base unit
        quantity_class_name = quantity_class.find('name').text
        base_unit = quantity_class.find('baseForConversion').text
        
        # Return result
        return jsonify({
            'sourceValue': numeric_value,
            'sourceUnit': source_unit,
            'targetValue': target_value,
            'targetUnit': target_unit,
            'baseValue': base_value,
            'baseUnit': base_unit,
            'isExact': is_exact,
            'quantityClass': quantity_class_name
        })
        
    except Exception as e:
        logger.error(f"Conversion error: {e}")
        return jsonify({'error': 'Conversion failed. Please try again later.'}), 500


@app.route('/api/units/<quantity_class_name>', methods=['GET'])
def get_units_for_class(quantity_class_name):
    """
    Get all available units for a quantity class
    """
    try:
        # Fetch dictionary
        root = fetch_units_dictionary()
        
        # Find the quantity class
        found = False
        member_units = []
        base_unit = None
        
        for quantity_class in root.findall('.//quantityClass'):
            name = quantity_class.find('name')
            if name is not None and name.text == quantity_class_name:
                found = True
                member_units = [unit.text for unit in quantity_class.findall('memberUnit')]
                base_for_conversion = quantity_class.find('baseForConversion')
                if base_for_conversion is not None:
                    base_unit = base_for_conversion.text
                break
        
        if not found:
            return jsonify({'error': 'Quantity class not found'}), 404
        
        # Return all member units
        return jsonify({
            'quantityClass': quantity_class_name,
            'baseUnit': base_unit,
            'units': member_units
        })
        
    except Exception as e:
        logger.error(f"Error fetching units: {e}")
        return jsonify({'error': 'Failed to fetch units. Please try again later.'}), 500


@app.route('/api/quantityclasses', methods=['GET'])
def get_quantity_classes():
    """
    Get all available quantity classes
    """
    try:
        # Fetch dictionary
        root = fetch_units_dictionary()
        
        # Extract quantity class names
        class_data = []
        for quantity_class in root.findall('.//quantityClass'):
            name = quantity_class.find('name')
            base_unit = quantity_class.find('baseForConversion')
            
            if name is not None:
                class_info = {'name': name.text}
                if base_unit is not None:
                    class_info['baseUnit'] = base_unit.text
                class_data.append(class_info)
        
        return jsonify(class_data)
        
    except Exception as e:
        logger.error(f"Error fetching quantity classes: {e}")
        return jsonify({'error': 'Failed to fetch quantity classes. Please try again later.'}), 500


@app.route('/api/health', methods=['GET'])
def health_check():
    """
    Health check endpoint
    """
    return jsonify({'status': 'healthy'})


# Example test function
def test_conversion():
    """
    Manual test function to verify conversion logic
    """
    try:
        # Test converting 50 psi to MPa
        root = fetch_units_dictionary()
        
        source_unit = 'psi'
        target_unit = 'MPa'
        source_value = 50
        
        # Find quantity class
        quantity_class = units_in_same_quantity_class(root, source_unit, target_unit)
        quantity_class_name = quantity_class.find('name').text if quantity_class is not None else None
        print(f'Quantity Class: {quantity_class_name}')
        
        # Get conversion parameters
        source_params = get_conversion_parameters(root, source_unit)
        target_params = get_conversion_parameters(root, target_unit)
        
        print(f'Source Parameters: {source_params}')
        print(f'Target Parameters: {target_params}')
        
        # Convert to base unit
        base_value = convert_to_base_unit(source_value, source_params)
        base_unit = quantity_class.find('baseForConversion').text if quantity_class is not None else None
        print(f'Base Value: {base_value} {base_unit}')
        
        # Convert to target unit
        target_value = convert_from_base_unit(base_value, target_params)
        print(f'Target Value: {target_value} {target_unit}')
        
    except Exception as e:
        print(f'Test error: {e}')


if __name__ == '__main__':
    # Uncomment to run test function
    # test_conversion()
    
    app.run(debug=True, host='0.0.0.0', port=5000)