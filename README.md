# Semantic Validation Repository

## Introduction

 This repository is for the development of xslt scripts to perform complex validation tasks on DIGGS instances as well as unit conversion lookups. When completed, the scripts are copied to the def/validation repository for deployment.

Many elements of a DIGGS instance can be validated via standard syntactic and schema validation, but there are many context and structural constraints on the data that can't be validated solely by schema (semantic validation). The goal of this project is to develop rules for more complex semantic validation tasks. Many of these validation needs are complex, involving progressive validation steps for an element, external dictionary or other file lookups, validating the structure of &lt;dataBlock&gt; string elements for consistency,  validating geometry coordinate structure for dimensional consistency, validating href links, etc. Failure to perform semantic validation of DIGGS files may cause processing applications to fail to properly ingest and process DIGGS instances.

To address the issue of semantic validation, this project's goal is to develop a normative set of XSLT transform modules that will take DIGGS instance files and output messages in a simple XML format via a workflow chain. This output can then be displayed in a browser (through another XSL style sheet) or otherwise processed by applications. The advantage of this approach is that the DIGGS project will be able to:

- Write one set of normative rules for semantic validation that can be deployed in different scenarios
- Provide consistency in validation results regardless of platform or application
- Reduced maintenance overhead

XSLT transforms are portable and can be applied in:

- Web applications (regardless of backend language - Python, JavaScript, PHP, etc.)
- Desktop environments using Saxon processors
- XML editors like Oxygen or StylusStudio
- Command-line processing pipelines

## Overall Approach

### Schema validation

