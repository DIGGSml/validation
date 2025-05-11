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

def generate_html_report(xml_validation_report, html_xslt_path, html_output_path):
    """
    Transform XML validation report to HTML report
    
    Args:
        xml_validation_report: Path to the XML validation report
        html_xslt_path: Path to the HTML report XSLT stylesheet
        html_output_path: Path to save the HTML report
    
    Returns:
        True if successful, False otherwise
    """
    try:
        # Create a Saxon processor for HTML transformation
        with PySaxonProcessor(license=False) as proc:
            # Create an XSLT compiler
            xslt = proc.new_xslt30_processor()
            
            # Compile the HTML stylesheet
            executable = xslt.compile_stylesheet(stylesheet_file=html_xslt_path)
            
            # Transform the XML to HTML
            html_result = executable.transform_to_string(source_file=xml_validation_report)
            
            # Save the HTML result
            with open(html_output_path, 'w', encoding='utf-8') as f:
                f.write(html_result)
            
            print(f"HTML report generated successfully: {html_output_path}")
            return True
    except Exception as e:
        print(f"Error generating HTML report: {e}")
        return False

# Example usage
if __name__ == "__main__":
    # Define file paths
    xml_file = "/workspaces/validation/challange_file.xml"
    validation_xslt = "/workspaces/validation/diggs-validation.xsl"  # First XSLT
    html_report_xslt = "/workspaces/validation/validation-report-html.xsl"  # Second XSLT 
    
    # Define output paths
    xml_output = "/workspaces/validation/validation-output_new.xml"
    html_output = "/workspaces/validation/validation-report_new.html"
    
    # Optional parameters for validation
    params = {
        "whiteListFile": "/workspaces/validation/whiteList.xml"
    }
    
    # Step 1: Run XML validation
    print("Running XML validation...")
    validation_result = validate_xml_with_xslt(xml_file, validation_xslt, xml_output, params)
    print(f"Validation completed. XML report saved to: {xml_output}")
    
    # Step 2: Generate HTML report from validation result
    print("Generating HTML report...")
    generate_html_report(xml_output, html_report_xslt, html_output)
    print(f"Complete! Open {html_output} in a browser to view the interactive report.")