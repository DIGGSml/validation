# Validation Repo

## Introduction

 This repository is for the development of scripts to perform complex validation tasks on DIGGS instances as well as unit conversion lookups

Many elements of a DIGGS instance can be validated via standard schema validation, but there are many context and structural constraints on the data that can't be validated solely by schema. The goal of this project is to develop rules for more complex content validation tasks. Many of these validation needs are complex, involving progressive validation steps for an element, external dictionary or other file lookups, validating the structure of &lt;dataBlock&gt; string elements for consistency,  validating geometry coordinate structure for dimensional consistency, validating href links, etc.

To address the issue of context validation, this project's goal is to develop a normative set of XSLT transform modules that will take DIGGS instance files and output messages in a simple XML format via a workflow chain. This output can then be displayed in a browser (through another XSL style sheet) or otherwise processed by applications. The advantage of this approach is that the DIGGS project will be able to:

- Write one set of normative rules that can be deployed in different scenarios
- Provide consistency in validation results regardless of platform or application
- Reduced maintenance overhead

XSLT transforms are portable and can be applied in:

- Web applications (regardless of backend language - Python, JavaScript, PHP, etc.)
- Desktop environments using Saxon processors
- XML editors like Oxygen
- Command-line processing pipelines

## Overall Approach

### Schema validation

