<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    exclude-result-prefixes="xs map diggs gml">
    
    <!-- Main template for geometry validation -->
    <xsl:template name="geometryValidation">
        <xsl:param name="sourceDocument" select="/"/>
        
        <messageSet>
            <step>Geometry Validation</step>
            
            <!-- Select all geometry elements by local-name -->
            <xsl:variable name="geometryElements" select="
                $sourceDocument//*[local-name() = 'LinearExtent' or 
                local-name() = 'MultiPointLocation' or 
                local-name() = 'MultiCurve' or 
                local-name() = 'Solid' or 
                local-name() = 'PointLocation' or 
                local-name() = 'PlanarObservationRepresentation' or 
                local-name() = 'PlanarSurface' or 
                local-name() = 'MultiPlanarSurface' or 
                local-name() = 'RectifiedGrid']"/>
            
            <!-- Process each geometry element -->
            <xsl:for-each select="$geometryElements">
                <xsl:call-template name="validateGeometryElement">
                    <xsl:with-param name="element" select="."/>
                </xsl:call-template>
            </xsl:for-each>
        </messageSet>
    </xsl:template>
    
    <!-- Template to validate individual geometry element -->
    <xsl:template name="validateGeometryElement">
        <xsl:param name="element"/>
        
        <xsl:variable name="elementName" select="local-name($element)"/>
        <xsl:variable name="elementPath" select="diggs:get-path($element)"/>
        
        <!-- Test 1: the geometry object carries both srsName and srsDimension -->
        <xsl:variable name="elementHasBoth" select="
            exists($element/@srsName) and exists($element/@srsDimension)"/>
        
        <xsl:choose>
            <xsl:when test="$elementHasBoth">
                <!-- Test 2: every component carrying srsName or srsDimension must repeat the top-level values -->
                <xsl:variable name="conflictingComponents" select="
                    $element//*[(@srsName and @srsName != $element/@srsName) or 
                                (@srsDimension and @srsDimension != $element/@srsDimension)]"/>
                
                <xsl:if test="exists($conflictingComponents)">
                    <xsl:sequence select="
                        diggs:createMessage(
                        'WARNING',
                        $elementPath,
                        concat('Geometry object &lt;', $elementName, '&gt; contains component geometry (&lt;', 
                        string-join(distinct-values($conflictingComponents ! local-name(.)), '&gt;, &lt;'), 
                        '&gt;) whose srsName or srsDimension differs from the values on the object (srsName &quot;', 
                        $element/@srsName, '&quot;, srsDimension &quot;', $element/@srsDimension, 
                        '&quot;). Best practice is for all components of a geometry object to use the same CRS.'),
                        $element
                        )"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- A component of a geometry object that carries both attributes passes silently -->
                <xsl:variable name="ancestorHasBoth" select="
                    some $ancestor in $element/ancestor::* satisfies 
                    (exists($ancestor/@srsName) and exists($ancestor/@srsDimension))"/>
                
                <xsl:choose>
                    <xsl:when test="$ancestorHasBoth">
                        <!-- Pass silently - no message -->
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="childHasBoth" select="
                            some $child in $element//* satisfies 
                            (exists($child/@srsName) and exists($child/@srsDimension))"/>
                        
                        <xsl:choose>
                            <xsl:when test="$childHasBoth">
                                <!-- Test 1 fails but the attributes are found on components -->
                                <xsl:sequence select="
                                    diggs:createMessage(
                                    'WARNING',
                                    $elementPath,
                                    concat('Geometry object &lt;', $elementName, '&gt; should carry both srsName and srsDimension itself, but they are found only in child elements. Best practice is to place srsName and srsDimension on the top-level geometry object.'),
                                    $element
                                    )"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="
                                    diggs:createMessage(
                                    'ERROR',
                                    $elementPath,
                                    concat('Geometry object &lt;', $elementName, '&gt; is missing required srsName and srsDimension attributes. Both attributes must be present together in the object itself, or in a parent geometry object.'),
                                    $element
                                    )"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>