from saxonche import PySaxonProcessor

def validate_xml_with_xslt(xml_file_path, xslt_file_path, output_file_path=None, parameters=None):
    """
    Validate XML using XSLT via Saxon-C
    
    Args:
        xml_file_path: Path to the XML file to validate
        xslt_file_path: Path to the XSLT stylesheet
        output_file_path: Optional path to save the validation report
        parameters: Optional dictionary of parameters to pass to the XSLT
    
    Returns:
        The validation result as a string
    """
    # Create a Saxon processor
    with PySaxonProcessor(license=False) as proc:
        # Create an XSLT compiler
        xslt = proc.new_xslt30_processor()
        
        # Set parameters if provided
        if parameters:
            for key, value in parameters.items():
                xslt.set_parameter(key, proc.make_string_value(value))
        
        # Compile the stylesheet
        executable = xslt.compile_stylesheet(stylesheet_file=xslt_file_path)
        
        # Transform the XML
        result = executable.transform_to_string(source_file=xml_file_path)
        
        # Save the result if output path is specified
        if output_file_path:
            with open(output_file_path, 'w', encoding='utf-8') as f:
                f.write(result)
        
        return result

# Example usage
if __name__ == "__main__":
    xml_file = "/workspaces/validation/schematronTest.xml"
    xslt_file = "diggs-validation.xsl"  # Your main stylesheet
    output_file = "/workspaces/validation/validation-output_new.xml"
    
    # Optional parameters (based on your XSLT)
    params = {
        "whiteListFile": "/workspaces/validation/whiteList.xml"
    }
    
    validation_result = validate_xml_with_xslt(xml_file, xslt_file, output_file, params)
    print("Validation completed. Report saved to:", output_file)