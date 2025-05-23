<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    exclude-result-prefixes="xs diggs gml err">
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:import href="modules//diggs-functions.xsl"/>
    
    <!-- Match the root element directly -->
    <xsl:template match="/">
        <messageSet>
            <step>CodeType Validation - Direct Test</step>
            
            <!-- Test evaluate here directly in root template -->
            <directTest>
                <manualCount><xsl:value-of select="count(//*[local-name() = 'rolePerformed'])"/></manualCount>
                
                <evaluateTest>
                    <xsl:try>
                        <xsl:variable name="selectedElements" as="element()*">
                            <xsl:evaluate context-item="/" xpath="'//*[local-name() = ''rolePerformed'']'"/>
                        </xsl:variable>
                        <count><xsl:value-of select="count($selectedElements)"/></count>
                        <xsl:for-each select="$selectedElements[position() le 3]">
                            <element><xsl:value-of select="."/></element>
                        </xsl:for-each>
                        <xsl:catch>
                            <e><xsl:value-of select="$err:description"/></e>
                        </xsl:catch>
                    </xsl:try>
                </evaluateTest>
            </directTest>
            
            <!-- Now test with the resource file -->
            <resourceTest>
                <xsl:variable name="resourceUrl" select="'https://diggsml.org/def/validation/definedCodeTypes.xml'"/>
                <xsl:variable name="codeTypeResource" select="diggs:getResource($resourceUrl, base-uri(/))"/>
                
                <xsl:choose>
                    <xsl:when test="empty($codeTypeResource)">
                        <error>Resource file could not be loaded</error>
                    </xsl:when>
                    <xsl:otherwise>
                        <success>Resource loaded</success>
                        
                        <!-- Test with first codeType from resource -->
                        <xsl:variable name="firstCodeType" select="$codeTypeResource//codeType[1]"/>
                        <xsl:variable name="firstXPath" select="string($firstCodeType/xpath)"/>
                        
                        <firstXPathTest>
                            <xpath><xsl:value-of select="$firstXPath"/></xpath>
                            <xsl:try>
                                <xsl:variable name="elements" as="element()*">
                                    <xsl:evaluate context-item="/" xpath="$firstXPath"/>
                                </xsl:variable>
                                <count><xsl:value-of select="count($elements)"/></count>
                                <xsl:catch>
                                    <e><xsl:value-of select="$err:description"/></e>
                                </xsl:catch>
                            </xsl:try>
                        </firstXPathTest>
                    </xsl:otherwise>
                </xsl:choose>
            </resourceTest>
        </messageSet>
    </xsl:template>
    
</xsl:stylesheet>