Syntactic and schema validation is required before semantic validation can be done and is not part of this project, but semantic validation can be part of a pipeline that includes syntactic and schema validation as initial steps. Syntactic and schema validation can be accomplished using existing online tools (from Geosetta, Validation Xpress or <https://www.freeformatter.com/xml-validator-xsd.html#google_vignette>), or on the desktop using a commercial XML editor (Oxygen) or custom applications that use open-sourcem scheama-aware XML Parser Library such as Xerces, libxmljs2 or lxml. 

### Accessing external resources

Some semantic validation will require accessing external resources such as code list dictionaries, CRS definitions, etc. There are security concerns when outside resources are accessed. We propose to address this issue through the use of a parameter file that will contain whitelisted URLs (or URL fragments) that are safe. The DIGGS project will provide a vhiteList.xml file for this purpose that is preloaded with DIGGS, OGC, and EPSG URL fragments that are known to be safe, and that a user can customize for validation using custom resources. Note: in some environments, such as browser-based applications, CORS restrictions may prevent these XSLT stylesheets from accessing necessary external resources regardless of the white list.

For efficiency, external resources are cached once loaded by the workflow.

### Semantic validation report

The validation report output by the XSLT modules consists of a copy of the DIGGS file being validated, plus a group of messageSet elements. A messageSet element is output whenever a line in the XML instance fails validation. Each messageSet element contains the following elements:

- severity - levels are Error, Warning, and Info
- step - name of the validation step where the failure occurred. Each XSLT module performs one step of the validation.
- elementPath - the xpath of the element or attribute where the failure occurs
- text - a message explaining the nature of the failure
- source - a serialized copy of the element where the failure occurred

With respect to severity,

- INFO messages identify issues that suggest review to ensure data integrity, for example that the correct authority is referenced for a codeType term.
- WARNING indicates that validation couldn't be completed, such as when a resource needed for validation is unavailable due to white list issues, or where interoperability might be affected.
- ERROR indicates an issue that can affect processing of the XML file, such as incorrect codes for the context, pointers to invalid objects, or resources that don't resolve, etc.

### Deployment Scheme
  
The suite of validation stylesheets will be hosted and maintained at <https://diggsml.org/def/validation>. A master stylesheet (diggs-validation.xsl) is configured for "full-suite" validation. The modules that perform the actual validation will be hosted and maintained at  <https://diggsml.org/def/validation/modules>. Additional resources are:

- a whiteList.xml file pre-populated with URL fragments for commonly accessed resources and local files.
- a second stylesheet (validation-report-html.xsl), that will convert the XML output from the validation modules to an interactive report that can be viewed in a browser.

diggs-validaton.xsl and whitelist.xml are intended for user customization (add custom modules, validate with fewer modules, etc.) when used locally.

## Proposed XSLT modules

The following XSLT modules are proposed for semantic validation. As they are developed they will be added to the master diggs-validation.xsl stylesheet. All modules are written in XSLT 3.0 to take advantage of advanced features, using only features that meet the specification without extension functions. This will allow processing to use free XSLT processors, like Saxon-HE.

#### DIGGS structure check

Checks that the XML file contains a Diggs root element and documentInformation element with one DocumentElement object. While this workflow does not do full schema validation, this checks basic structural integriity of the file before proceeding. Failure in passing this check terminates additonal module checks in the master stylesheet. ***COMPLETED***

#### DIGGS Schema Check

Checks that the file has a schemaLocation attribute in the root element, that the target schema file can be accessed and is a DIGGS schema file. Also checks for neamespace consistency between document, schemaLocation, and schema. The master style sheet will prevent execution of subsequent modules if this check fails. ***COMPLETED***

#### CodeType valdation

Checks that codeType elements that have DIGGS standard code list dictionaries defined for them have a codeSpace attribute that references a DIGGS dictionary located at https://diggsml.org/def/codes. This step relies on a helper xml file at https://diggsml.org/def/validation/definedCodeTypes.xml, which stores
a list of xpaths to elements that have DIGGS standard code llsts defined for them. This file is generated programmatically using GitHub actions, whenever the DIGGS Standard dictionaries are updated.  ***COMPLETED***

#### Dictionary validation
  
For each element in the DIGGS file that contains a codeSpace attribute, runs through a progressive sequence of checks that:

   1. checks if the codeSpace value is a URL to a dictionary definition. (value starts with http:, https:, file: or local path (eg ./) and contains a # character). Outputs an info message if not. ***COMPLETED***
   2. If 1 passes, checks codeSpace to see if it passes the white list check. Outputs a warning if not. ***COMPLETED***
   3. If 2 passes, checks if dictionary file can be accessed. Outputs an error if not. ***COMPLETED***
   4. Uf 3 passes, checks if the resource is a DIGGS dictionary, Outputs an error if not.  ***COMPLETED***
   5. If 4 passes, checks to see that the codeSpace returns a Definition element. Outputs an error if not.  ***COMPLETED***
   6. If 5 passes, checks that element containing the codeSpace matches sourceElementXpath in the dictionary definition. Outputs an error if not.  ***COMPLETED***
   7. If 6 passes, checks that the element value is a case insensitive match to any of the gml:mame elements in the Definition. Outputs an INFO if not.  ***COMPLETED***
   8. If 7 passes, check that the name of the element that contains the codeSpace is propertyClass. If not, terminate validation (success), else proceed with the remaining steps.  ***COMPLETED***
   9. Check that conditionalElementXpath from the dictionary can be found in the DIGGS file. This checks that the property is used in correct measurement context (eg.liquid limit is reported for an Atterberg procedure and not for a particle size test). Pass if it does or if there is no procedure object to test, otherwise report an error.  ***COMPLETED***
   10. If 9 passes, check that the value of the sibling dataType matches the dataType value from the Dictionary definition. Outputs an error if not.  ***COMPLETED***
   11. If 10 passes, check if quantityClass element exists in the definition. If not, check that there is no sibling uom element; if so, output an error. Terminate with error or if there is no uom where quantityClass is empty, ***COMPLETED***
   12. If 11 passes, check that propertyClass has a sibling uom element. Outputs an error if not.  ***COMPLETED***
   13. If 12 passes, check that value of uom belongs to the quantityClass value from the Dictionary definition. Outputs an error if not. ***Completed***
   

#### Schematron validation for simple rule checks

Single element and cross-element schematron rules are being developed to handle less complex semantic validations, such as element-specific value range checks or cross-element checks. This module accesses schematron rules from the standard DIGGS schematron file and outputs the assertions in the same output format as the other modules.  ***COMPLETED***

#### Geometry validation

Schema requires that every geometry object contains srsName and srsDimension attributes. This check ensures taht srsName and srsDimension attributes are declared for each top-level geometry object ***COMPLETED***

#### CRS validation

This module checks that the srsName returns a valid GML formatted coordinate reference system definition. ***COMPLETED***

#### Coordinate validation

This module evaluates the coordinates reported in &lt;gml:pos&gt; and &lt;gml:posList&gt; are consistent with the srsDimension. For example, for srsDimension of 3, the  &lt;gml:pos&gt; element should contain exactly 3 coordinates, whereas &lt;gml:posList&gt; must contain a minimu of 6 coordinates in multiples of 3. ***COMPLETED***


#### xlink:href validation

DIGGS has reference properties that point sto other objects, either in the existing instance or in an external file. This check will ensure that a referenced object exists and that it is in the proper context (eg. a projectRef link points to a Project object)

#### Measurement structure check

DIGGS measurement and time series structures consist of a domain (containing either a geometry or a time object, and a range (a list of observed properties with a dataBlock that holds the results). The dataBlock reports comma-separated results within whitespace-separated tuples, with each tuple holding a result value for each observed property, and where each tuple corresponds to a single element in the geometry or time instance. This check will ensure structural integrity of the measurement or time-series object, ensuring that there are the same number of data block tuples as there are domain elements, and that each tuple contains the same number of comma-separated values as the number of declared observed properties.

#### Measureent results datatype and values check

This check will ensure that the measurement and time-series results are consistent with the dataType element of the corresponding Property object and (possibly) that the value of the result is appropriate for the property. This latter check will require extending the property dictionary schema to include value constraints for properties.
