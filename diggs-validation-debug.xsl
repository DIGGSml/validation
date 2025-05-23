<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    exclude-result-prefixes="xs map diggs gml err">
    
    
    <!-- ************ Master stylesheet for DIGGS context validation ************** 
         *            DIGGS files should be schema valid before running context   *
         *            validation                                                  *
         **************************************************************************
     -->
    
    <!-- Output method -->
    <xsl:output method="xml" indent="yes"/>
    
    <!-- Parameters -->
    <xsl:param name="whiteListFile" select="'https://diggsml.org/def/validation/whiteList.xml'"/>
    
    <!-- Debug: Check parameter value -->
    <xsl:variable name="debugWhiteListParam">
        <debug>
            <message>Parameter whiteListFile value: <xsl:value-of select="$whiteListFile"/></message>
        </debug>
    </xsl:variable>
    
    <!-- Debug: Test doc-available function -->
    <xsl:variable name="debugDocAvailable">
        <debug>
            <message>Testing doc-available for: <xsl:value-of select="$whiteListFile"/></message>
            <result>
                <xsl:choose>
                    <xsl:when test="doc-available($whiteListFile)">
                        <xsl:text>doc-available returned TRUE</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>doc-available returned FALSE</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </result>
        </debug>
    </xsl:variable>
    
    <!-- Debug: Test doc function with error handling -->
    <xsl:variable name="debugDocFunction">
        <debug>
            <message>Testing doc() function for: <xsl:value-of select="$whiteListFile"/></message>
            <result>
                <xsl:try>
                    <xsl:variable name="testDoc" select="doc($whiteListFile)"/>
                    <xsl:choose>
                        <xsl:when test="exists($testDoc)">
                            <xsl:text>doc() returned a document node</xsl:text>
                            <xsl:text> - Root element: </xsl:text>
                            <xsl:value-of select="name($testDoc/*)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>doc() returned empty sequence</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:catch>
                        <xsl:text>ERROR in doc() function: </xsl:text>
                        <xsl:value-of select="$err:code"/>
                        <xsl:text> - </xsl:text>
                        <xsl:value-of select="$err:description"/>
                    </xsl:catch>
                </xsl:try>
            </result>
        </debug>
    </xsl:variable>
    
    <!-- Global variables with enhanced debugging -->
    <xsl:variable name="whiteList">
        <xsl:choose>
            <xsl:when test="doc-available($whiteListFile)">
                <xsl:sequence select="doc($whiteListFile)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- Debug: Check final whiteList result -->
    <xsl:variable name="debugWhiteListResult">
        <debug>
            <message>Final whiteList variable check:</message>
            <result>
                <xsl:choose>
                    <xsl:when test="exists($whiteList)">
                        <xsl:text>whiteList contains data - Root element: </xsl:text>
                        <xsl:value-of select="name($whiteList/*)"/>
                        <xsl:text>, Node count: </xsl:text>
                        <xsl:value-of select="count($whiteList//*)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>whiteList is EMPTY</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </result>
        </debug>
    </xsl:variable>
    
    <!-- Store the original XML document -->
    <xsl:variable name="originalXml" select="/"/>
    
    <!-- Convert the XML to a string -->
    <xsl:variable name="originalXmlString">
        <xsl:value-of select="serialize($originalXml)"/>
    </xsl:variable>
    
    <!-- Import function module first -->
    <xsl:import href="modules/diggs-functions.xsl"/>
    
    <!-- Initialize whitelist (this call is preserved but not actually needed) 
    <xsl:variable name="_" select="diggs:setWhiteList($whiteList)"/> -->
    
    <!-- Import DIGGS structure check module -->
    <xsl:import href="modules/diggs-check.xsl"/>
    
    <!-- Import schema validation module -->
    <xsl:import href="modules/schema-check.xsl"/>
    
    <!-- Import codeType-validation module -->
    <xsl:import href="modules/codeType-validation.xsl"/>
    
    <!-- Import dictionary-validation module -->
    <xsl:import href="modules/dictionary-validation.xsl"/>
 
    <!-- Import schematron-validation module 
    <xsl:import href="modules/schematron-validation.xsl"/>
    -->
 
    <!-- Import other modules here once they are developed -->
    
    <!-- Main template -->
    <xsl:template match="/">
        <validationReport>
            <timestamp><xsl:value-of select="current-dateTime()"/></timestamp>
            <fileName><xsl:value-of select="tokenize(document-uri(/), '/')[last()]"/></fileName>
            <originalXml><xsl:value-of select="$originalXmlString"/></originalXml>
            
            <!-- Include all debug information -->
            <debugSection>
                <xsl:copy-of select="$debugWhiteListParam"/>
                <xsl:copy-of select="$debugDocAvailable"/>
                <xsl:copy-of select="$debugDocFunction"/>
                <xsl:copy-of select="$debugWhiteListResult"/>
                
                <!-- Additional SaxonJS-specific debug info -->
                <debug>
                    <message>SaxonJS Environment Check:</message>
                    <result>
                        <xsl:text>XSLT Version: </xsl:text>
                        <xsl:value-of select="system-property('xsl:version')"/>
                        <xsl:text>, Vendor: </xsl:text>
                        <xsl:value-of select="system-property('xsl:vendor')"/>
                        <xsl:text>, Product: </xsl:text>
                        <xsl:value-of select="system-property('xsl:product-name')"/>
                        <xsl:text>, Version: </xsl:text>
                        <xsl:value-of select="system-property('xsl:product-version')"/>
                    </result>
                </debug>
            </debugSection>
            
            <!-- Run DIGGS structure check first -->
            <xsl:variable name="diggsCheckResults">
                <xsl:call-template name="diggsCheck"/>
            </xsl:variable>
            
            <!-- Include DIGGS structure check results in the report -->
            <xsl:copy-of select="$diggsCheckResults"/>
            
            <!-- Only proceed with other validations if DIGGS structure check allows continuation -->
            <xsl:if test="$diggsCheckResults/messageSet/continuable = 'true'">
                
                <!-- Run schema validation, passing the whitelist -->
                <xsl:variable name="schemaCheckResults">
                    <xsl:call-template name="schemaCheck">
                        <xsl:with-param name="whiteList" select="$whiteList"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <!-- Include schema validation results in the report -->
                <xsl:copy-of select="$schemaCheckResults"/>
                
                <!-- Only proceed with other validations if schema validation allows continuation -->
                <xsl:if test="$schemaCheckResults/messageSet/continuable = 'true'">
                    
                    <!-- Run codeType validation 
                    <xsl:call-template name="codeTypeValidation"></xsl:call-template>
                    -->
                    <!-- Run  dictionary validation, passing the whitelist -->
                    <xsl:call-template name="dictionaryValidation">
                        <xsl:with-param name="whiteList" select="$whiteList"/>
                    </xsl:call-template>
                    
                    <!-- Run schematron validation, passing the whitelist
                    <xsl:call-template name="schematronValidation">
                        <xsl:with-param name="whiteList" select="$whiteList"/>
                    </xsl:call-template>
                     -->
                   
                    <!-- Other validation modules will be called here as they are developed -->
                </xsl:if>
            </xsl:if>
        </validationReport>
    </xsl:template>
</xsl:stylesheet>