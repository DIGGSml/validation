<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:diggs="http://diggsml.org/schema-dev"
    xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:dr="http://diggsml.org/schemas/3/deprecation"
    xmlns:ns="http://temp/ns"
    exclude-result-prefixes="xs map diggs gml dr ns">

    <!-- Deprecation validation.

         Reads the DIGGS deprecation registry (diggs-schema/deprecated/DeprecationRegistry.xml, generated from
         the schema) and reports every place in the instance where something deprecated or removed is used:

           deprecated  ->  WARNING   still valid; says since which release and what to use instead
           removed     ->  ERROR     no longer in the schema; says in which release it went and what replaced it

         An entry flagged exact="false" is matched by element names only and a live use of the same names
         shares the path, so the message says the match may be a valid use.

         The registry is read from the first of deprecationRegistryUri that is available. Override the
         parameter to use a local copy or another release. If none can be read the module reports one INFO
         message and checks nothing. Entries with no instance XPath (types) are never evaluated. -->

    <xsl:param name="deprecationRegistryUri" as="xs:string*" select="(
        'https://diggsml.org/schema-dev/deprecated/DeprecationRegistry.xml',
        'https://raw.githubusercontent.com/DIGGSml/schema-dev/3.1-dev/deprecated/DeprecationRegistry.xml')"/>

    <xsl:template name="deprecationValidation">
        <xsl:param name="sourceDocument" select="/"/>
        <xsl:param name="registryUris" as="xs:string*" select="$deprecationRegistryUri"/>

        <messageSet>
            <step>Deprecation Validation</step>

            <xsl:variable name="registryUri" select="($registryUris[doc-available(.)])[1]" as="xs:string?"/>

            <xsl:choose>
                <xsl:when test="empty($registryUri)">
                    <xsl:sequence select="diggs:createMessage(
                        'INFO',
                        '/Diggs[1]',
                        'Deprecation check skipped: the deprecation registry could not be read from any of: ' ||
                        string-join($registryUris, ', ') || '.',
                        ())"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="registry" select="doc($registryUri)/dr:DeprecationRegistry"/>

                    <!-- the registry binds the prefixes its XPaths use -->
                    <xsl:variable name="namespaceNode">
                        <ns:context>
                            <xsl:for-each select="$registry/dr:namespace">
                                <xsl:namespace name="{@prefix}" select="string(@uri)"/>
                            </xsl:for-each>
                        </ns:context>
                    </xsl:variable>

                    <xsl:for-each select="$registry/dr:entry[normalize-space(dr:instanceXPath) != '']">
                        <xsl:variable name="entry" select="."/>
                        <xsl:variable name="matches" as="node()*">
                            <xsl:try>
                                <xsl:evaluate xpath="string($entry/dr:instanceXPath)"
                                    context-item="$sourceDocument"
                                    namespace-context="$namespaceNode/*"
                                    as="node()*"/>
                                <xsl:catch>
                                    <xsl:sequence select="()"/>
                                </xsl:catch>
                            </xsl:try>
                        </xsl:variable>
                        <xsl:for-each select="$matches">
                            <xsl:sequence select="diggs:createMessage(
                                if ($entry/@status = 'removed') then 'ERROR' else 'WARNING',
                                diggs:deprecationPath(.),
                                diggs:deprecationText($entry),
                                .[. instance of element()])"/>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </messageSet>
    </xsl:template>

    <!-- path of the matched node; get-path covers elements, so an attribute adds its own step -->
    <xsl:function name="diggs:deprecationPath" as="xs:string">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node instance of attribute())
            then concat(diggs:get-path($node/parent::*), '/@', local-name($node))
            else diggs:get-path($node)"/>
    </xsl:function>

    <xsl:function name="diggs:deprecationText" as="xs:string">
        <xsl:param name="entry" as="element(dr:entry)"/>

        <xsl:variable name="kindLabel" select="
            if ($entry/@kind = ('element', 'branchRef')) then 'Element'
            else if ($entry/@kind = 'type') then 'Type'
            else if ($entry/@kind = 'attribute') then 'Attribute'
            else if ($entry/@kind = 'enumValue') then 'Value'
            else 'Content branch'"/>
        <xsl:variable name="what" select="concat($kindLabel, ' ', $entry/@name,
            if ($entry/@host != '') then concat(' in ', $entry/@host) else '')"/>

        <!-- what to use instead: the replacement, its note, or both -->
        <xsl:variable name="note" select="string($entry/dr:note)"/>
        <xsl:variable name="instead" select="
            if ($entry/@replacedBy and $note != '') then concat($entry/@replacedBy, ' (', $note, ')')
            else if ($entry/@replacedBy) then string($entry/@replacedBy)
            else $note"/>

        <xsl:variable name="exactness" select="
            if ($entry/dr:instanceXPath/@exact = 'false')
            then ' This match is by name only and may be a valid use of the same name; check its context.'
            else ''"/>

        <xsl:sequence select="
            if ($entry/@status = 'removed') then
                concat($what, ' was removed in ', $entry/@removedIn,
                    if ($entry/@replacedBy) then concat('; use ', $instead, '.')
                    else concat('. ', $note))
            else
                concat($what, ' is deprecated since ', $entry/@since,
                    if ($instead != '') then concat('; use ', $instead, '.') else '.',
                    $exactness)"/>
    </xsl:function>

</xsl:stylesheet>
