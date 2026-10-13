<?xml version='1.0' encoding='utf-8'?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" 
  xmlns:diggs="http://diggsml.org/schema-dev"
  xmlns:gml="http://www.opengis.net/gml/3.2" 
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:error="http://www.w3.org/2005/xqt-errors"
  xmlns:json="http://www.w3.org/2005/xpath-functions"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" queryBinding="xslt3">
  
  <title>DIGGS Schematron Validation Rules</title>
  <p>Validation rules for DIGGS XML files.</p>
  <ns prefix="diggs" uri="http://diggsml.org/schema-dev"/>
  <ns prefix="gml" uri="http://www.opengis.net/gml/3.2"/>
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink"/>
  <ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance"/>
                 
  <!--
    Function to extract targetValue from unit conversion API response
    Parameters:
      - url: The URL of the unit conversion API endpoint
    Returns:
      - The targetValue as a string, or empty string if not found
-->
  <xsl:function name="diggs:extractTargetValue" as="xs:string">
    <xsl:param name="url" as="xs:string"/>
    
    <xsl:try>
      <xsl:variable name="jsonText" select="unparsed-text($url)"/>
      <xsl:variable name="jsonData" select="parse-json($jsonText)"/>
      
      <!-- Since we know the API structure, directly access targetValue -->
      <xsl:choose>
        <xsl:when test="$jsonData instance of map(xs:anyAtomicType, item()*) and map:contains($jsonData, 'targetValue')">
          <xsl:sequence select="string(map:get($jsonData, 'targetValue'))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="''"/>
        </xsl:otherwise>
      </xsl:choose>
      
      <xsl:catch>
        <xsl:message terminate="no">Error extracting targetValue from <xsl:value-of select="$url"/>: <xsl:value-of select="$error:description"/></xsl:message>
        <xsl:sequence select="''"/>
      </xsl:catch>
    </xsl:try>
  </xsl:function>  
  
  <pattern id="DIGGS-validation-rules">
    <rule context="//diggs:Borehole/diggs:totalMeasuredDepth" role="error">
      <assert test="number(.) &gt; 0">totalMeasuredDepth must be positive</assert>
    </rule>
    <rule context="//diggs:DriveSet/diggs:penetration" role="error">
      <assert test="number(.) &gt;= 0">Penetration depth must be positive</assert>
    </rule>
    <rule context="//diggs:DrivenPenetrationTest/diggs:hammerEfficiency" role="error">
      <assert test="number(.) &gt;= 0 and number(.) &lt;= 100">Energy efficiency must be between 0 and 100</assert>
    </rule>
    <rule context="//diggs:Casing/diggs:casingOutsideDiameter" role="error">
      <assert test="number(.) &gt; 0">casingOutsideDiameter must be positive</assert>
    </rule>

    <rule context="//diggs:Casing/diggs:casingInsideDiameter" role="error">
      <assert test="number(.) &gt; 0">casingInsideDiameter must be positive</assert>
    </rule>

    <rule context="//diggs:AbstractLinearSamplingFeature/diggs:plunge" role="error">
      <assert test="number(.) &gt;= -45 and number(.) &lt;= -10">Plunge must be between -45 and -10
        degrees</assert>
    </rule>
    <rule context="//diggs:CasagrandeTrial/diggs:waterContent" role="error">
      <assert test="number(.) &gt;= 0">waterContent must be non-negative</assert>
    </rule>
    <rule context="//diggs:CasagrandeTrial/diggs:blowCount" role="error">
      <assert test="number(.) &gt;= 0">blowCount must be non-negative</assert>
    </rule>
    <rule context="//diggs:FieldProperties/diggs:plasticity" role="error">
      <assert test="number(.) &gt;= 0">plasticity must be non-negative</assert>
    </rule>
    <rule context="//diggs:Cement/diggs:weight" role="error">
      <assert test="number(.) &gt; 0">weight must be positive</assert>
    </rule>
    <rule context="//diggs:Cement/diggs:specificGravity" role="error">
      <assert test="number(.) &gt; 0">specificGravity must be positive</assert>
    </rule>
    <rule context="//diggs:SpecimenConditions/diggs:voidRatio" role="error">
      <assert test="number(.) &gt;= 0">voidRatio must be non-negative</assert>
    </rule>
    <rule context="//diggs:Grading/diggs:percentPassing" role="error">
      <assert test="number(.) &gt;= 0">percentPassing must be non-negative</assert>
    </rule>
    <rule context="//diggs:Grading/diggs:percentRetained" role="error">
      <assert test="number(.) &gt;= 0">percentRetained must be non-negative</assert>
    </rule>
    <rule context="//diggs:Grading/diggs:weightRetained" role="error">
      <assert test="number(.) &gt; 0">weightRetained must be positive</assert>
    </rule>
    <rule context="//diggs:Grading/diggs:particleSize" role="error">
      <assert test="number(.) &gt; 0">particleSize must be positive</assert>
    </rule>
    <rule context="//diggs:AbstractTrialGroutBatch/diggs:specificGravityMix" role="error">
      <assert test="number(.) &gt; 1.0">Specific gravity mix must be greater than water
        (1.0)</assert>
    </rule>

    <rule context="*[local-name() = 'Casing'][*[local-name() = 'casingOutsideDiameter'] and *[local-name() = 'casingInsideDiameter']]" role="error">
      
      <let name="outsideDiameter" value="number(*[local-name() = 'casingOutsideDiameter'])"/>
      <let name="insideDiameter" value="number(*[local-name() = 'casingInsideDiameter'])"/>
      <let name="outsideUom" value="*[local-name() = 'casingOutsideDiameter']/@uom"/>
      <let name="insideUom" value="*[local-name() = 'casingInsideDiameter']/@uom"/>
      
      <!-- Basic validation -->
      <assert test="not(string($outsideDiameter) = 'NaN') and not(string($insideDiameter) = 'NaN') and string-length($outsideUom) > 0 and string-length($insideUom) > 0">
        Both diameter values must be numeric and have unit of measure attributes.
      </assert>
      
      <!-- Unit conversion using simplified function -->
      <let name="apiUrl" 
        value="if ($outsideUom = $insideUom) 
        then ''
        else concat('https://diggs.geosetta.org/api/units/convert?sourceValue=', 
        $insideDiameter, 
        '&amp;sourceUnit=', encode-for-uri($insideUom), 
        '&amp;targetUnit=', encode-for-uri($outsideUom))"/>
      
      <let name="convertedInsideDiameter" 
        value="if ($outsideUom = $insideUom) 
        then $insideDiameter
        else if ($apiUrl != '')
        then number(diggs:extractTargetValue($apiUrl))
        else ()"/>
      
      <let name="conversionSuccess" 
        value="$outsideUom = $insideUom or (exists($convertedInsideDiameter) and string($convertedInsideDiameter) != 'NaN')"/>
      
      <!-- Error handling -->
      <assert test="$conversionSuccess or 
        string($outsideDiameter) = 'NaN' or 
        string($insideDiameter) = 'NaN' or 
        string-length($outsideUom) = 0 or 
        string-length($insideUom) = 0">
        Failed to convert inside diameter from '<value-of select="$insideUom"/>' to '<value-of select="$outsideUom"/>'. 
        Unit conversion API call failed or returned invalid data.
        <value-of select="if ($apiUrl != '') then concat(' API URL: ', $apiUrl) else ''"/>
      </assert>
      
      <!-- Main comparison -->
      <assert test="string($outsideDiameter) = 'NaN' or 
        string($insideDiameter) = 'NaN' or 
        string-length($outsideUom) = 0 or 
        string-length($insideUom) = 0 or 
        not($conversionSuccess) or 
        $outsideDiameter > $convertedInsideDiameter">
        <value-of select="concat('casingOutsideDiameter (', $outsideDiameter, ' ', $outsideUom, ') must be greater than casingInsideDiameter (', $insideDiameter, ' ', $insideUom,
          if ($outsideUom != $insideUom and exists($convertedInsideDiameter)) 
          then concat(' = ', format-number($convertedInsideDiameter, '#.######'), ' ', $outsideUom,')') 
          else ')', '.')"/>
      </assert>
      
    </rule>
    
  </pattern>

  <!-- Remedial designs and the non-conformances they respond to (AbstractProgramDesignType/nonConformanceRef).
       Local-name tests are used so the rules fire on any DIGGS 3.x namespace. -->
  <pattern id="NC-ref-placement-errors">
    <rule context="*[local-name() = 'nonConformanceRef'][starts-with(@xlink:href, '#')]" role="error">
      <let name="target" value="(//*[@gml:id = substring(current()/@xlink:href, 2)])[1]"/>
      <let name="designId" value="string(../@gml:id)"/>
      <assert test="exists($target)">nonConformanceRef '<value-of select="@xlink:href"/>' does not resolve to an object in this file.</assert>
      <assert test="empty($target) or local-name($target) = 'NonConformance'">nonConformanceRef '<value-of select="@xlink:href"/>' must cite a NonConformance, but it cites a <value-of select="local-name($target)"/>.</assert>
      <!-- A design cannot respond to a finding on work built to that same design: the design precedes the work. -->
      <assert test="empty($target) or $designId = '' or not(
          some $f in $target/*[local-name() = 'samplingFeatureRef']/@xlink:href
          satisfies (//*[@gml:id = substring($f, 2)])[1]//*[local-name() = 'programDesignRef'][@xlink:href = concat('#', $designId)])">nonConformanceRef '<value-of select="@xlink:href"/>' is on design '<value-of select="$designId"/>', which the non-conforming work cited by that NonConformance was built to. A remedial design responds to a finding made after its predecessor was built; this looks like a reference on an original design.</assert>
    </rule>
  </pattern>

  <pattern id="NC-ref-disposition-warnings">
    <rule context="*[local-name() = 'nonConformanceRef'][starts-with(@xlink:href, '#')]" role="warning">
      <let name="target" value="(//*[@gml:id = substring(current()/@xlink:href, 2)])[1]"/>
      <let name="code" value="substring-after(string($target/*[local-name() = 'disposition']/@codeSpace), '#')"/>
      <assert test="not($code = ('accept_as_is', 'reject'))">nonConformanceRef '<value-of select="@xlink:href"/>' cites a NonConformance whose disposition is '<value-of select="$code"/>', which does not call for a remedial design.</assert>
    </rule>
  </pattern>

  <pattern id="NC-disposition-needs-design">
    <rule context="*[local-name() = 'NonConformance'][@gml:id]" role="warning">
      <let name="id" value="string(@gml:id)"/>
      <let name="code" value="substring-after(string(*[local-name() = 'disposition']/@codeSpace), '#')"/>
      <assert test="not($code = ('repair', 'rework', 'replace', 'redesign')) or exists(//*[local-name() = 'nonConformanceRef'][@xlink:href = concat('#', $id)])">NonConformance '<value-of select="$id"/>' has disposition '<value-of select="$code"/>', but no design cites it through nonConformanceRef.</assert>
    </rule>
  </pattern>
</schema>
