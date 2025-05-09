<?xml version='1.0' encoding='utf-8'?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" 
  xmlns:diggs="http://diggsml.org/schema-dev" 
  xmlns:gml="http://www.opengis.net/gml/3.2" 
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  
  <title>DIGGS Schematron Validation Rules</title>
  <p>Validation rules for DIGGS XML files generated from the DIGGS Schematron rules spreadsheet.</p>
  
  <ns prefix="diggs" uri="http://diggsml.org/schema-dev"/>
  <ns prefix="gml" uri="http://www.opengis.net/gml/3.2"/>
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink"/>
  <ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance"/>
  
  <pattern id="DIGGS-validation-rules">
    <rule context="//diggs:DrivenPenetrationTest//diggs:hammerEfficiency">
      <assert test="number(.) &gt;= 0 and number(.) &lt;= 100" role="ERROR">Energy efficiency must be between 0 and 100</assert>
    </rule>
    <rule context="//diggs:Casing//diggs:casingOutsideDiameter">
      <assert test="number(.) &gt; 0" role="ERROR">casingOutsideDiameter must be positive</assert>
    </rule>
  </pattern>
</schema>