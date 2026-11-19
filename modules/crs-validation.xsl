<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    exclude-result-prefixes="xs map diggs gml">
    
    <!-- Main template for CRS validation -->
    <xsl:template name="crsValidation">
        <xsl:param name="sourceDocument" select="/"/>
        <xsl:param name="whiteList" as="node()?"/>
        
        <messageSet>
            <step>CRS Validation</step>
            
            <!-- Select all elements that contain srsName attribute -->
            <xsl:variable name="elementsWithSrsName" select="
                $sourceDocument//*[@*[local-name() = 'srsName']]"/>
            
            <!-- Check each distinct srsName value once; a value is typically repeated on many elements -->
            <xsl:variable name="crsResults" as="map(xs:string, item()*)" select="
                map:merge(
                    for $value in distinct-values($elementsWithSrsName/@*[local-name() = 'srsName'] ! string(.))
                    return map:entry($value, diggs:isCRS($value, $sourceDocument, $whiteList))
                )"/>
            
            <!-- Report on each element with srsName attribute, in document order -->
            <xsl:for-each select="$elementsWithSrsName">
                <xsl:call-template name="validateSrsName">
                    <xsl:with-param name="element" select="."/>
                    <xsl:with-param name="crsResults" select="$crsResults"/>
                </xsl:call-template>
            </xsl:for-each>
        </messageSet>
    </xsl:template>
    
    <!-- Template to validate individual srsName attribute -->
    <xsl:template name="validateSrsName">
        <xsl:param name="element"/>
        <xsl:param name="crsResults" as="map(xs:string, item()*)"/>
        
        <xsl:variable name="elementName" select="local-name($element)"/>
        <xsl:variable name="elementPath" select="diggs:get-path($element)"/>
        <xsl:variable name="srsNameValue" select="$element/@*[local-name() = 'srsName']"/>
        
        <!-- Result of the isCRS check for this srsName value -->
        <xsl:variable name="crsResult" select="map:get($crsResults, string($srsNameValue))"/>
        
        <!-- Extract CRS definition and message from the result -->
        <xsl:variable name="crsDefinition" select="$crsResult[1]"/>
        <xsl:variable name="messageText" select="$crsResult[2]"/>
        
        <!-- Check if validation failed (empty CRS definition or non-empty message) -->
        <xsl:choose>
            <xsl:when test="not($crsDefinition/*) or $messageText != ''">
                <!-- Validation failed - write ERROR message -->
                <xsl:variable name="errorMessage">
                    <xsl:choose>
                        <xsl:when test="$messageText != ''">
                            <!-- Use the message returned by isCRS function -->
                            <xsl:value-of select="$messageText"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- Fallback message if no specific message returned -->
                            <xsl:value-of select="concat('The srsName attribute value &quot;', $srsNameValue, '&quot; in &lt;', $elementName, '&gt; does not reference a valid CRS definition.')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:sequence select="
                    diggs:createMessage(
                    'ERROR',
                    $elementPath,
                    $errorMessage,
                    $element
                    )"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Validation passed - no message needed (pass silently) -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>