Schema validation is required before context validation can be done and is not part of this workflow. Schema validation can be accomplished using existing online tools (from Geosetta, Validation Xpress or <https://www.freeformatter.com/xml-validator-xsd.html#google_vignette>), or on the desktop using a commercial XML editor (Oxygen) or open-source validation tools such as Xerces or VS Code with XML Language Support Extension by Red Hat. We could consider providing an XSLT module that could perform schema validation as part of the workflow, but this would likely require the Saxon-EE processor, which is a commercial (for cost) product.

### Accessing external resources

Some context validation will require accessing external resources such as code list dictionaries, CRS definitions, etc. There are security concerns when outside resources are accessed. We propose to address this issue through the use of a parameter file that will contain whitelisted URLs (or URL fragments) that are safe. The DIGGS project will provide a vhiteList.xml file for this purpose that is preloaded with DIGGS and OGC URL fragments that are known to be safe, and that a user can customize for validation using custom resources.

For efficiency, external resources will be cached once loaded by the workflow.

### Output format for XSLT output

The validation report output by the XSLT modules will be a simple table structure with each record of the table representing a group of messageSet elements. A messageSet is output whenever a line in the XML instance fails validation. Each messageSet element will contain the following elements:

- severity - proposed levels are Error, Warning, and Info
- step - name of the validation step where the failure occurred.
- elementPath - the xpath of the element or attribute where the failure occurs
- text - a message explaining the nature of the failure
- x\source - the xml string where the failure occurred

With respect to severity, 

- INTO messages identify issues that suggest review to ensure data integrity, for example that the correct authority is referenced for a codeType term
- WARNING indicates that validation couldn't be completed, such as when a resoure needed for validation is unavailable
- ERROR indiates an issue that can affect processing of the XML file, such as incorrect codes for the context, pointers to objects or resources that don't resolve, etc.

### Deployment Scheme
  
The suite of validation stylesheets would be hosted and maintained on the DIGGS Github site. Stamdard validation modules will be hosted on web server <https://diggsml.org/validation>, initially on Github pages. A master stylesheet (diggs_validation.xsl) will be configured for "full-suite" validation, along with a whiteList.xml file pre-populated with URL fragments for commonly accessed resources and local files. Both files are intended for user customization (add custom modules, validate with fewer modules, etc.)


## Proposed XSLT modules

The following XSLT modules are proposed for context validation. Each of these modules can be applied independently, but there will be a master style sheet that can be customized to generate a complete validation workflow. All modules will be written XSLT 3.0 to take advantage of advanced feature, using only features that meet the specification without extension functions. This will allow processing to use free XSLT processors, like Saxon-HE.

#### DIGGS structure check

Checks that the XML file contains a Diggs root element and documentInformation element with one DocumentElement object. While this workflow does not do full schema validation, this checks basic structural integriity of the file before proceeding. Failure in passing this check terminates additonal module checks in the master stylesheet. ***COMPLETED***

#### DIGGS Schema Check

Checks that the file has a schemaLocation attribute in the root element, that the target schema file can be accessed and is a DIGGS schema file. Also checks for neamespace consistency between document, schemaLocation, and schema. As another check on file integrity, the master style sheet will prevent execution of subsequent modules if this check fails. ***COMPLETED***

#### codeSpace occurrence

Checks that elements that have DIGGS standard code list dictionaries defined for them have a codeSpace attribute. Specific check procedure is TBD.

#### codeSpace validation
  
For each element in the DIGGS file that has a codeSpace attribute:

   1. checks if the codeSpace value is a URL to a dictionary definition. (value starts with http:, https: or file: and contains a # character). Outputs an info message if not. ***COMPLETED***
   2. If 1 passes, checks codeSpace to see if it passes the whiteList check. Outputs a warning if not. ***COMPLETED***
   3. If 2 passes, checks if dictionary file can be accessed. Outputs an error if not. ***COMPLETED***
   4. Uf 3 passes, checks if the resource is a DIGGS dictionary, Outputs an error if not.  ***COMPLETED***
   5. If 4 passes, checks to see that the codeSpace returns a Definition element. Outputs an error if not.  ***COMPLETED***
   6. If 5 passes, checks that element containing the codeSpace matched sourceElementXpath in the dictionary. Outputs an error if not.  ***COMPLETED***
   7. If 6 passes, checks that the elment value is a case insensitive match to any of the gml:mame elements in the Definition. Outputs a Warning if not.  ***COMPLETED***
   8. If 7 passes, check that the name of the element that contains the codeSpace is propertyClass. If not, terminate validation (success), else proceed with the remaining steps.  ***COMPLETED***
   9. Check that conditionalElementXpath from the dictionary exists. This checks that property is used in correct measurement context. Outputs an error if not.  ***COMPLETED***
   10. If 9 passes, check that the value of the sibling dataType  matches the dataType value from the Dictionary definition. Outputs an error if not.  ***COMPLETED***
   11. If 10 passes, check if quantityClass element exists in the definition. If not, check that there is no sibling uom element; if so, output an error. Terminate with error or if there is no uom where quantityClass is empty, ***COMPLETED***
   12. If 11 passes, check that propertyClass has a sibling uom element. Outputs an error if not.  ***COMPLETED***
   13. If 12 passes, check that value of uom belongs to the quantityClass value from the Dictionary definition. Outputs an error if not.
   

#### Schematron validation for simple rule checks

Single element and cross-element schematron rules are being developed using a Google spreadsheet. This module will either access the Google sheet via the gViz API, convert the result from json to xml schema, then process within the XSLT. Alternatively could work from a static sch file generated programmatically. Specific check procedure TBD.

#### CRS validation

Schema requires that every geometry object contains a SRSName and SRS Dimension. This check ensures taht srsName references a valid dictionary and that the srsDimension matches the dimension of the CRS. Detailed check procedure TBD.

#### xlink:href validation

DIGGS has reference properties that point sto other objects, either in the existing instance or in an internal file. This check will ensure that a referenced object exists and that it is in the proper context. Detailed check procedure TBD.

#### Coordinate validation

DIGGS geometry objects contain coordinate values in either gml:pos or gml:posList properties. The value of these properties is a doubleList with each value in the list representing a single coordinate, with axis order consistent with the CRS. This check will ensure that the number of coordinates is consistent with srsDimension. We may also consider if a check to ensure that coordinate values fall within the scope of teh CRS (this is a lot more work). Detailed check procedure TBD.

#### Measurement structure check

DIGGS measurement and time series structures consist of a domain (containing either a geometry or a time object) and a range, which lists observed properties with a dataBlock that hold the results for the properties. The dataBlock holds results in whitespace-separated tuples, with each tuple holding a result value for each observed property, and where each tuple corresponds to a single element in the geometry or time instance. This check will ensure structural integrity of the measurement or time-series object, ensuring that there are the same number of data block tuples as there are domain elements and that each tuple contains the same number of comma-separated values as the number of declared observed properties. Specific check procedure TBD.

#### Measureent results datatype and values check

This check will ensure that the measurement and time-series results are consistent with the dataType element of the corresponding Property object and that the value of the result is appropriate for the property. This latter check will likely require extending the property dictionary schema to include schematron rules. Specific check procedure TBD.
