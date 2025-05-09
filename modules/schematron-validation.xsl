<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    exclude-result-prefixes="xs map diggs gml sch err">
    
    <!-- Main template for schematron validation with parameter declaration -->
    <xsl:template name="schematronValidation">
        <!-- Declare the whitelist parameter - keeping same parameters as codeSpace for consistency -->
        <xsl:param name="whiteList" as="node()*"/>
        
        <messageSet>
            <step>Schematron Validation</step>
            
            <!-- Load the schematron file -->
            <xsl:variable name="schematronURL" select="'modules/diggs_validation_rules.sch'"/>
            <xsl:variable name="schematronFile" select="diggs:getResource($schematronURL, document-uri(/))"/>
            
            <xsl:choose>
                <xsl:when test="empty($schematronFile)">
                    <xsl:sequence select="diggs:createMessage(
                        'ERROR',
                        '/',
                        concat('Failed to load the Schematron rules file (', $schematronURL ,').'),
                        /
                        )"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Process specific validation rules - using direct element targeting for clarity -->
                    <xsl:message>Starting targeted validation for known rules...</xsl:message>
                    
                    <!-- Rule 1: Validate hammerEfficiency -->
                    <xsl:call-template name="validateHammerEfficiency"/>
                    
                    <!-- Rule 2: Validate casingOutsideDiameter -->
                    <xsl:call-template name="validateCasingDiameter"/>
                    
                    <!-- More validation templates can be added here as needed -->
                </xsl:otherwise>
            </xsl:choose>
        </messageSet>
    </xsl:template>
    
    <!-- Template to validate hammerEfficiency -->
    <xsl:template name="validateHammerEfficiency">
        <xsl:message>Checking hammerEfficiency elements...</xsl:message>
        
        <!-- Find all hammerEfficiency elements directly -->
        <xsl:for-each select="//*[local-name() = 'hammerEfficiency']">
            <xsl:variable name="nodeValue" select="normalize-space(string(.))"/>
            <xsl:variable name="numValue" select="number($nodeValue)"/>
            <xsl:variable name="elementPath" select="diggs:get-path(.)"/>
            
            <xsl:message>Validating hammerEfficiency at <xsl:value-of select="$elementPath"/> with value: <xsl:value-of select="$nodeValue"/></xsl:message>
            
            <!-- Test if value is between 0 and 100 -->
            <xsl:if test="not($numValue &gt;= 0 and $numValue &lt;= 100)">
                <xsl:message>VALIDATION FAILURE: hammerEfficiency must be between 0 and 100 (value: <xsl:value-of select="$nodeValue"/>)</xsl:message>
                
                <!-- Use diggs:createMessage for the error -->
                <xsl:sequence select="diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    concat('Energy efficiency must be between 0 and 100. Current value: ', $nodeValue),
                    .
                    )"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Template to validate casingOutsideDiameter -->
    <xsl:template name="validateCasingDiameter">
        <xsl:message>Checking casingOutsideDiameter elements...</xsl:message>
        
        <!-- Find all casingOutsideDiameter elements directly -->
        <xsl:for-each select="//*[local-name() = 'casingOutsideDiameter']">
            <xsl:variable name="nodeValue" select="normalize-space(string(.))"/>
            <xsl:variable name="numValue" select="number($nodeValue)"/>
            <xsl:variable name="elementPath" select="diggs:get-path(.)"/>
            
            <xsl:message>Validating casingOutsideDiameter at <xsl:value-of select="$elementPath"/> with value: <xsl:value-of select="$nodeValue"/></xsl:message>
            
            <!-- Test if value is positive -->
            <xsl:if test="not($numValue &gt; 0)">
                <xsl:message>VALIDATION FAILURE: casingOutsideDiameter must be positive (value: <xsl:value-of select="$nodeValue"/>)</xsl:message>
                
                <!-- Use diggs:createMessage for the error -->
                <xsl:sequence select="diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    concat('casingOutsideDiameter must be positive. Current value: ', $nodeValue),
                    .
                    )"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Additional validation templates can be added here -->
    <!-- For example, to validate plunge, totalMeasuredDepth, etc. -->
</xsl:stylesheet>