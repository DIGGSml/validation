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
    # Determine namespace
    namespace = ""
    if "}" in root.tag:
        namespace = root.tag.split("}")[0] + "}"
    
    # Find the quantityClassSet element first
    quantity_class_set = None
    for child in root:
        if child.tag.endswith('quantityClassSet'):
            quantity_class_set = child
            break
    
    if quantity_class_set is None:
        logger.warning("Could not find quantityClassSet element")
        return None
    
    # Check each quantity class
    for quantity_class in quantity_class_set:
        if not quantity_class.tag.endswith('quantityClass'):
            continue
            
        # Get all memberUnit elements
        member_units = []
        for elem in quantity_class:
            if elem.tag.endswith('memberUnit'):
                member_units.append(elem.text)
        
        # Check if both source and target units are in this quantity class
        if source_unit in member_units and target_unit in member_units:
            logger.info(f"Found compatible quantity class for {source_unit} and {target_unit}")
            return quantity_class
    
    logger.warning(f"Units {source_unit} and {target_unit} are not in the same quantity class")
    return None

def get_conversion_parameters(root, unit_symbol):
    """
    Get conversion parameters for a unit
    Returns a dictionary with parameters or None if unit not found
    """
    # Determine namespace
    namespace = ""
    if "}" in root.tag:
        namespace = root.tag.split("}")[0] + "}"
    
    # Find the unitSet element first
    unit_set = None
    for child in root:
        if child.tag.endswith('unitSet'):
            unit_set = child
            break
    
    if unit_set is None:
        logger.warning("Could not find unitSet element")
        return None
    
    # Check each unit
    for unit in unit_set:
        if not unit.tag.endswith('unit'):
            continue
            
        # Get symbol element
        symbol_text = None
        for elem in unit:
            if elem.tag.endswith('symbol'):
                symbol_text = elem.text
                break
                
        if symbol_text is not None and symbol_text == unit_symbol:
            # Check if this is a base unit
            is_base = False
            for elem in unit:
                if elem.tag.endswith('isBase'):
                    is_base = True
                    break
            
            if is_base:
                logger.info(f"Unit {unit_symbol} is a base unit")
                return {"isBase": True}
            
            # Get conversion parameters with safe defaults
            params = {
                "isBase": False,
                "A": 0,
                "B": 0,
                "C": 0,
                "D": 0,
                "isExact": False
            }
            
            # Process all elements
            for elem in unit:
                tag = elem.tag.split('}')[-1]  # Get tag without namespace
                if tag == 'A' and elem.text:
                    params["A"] = float(elem.text)
                elif tag == 'B' and elem.text:
                    params["B"] = float(elem.text)
                elif tag == 'C' and elem.text:
                    params["C"] = float(elem.text)
                elif tag == 'D' and elem.text:
                    params["D"] = float(elem.text)
                elif tag == 'isExact' and elem.text:
                    params["isExact"] = elem.text.lower() == 'true'
            
            logger.info(f"Found conversion parameters for unit {unit_symbol}: {params}")
            return params
    
    logger.warning(f"Unit {unit_symbol} not found in dictionary")
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
        return (A - C * base_value) /(-B)
    
    return (A - C * base_value) / (D * base_value - B)


@app.route('/api/convert', methods=['GET', 'POST'])
def convert():
    """
    Main conversion endpoint
    Supports both GET and POST requests
    """
    try:
        # Handle both GET and POST requests
        if request.method == 'POST':
            data = request.json
        else:  # GET request
            data = {
                'sourceValue': request.args.get('sourceValue'),
                'sourceUnit': request.args.get('sourceUnit'),
                'targetUnit': request.args.get('targetUnit')
            }
        
        # Validate input
        if not all(k in data and data[k] is not None for k in ['sourceValue', 'sourceUnit', 'targetUnit']):
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
        
        # Determine if conversion is exact -true if one of the and clauses is true
        is_exact = ((source_params["isBase"] and target_params.get("isExact", False)) or
                   (target_params["isBase"] and source_params.get("isExact", False)) or
                   (source_params.get("isExact", False) and target_params.get("isExact", False)))
        
        # Get quantity class name and base unit
        quantity_class_name = None
        base_unit = None
        
        # Find the name element and baseForConversion element in the quantity class
        for elem in quantity_class:
            if elem.tag.endswith('name'):
                quantity_class_name = elem.text
            elif elem.tag.endswith('baseForConversion'):
                base_unit = elem.text
        
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
        
        # Determine namespace
        namespace = ""
        if "}" in root.tag:
            namespace = root.tag.split("}")[0] + "}"
        
        # Find the quantityClassSet element first
        quantity_class_set = None
        for child in root:
            if child.tag.endswith('quantityClassSet'):
                quantity_class_set = child
                break
        
        if quantity_class_set is None:
            return jsonify({'error': 'Could not find quantity classes'}), 500
        
        # Find the specified quantity class
        found = False
        member_units = []
        base_unit = None
        
        # Match case-insensitively
        for quantity_class in quantity_class_set:
            if not quantity_class.tag.endswith('quantityClass'):
                continue
                
            name_elem = None
            for elem in quantity_class:
                if elem.tag.endswith('name'):
                    name_elem = elem
                    break
                    
            if name_elem is not None and name_elem.text.lower() == quantity_class_name.lower():
                found = True
                
                # Get all memberUnit elements
                for elem in quantity_class:
                    if elem.tag.endswith('memberUnit'):
                        member_units.append(elem.text)
                    elif elem.tag.endswith('baseForConversion'):
                        base_unit = elem.text
                break
        
        if not found:
            logger.warning(f"Quantity class '{quantity_class_name}' not found")
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
        
        # Determine if there's a namespace
        namespace = ""
        if "}" in root.tag:
            namespace = root.tag.split("}")[0] + "}"
        
        # Find the quantityClassSet element first (direct child of root)
        quantity_class_set = None
        for child in root:
            if child.tag.endswith('quantityClassSet'):
                quantity_class_set = child
                break
        
        # If we found the quantityClassSet, look for quantityClass elements
        if quantity_class_set is not None:
            for quantity_class in quantity_class_set:
                if quantity_class.tag.endswith('quantityClass'):
                    # Get name element
                    name_elem = None
                    base_unit_elem = None
                    
                    for elem in quantity_class:
                        if elem.tag.endswith('name'):
                            name_elem = elem
                        elif elem.tag.endswith('baseForConversion'):
                            base_unit_elem = elem
                    
                    if name_elem is not None:
                        class_info = {'name': name_elem.text}
                        if base_unit_elem is not None:
                            class_info['baseUnit'] = base_unit_elem.text
                        class_data.append(class_info)
        
        logger.info(f"Returning {len(class_data)} quantity classes")
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

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)