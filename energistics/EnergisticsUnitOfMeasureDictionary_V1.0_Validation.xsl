<xsl:transform
	xmlns:tns="http://www.energistics.org/energyml/data/uomv1"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.energistics.org/energyml/data/uomv1"
	version="2.0">

  <xsl:output 
	method     = "xml" 
	media-type = "text/xml"
	encoding   = "utf-8"
        name       = "xml"
	indent     = "yes" />

<!-- =====================================================================
	Test the validity of XML files related to "Energistics Unit of Measure Dictionary V1.0".
	These dictionary and integer code tests are outlined in the Energistics Maintaining a Unit Dictonary document.
	Any "mapsFrom" values in the mapping sets will be tested to insure that they are unique within that set.
	Any "mapsTo" values in the mapping sets will be tested to insure that the referenced item is in the dictionary.
	All input files should first be validated against their XML schema.

	The input can be all in one uomAggregate file (default) or in multiple files (requires parameter input).
	The following node sets will be tested if present in an input file:
		uomDictionary	(which MUST contain the following)
			unitDimensionSet
			quantityClassSet
			unitSet
			referenceSet
			prefixSet
		integerCodeSet
		classMappingSet
		unitMappingSet
	Note that integer codes and mappings are compared against the dictonary so its inclusion is important.
	The output file will contain the uomAggregate root element and each set root.
	A parameter value of DETAIL for the "output-mode" parameter will include the node set details in the output stream.
	ERROR elements will be interspersed with the output if problems are found.

VERSION HISTORY:
	March 2014	First Release
===================================================================== -->


<!-- Input parameters. -->

	<!-- The path/name to the uomDictionary nodeset - if not within the main input. -->
	<xsl:param name="dictionaryFile"></xsl:param>

	<!-- The path/name to the integerCodeSet nodeset - if not in the main input. -->
	<xsl:param name="integerFile"></xsl:param>

	<!-- The path/name to the classMappingSet nodeset - if not in the main input. -->
	<xsl:param name="classMapFile"></xsl:param>

	<!-- The path/name to the unitMappingSet nodeset - if not in the main input. -->
	<xsl:param name="unitMapFile"></xsl:param>

	<!-- The output mode. The default is to output all input nodes. -->
	<!-- A value of NO-DETAIL will supress the detail nodes from within each set. -->
	<!-- A value of DETAIL will output the detail nodes from each input set. -->
	<xsl:param name="output-mode">NO-DETAIL</xsl:param>


<!-- Global variables. -->

	<!-- The name of the schema file. -->
	<xsl:variable name="schemaFile">EnergisticsUnitOfMeasureDictionary_v1.0.xsd</xsl:variable>

	<!-- Value which indicates some sort of error. This flag works in both strings and numbers. -->
	<xsl:variable name="ERROR">-9.999999E-99</xsl:variable>

	<!-- The amount to indent. -->
	<xsl:variable name="indent"><xsl:text>	</xsl:text></xsl:variable>

	<!-- The namespace of the XML to be generated. -->
	<xsl:variable name="nameSpace">http://www.energistics.org/energyml/data/uomv1</xsl:variable>

	<!-- The maximum detectable difference in precision on this machine using double precision math in XSL. -->
	<xsl:variable name="maxDiff" as="xsd:double">1E-15</xsl:variable>

	<!-- The value of PI (for the purpose of calculating derived factors on this machine). -->
	<xsl:variable name="PI">3.1415926535897932384626433832795</xsl:variable>

	<!-- The fixed up path to the dictionary file. -->
	<xsl:variable name="dictionaryPath">
		<xsl:call-template name="fixPath">
			<xsl:with-param name="path"><xsl:value-of select="$dictionaryFile"/></xsl:with-param>
		</xsl:call-template>
	</xsl:variable>

	<!-- The fixed up path to the integer file. -->
	<xsl:variable name="integerPath">
		<xsl:call-template name="fixPath">
			<xsl:with-param name="path"><xsl:value-of select="$integerFile"/></xsl:with-param>
		</xsl:call-template>
	</xsl:variable>

	<!-- The fixed up path to the class mapping file. -->
	<xsl:variable name="classMapPath">
		<xsl:call-template name="fixPath">
			<xsl:with-param name="path"><xsl:value-of select="$classMapFile"/></xsl:with-param>
		</xsl:call-template>
	</xsl:variable>

	<!-- The fixed up path to the unit mapping file. -->
	<xsl:variable name="unitMapPath">
		<xsl:call-template name="fixPath">
			<xsl:with-param name="path"><xsl:value-of select="$unitMapFile"/></xsl:with-param>
		</xsl:call-template>
	</xsl:variable>


	<!-- Dictionary node set. -->
	<xsl:variable name="dictionaryNodeSet">
		<xsl:choose>
			<xsl:when test="$dictionaryPath!=''">
				<xsl:copy-of select="document($dictionaryPath)//tns:uomDictionary"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select=".//tns:uomDictionary"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<!-- Integer Code node set. -->
	<xsl:variable name="integerNodeSet">
		<xsl:choose>
			<xsl:when test="$integerPath!=''">
				<xsl:copy-of select="document($integerPath)//tns:integerCodeSet"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select=".//tns:integerCodeSet"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<!-- Class Mapping node set. -->
	<xsl:variable name="classMapNodeSet">
		<xsl:choose>
			<xsl:when test="$classMapPath!=''">
				<xsl:copy-of select="document($classMapPath)//tns:classMappingSet"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select=".//tns:classMappingSet"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<!-- Unit Mapping node set. -->
	<xsl:variable name="unitMapNodeSet">
		<xsl:choose>
			<xsl:when test="$unitMapPath!=''">
				<xsl:copy-of select="document($unitMapPath)//tns:unitMappingSet"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select=".//tns:unitMappingSet"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>


	<!-- Dimension node set. -->
	<xsl:variable name="dimensionNodeSet" select="$dictionaryNodeSet"/>

	<!-- Quantity Class node set. -->
	<xsl:variable name="classNodeSet" select="$dictionaryNodeSet"/>

	<!-- Unit Symbol node set. -->
	<xsl:variable name="unitNodeSet" select="$dictionaryNodeSet"/>

	<!-- Reference node set. -->
	<xsl:variable name="referenceNodeSet" select="$dictionaryNodeSet"/>

	<!-- Prefix node set. -->
	<xsl:variable name="prefixNodeSet" select="$dictionaryNodeSet"/>


	<!-- Unit components. -->
	<xsl:variable name="underlyingNodeSet" select="$unitNodeSet//tns:unit[contains(./tns:category,'atom') or ./tns:category='prefixed']"/>


<xsl:template match="/">

<!-- ========================================================================================================= -->
<!-- AGGREGATE ROOT -->
<xsl:call-template name="linebreak"/>
<xsl:element name="uomAggregate" namespace="{$nameSpace}">
	<xsl:attribute name="schemaLocation" namespace="http://www.w3.org/2001/XMLSchema-instance">
		<xsl:value-of select="$nameSpace"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="$schemaFile"/>
	</xsl:attribute>
	<!-- ========================================================================================================= -->
	<!-- DICTIONARY ROOT -->
	<xsl:for-each select="$dictionaryNodeSet//tns:uomDictionary ">
		<!-- Copy the parent node for context. -->
		<xsl:call-template name="linebreak-indent"/>
		<xsl:copy>
			<xsl:copy-of select="./attribute::*"/>
			<xsl:call-template name="linebreak-2indent"/>
			<xsl:copy-of select="./child::*[name()='title']"/>
			<xsl:if test="$output-mode='DETAIL'">
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy-of select="./child::*[name()='originator']"/>
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy-of select="./child::*[name()='description']"/>
			</xsl:if>

			<!-- ========================================================================================================= -->
			<!-- DIMENSION SET -->
			<xsl:for-each select="$dimensionNodeSet//tns:unitDimensionSet ">
				<!-- Copy the parent node for context. -->
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy>
					<xsl:copy-of select="./attribute::*"/>
					<!-- Now process each class. -->
					<xsl:for-each select="./tns:unitDimension">
						<!-- ========== -->
						<!-- Copy the node as context for any error messages. -->
						<xsl:if test="$output-mode='DETAIL'">
							<xsl:call-template name="linebreak-3indent"/>
							<xsl:copy-of select="."/>
						</xsl:if>
						<!-- ========== -->
						<!-- Variables. -->
						<xsl:variable name="name"><xsl:value-of select="./tns:name"/></xsl:variable>
						<xsl:variable name="dimension"><xsl:value-of select="./tns:dimension"/></xsl:variable>
						<xsl:variable name="base"><xsl:value-of select="./tns:baseForConversion"/></xsl:variable>
						<xsl:variable name="canon"><xsl:value-of select="./tns:canonicalUnit"/></xsl:variable>
						<!-- ========== -->
						<!-- Test that the name is unique. -->
						<xsl:variable name="countname"><xsl:value-of select="count($dimensionNodeSet//tns:unitDimension[./tns:name=$name])"/></xsl:variable>
						<xsl:if test="($countname!=1)">
							<xsl:variable name="errorText">
								<xsl:text>DIMENSION: The name="</xsl:text>
								<xsl:value-of select="$name"/>
								<xsl:text>" is not unique.  count="</xsl:text>
								<xsl:value-of select="$countname"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the dimension is unique. -->
						<xsl:variable name="countDim"><xsl:value-of select="count($dimensionNodeSet//tns:unitDimension[./tns:dimension=$dimension])"/></xsl:variable>
						<xsl:if test="($countDim!=1)">
							<xsl:variable name="errorText">
								<xsl:text>DIMENSION: For name="</xsl:text>
								<xsl:value-of select="$name"/>
								<xsl:text>", the dimension="</xsl:text>
								<xsl:value-of select="$dimension"/>
								<xsl:text>" is not unique.  count="</xsl:text>
								<xsl:value-of select="$countDim"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the base is unique. -->
						<xsl:variable name="countBase"><xsl:value-of select="count($dimensionNodeSet//tns:unitDimension[./tns:baseForConversion=$base])"/></xsl:variable>
						<xsl:if test="($countBase!=1)">
							<xsl:variable name="errorText">
								<xsl:text>DIMENSION: For name="</xsl:text>
								<xsl:value-of select="$name"/>
								<xsl:text>", the baseForConversion="</xsl:text>
								<xsl:value-of select="$base"/>
								<xsl:text>" is not unique.  count="</xsl:text>
								<xsl:value-of select="$countBase"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the canonical unit matches the canonical unit derived from the base. -->
						<xsl:variable name="generatedCanonical">
							<xsl:call-template name="generateCanonical">
								<xsl:with-param name="symbol" select="$base"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:if test="$generatedCanonical!=$canon and $base!='0'">
							<xsl:variable name="errorText">
								<xsl:text>DIMENSION: For name="</xsl:text>
								<xsl:value-of select="$name"/>
								<xsl:text>", the canonical-unit="</xsl:text>
								<xsl:value-of select="$canon"/>
								<xsl:text>" does not match the derived-canonical-unit="</xsl:text>
								<xsl:value-of select="$generatedCanonical"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the base unit is from the SI system. -->
						<xsl:if test="$unitNodeSet//tns:unit[./tns:symbol=$base]/tns:isSI!='true'">
							<xsl:variable name="errorText">
								<xsl:text>DIMENSION: For name="</xsl:text>
								<xsl:value-of select="$name"/>
								<xsl:text>", the baseForConversion="</xsl:text>
								<xsl:value-of select="$base"/>
								<xsl:text>" is not flagged as SI.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- The dimension base must be referenced by a base, an alternative base or an underlying definition. -->
						<xsl:if test="$base!='0' and 
							      not($classNodeSet//tns:quantityClass[./tns:baseForConversion=$base or ./tns:alternativeBase=$base]) and
							      not($unitNodeSet//tns:unit[./tns:underlyingDef=$base])">
							<xsl:variable name="errorText">
								<xsl:text>DIMENSION: For name="</xsl:text>
								<xsl:value-of select="$name"/>
								<xsl:text>", the baseForConversion="</xsl:text>
								<xsl:value-of select="$base"/>
								<xsl:text>" is not a class baseForConversion, a class alternativeBase or the underlying definition of a class baseUnit.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the dimension is referenced by a class. -->
						<xsl:if test="not($classNodeSet//tns:quantityClass[./tns:dimension=$dimension])">
							<xsl:variable name="errorText">
								<xsl:text>DIMENSION: For name="</xsl:text>
								<xsl:value-of select="$name"/>
								<xsl:text>", the dimension="</xsl:text>
								<xsl:value-of select="$dimension"/>
								<xsl:text>" is not the dimension of any quantityClass.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
					</xsl:for-each>
					<xsl:call-template name="linebreak-2indent"/>
				</xsl:copy>
			</xsl:for-each>

			<!-- ========================================================================================================= -->
			<!-- CLASS SET -->
			<xsl:for-each select="$classNodeSet//tns:quantityClassSet">
				<!-- Copy the parent node for context. -->
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy>
					<xsl:copy-of select="./attribute::*"/>
					<!-- Now process each class. -->
					<xsl:for-each select="./tns:quantityClass">
						<!-- ========== -->
						<!-- Copy the node as context for any error messages. -->
						<xsl:if test="$output-mode='DETAIL'">
							<xsl:call-template name="linebreak-3indent"/>
							<xsl:copy-of select="."/>
						</xsl:if>
						<!-- ========== -->
						<!-- Variables. -->
						<xsl:variable name="class"><xsl:value-of select="./tns:name"/></xsl:variable>
						<xsl:variable name="dimension"><xsl:value-of select="./tns:dimension"/></xsl:variable>
						<xsl:variable name="represent"><xsl:value-of select="./tns:representativeUom"/></xsl:variable>
						<xsl:variable name="base"><xsl:value-of select="./tns:baseForConversion"/></xsl:variable>
						<xsl:variable name="alternative"><xsl:value-of select="./tns:alternativeBase"/></xsl:variable>
						<xsl:variable name="comment"><xsl:value-of select="./tns:description"/></xsl:variable>
						<xsl:variable name="baseUnder"><xsl:value-of select="$unitNodeSet//tns:unit[./tns:symbol=$base]/tns:underlyingDef"/></xsl:variable>
						<!-- ========== -->
						<!-- Test that the class name is unique. -->
						<xsl:variable name="codeCount">
							<xsl:value-of select="count($classNodeSet//tns:quantityClass[./tns:name=$class])"/>
						</xsl:variable>
						<xsl:if test="$codeCount>1">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: The name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>" is not unique. count="</xsl:text>
								<xsl:value-of select="$codeCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the base is unique within the class set. -->
						<xsl:variable name="countBse"><xsl:value-of select="count($classNodeSet//tns:quantityClass[./tns:baseForConversion=$base])"/></xsl:variable>
						<xsl:if test="($countBse!=1)">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", the baseForConversion="</xsl:text>
								<xsl:value-of select="$base"/>
								<xsl:text>" is not unique.  count="</xsl:text>
								<xsl:value-of select="$countBse"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that an equivalent of the base exists in the dimension set. -->
						<xsl:if test="$dimension!='none' and $alternative=''">
							<xsl:variable name="countBase" ><xsl:value-of select="count($dimensionNodeSet//tns:unitDimension[./tns:baseForConversion=$base])"/></xsl:variable>
							<xsl:variable name="countUnder"><xsl:value-of select="count($dimensionNodeSet//tns:unitDimension[./tns:baseForConversion=$baseUnder])"/></xsl:variable>
							<xsl:if test="$countBase=0 and $countUnder=0">
								<xsl:variable name="errorText">
									<xsl:text>CLASS: For name="</xsl:text>
									<xsl:value-of select="$class"/>
									<xsl:text>" whose dimension is not "none" and which does not have an alternativeBase, neither the baseForConversion="</xsl:text>
									<xsl:value-of select="$base"/>
									<xsl:text>" nor the underlyingDef="</xsl:text>
									<xsl:value-of select="$baseUnder"/>
									<xsl:text>" are dimensional bases.</xsl:text>
								</xsl:variable>
								<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
							</xsl:if>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the dimension exists in the dimension set. -->
						<xsl:variable name="countDim">
							<xsl:value-of select="count($dimensionNodeSet//tns:unitDimension[./tns:dimension=$dimension])"/>
						</xsl:variable>
						<xsl:if test="$countDim=0">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", the dimension="</xsl:text>
								<xsl:value-of select="$dimension"/>
								<xsl:text>" is not in the dimension set.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the alternative base exists in the dimension set. -->
						<xsl:variable name="countAlt"><xsl:value-of select="count($dimensionNodeSet//tns:unitDimension[./tns:baseForConversion=$alternative])"/></xsl:variable>
						<xsl:if test="($countAlt=0 and $alternative!='')">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", the alternativeBase="</xsl:text>
								<xsl:value-of select="$alternative"/>
								<xsl:text>" does not exist in the dimension set.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- An alternative base must not match the base. -->
						<xsl:if test="$base=$alternative">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", the alternativeBase="</xsl:text>
								<xsl:value-of select="$alternative"/>
								<xsl:text>" equals the baseForConversion="</xsl:text>
								<xsl:value-of select="$base"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the alternative base is not specified unless there are multiple classes with the same dimension. -->
						<xsl:if test="$alternative!='' and count($classNodeSet//tns:quantityClass[./tns:dimension=$dimension])=1">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", the alternativeBase="</xsl:text>
								<xsl:value-of select="$alternative"/>
								<xsl:text>" was specified but no other classes have dimension="</xsl:text>
								<xsl:value-of select="$dimension"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- If an alternative base is specified then the underlying definition of the base must match the dimensional base. -->
						<xsl:if test="$alternative!=''">
							<xsl:variable name="dimBase">
								<xsl:value-of select="$dimensionNodeSet//tns:unitDimension[./tns:dimension=$dimension]/tns:baseForConversion"/>
							</xsl:variable>
							<xsl:variable name="baseUnderlying">
								<xsl:value-of select="$unitNodeSet//tns:unit[./tns:symbol=$base]/tns:underlyingDef"/>
							</xsl:variable>
							<xsl:if test="$dimBase!=$baseUnderlying">
								<xsl:variable name="errorText">
									<xsl:text>CLASS: For name="</xsl:text>
									<xsl:value-of select="$class"/>
									<xsl:text>", an alternative base was specified but the underlyingDef="</xsl:text>
									<xsl:value-of select="$baseUnderlying"/>
									<xsl:text>" of baseForConversion="</xsl:text>
									<xsl:value-of select="$base"/>
									<xsl:text>" does not match the dimensional base=</xsl:text>
									<xsl:value-of select="$dimBase"/>
									<xsl:text>".</xsl:text>
								</xsl:variable>
								<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
							</xsl:if>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that at least one member has the alternate base. -->
						<xsl:if test="$alternative!=''">
							<xsl:variable name="usedAlt">
								<xsl:for-each select="./tns:memberUnit">
									<xsl:variable name="unt"><xsl:value-of select="."/></xsl:variable>
									<xsl:variable name="bse"><xsl:value-of select="$unitNodeSet//tns:unit[./tns:symbol=$unt]/tns:baseUnit"/></xsl:variable>
									<xsl:if test="$bse=$alternative or ($bse='' and $unt=$alternative)">
										<xsl:text>YES</xsl:text>
									</xsl:if>
								</xsl:for-each>
							</xsl:variable>
							<xsl:if test="not(contains($usedAlt,'YES'))">
								<xsl:variable name="errorText">
									<xsl:text>CLASS: For name="</xsl:text>
									<xsl:value-of select="$class"/>
									<xsl:text>", the alternativeBase="</xsl:text>
									<xsl:value-of select="$alternative"/>
									<xsl:text>" is not the baseForConversion of a memberUnit.</xsl:text>
								</xsl:variable>
								<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
							</xsl:if>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the base unit is from the SI system. -->
						<xsl:if test="$unitNodeSet//tns:unit[./tns:symbol=$base]/tns:isSI!='true'">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", the baseForConversion="</xsl:text>
								<xsl:value-of select="$base"/>
								<xsl:text>" is not flagged as SI.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the alternative base unit is from the SI system. -->
						<xsl:if test="$alternative!='' and $unitNodeSet//tns:unit[./tns:symbol=$alternative]/tns:isSI!='true'">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", the alternativeBase="</xsl:text>
								<xsl:value-of select="$alternative"/>
								<xsl:text>" is not flagged as SI.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that at least one member is SI. -->
						<xsl:variable name="hasSI">
							<xsl:for-each select="./tns:memberUnit">
								<xsl:variable name="unt"><xsl:value-of select="."/></xsl:variable>
								<xsl:if test="$unitNodeSet//tns:unit[./tns:symbol=$unt]/tns:isSI='true'">
									<xsl:text>YES</xsl:text>
								</xsl:if>
							</xsl:for-each>
						</xsl:variable>
						<xsl:if test="not(contains($hasSI,'YES'))">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", no memberUnit is flagged as SI.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that a class has at least one member. -->
						<xsl:variable name="countMem"><xsl:value-of select="count(./tns:memberUnit)"/></xsl:variable>
						<xsl:if test="($countMem=0)">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: The name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>" has no member units.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the base unit is consistent for all members of this class. -->
						<xsl:for-each select="./tns:memberUnit">
							<xsl:variable name="unt"><xsl:value-of select="."/></xsl:variable>
							<xsl:variable name="count"><xsl:value-of select="count($unitNodeSet//tns:unit[./tns:symbol=$unt])"/></xsl:variable>
							<xsl:if test="count($unitNodeSet//tns:unit[./tns:symbol=$unt])!=0">
								<!-- This unit actually exists. -->
								<xsl:variable name="bse"><xsl:value-of select="$unitNodeSet//tns:unit[./tns:symbol=$unt]/tns:baseUnit"/></xsl:variable>
								<xsl:if test="($bse!='' and ($base!=$bse and $alternative!=$bse)) or 
									      ($bse=''  and ($base!=$unt and $alternative!=$unt))">
									<xsl:variable name="errorText">
										<xsl:text>CLASS: For name="</xsl:text>
										<xsl:value-of select="$class"/>
										<xsl:text>", the memberUnit="</xsl:text>
										<xsl:value-of select="$unt"/>
										<xsl:text>", is not the class base and not the alternative base and its base does not match the class base."</xsl:text>
									</xsl:variable>
									<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
								</xsl:if>
							</xsl:if>
						</xsl:for-each>
						<!-- ========== -->
						<!-- A class of dimension "none" must not have an alternative base. -->
						<xsl:if test="$dimension='none' and $alternative!=''">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>" its dimension is "none" but it has an alternative base.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the dimension is the same for all members of this class. -->
						<xsl:for-each select="./tns:memberUnit">
							<xsl:variable name="unt"><xsl:value-of select="."/></xsl:variable>
							<xsl:variable name="dim"><xsl:value-of select="$unitNodeSet//tns:unit[./tns:symbol=$unt]/tns:dimension"/></xsl:variable>
							<xsl:if test="$dim!=$dimension">
								<xsl:variable name="errorText">
									<xsl:text>CLASS: For name="</xsl:text>
									<xsl:value-of select="$class"/>
									<xsl:text>", the dimension="</xsl:text>
									<xsl:value-of select="$dimension"/>
									<xsl:text>" does not match the dimension of memberUnit="</xsl:text>
									<xsl:value-of select="$unt"/>
									<xsl:text>" whose dimension="</xsl:text>
									<xsl:value-of select="$dim"/>
									<xsl:text>".</xsl:text>
								</xsl:variable>
								<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
							</xsl:if>
						</xsl:for-each>
						<!-- ========== -->
						<!-- Test that the base (or alternative) unit is a member of this class. -->
						<xsl:variable name="nodeCount">
							<xsl:value-of select="count(./tns:memberUnit[.=$base or .=$alternative])"/>
						</xsl:variable>
						<xsl:if test="$nodeCount=0">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", either the baseForConversion="</xsl:text>
								<xsl:value-of select="$base"/>
								<xsl:text>" or alternativeBase="</xsl:text>
								<xsl:value-of select="$alternative"/>
								<xsl:text>" is not a member of the class.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the base unit exists. -->
						<xsl:if test="not($unitNodeSet//tns:unit[tns:symbol=$base])">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", the baseForConversion="</xsl:text>
								<xsl:value-of select="$base"/>
								<xsl:text>" does not exist.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the alternative base unit exists. -->
						<xsl:if test="$alternative!='' and not($unitNodeSet//tns:unit[tns:symbol=$alternative])">
							<xsl:variable name="errorText">
								<xsl:text>CLASS: For name="</xsl:text>
								<xsl:value-of select="$class"/>
								<xsl:text>", the alternativeBase="</xsl:text>
								<xsl:value-of select="$alternative"/>
								<xsl:text>" does not exist.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that each member unit exists. -->
						<xsl:for-each select="./tns:memberUnit">
							<xsl:variable name="unt"><xsl:value-of select="."/></xsl:variable>
							<xsl:variable name="count"><xsl:value-of select="count($unitNodeSet//tns:unit[./tns:symbol=$unt])"/></xsl:variable>
							<xsl:if test="count($unitNodeSet//tns:unit[./tns:symbol=$unt])=0">
								<xsl:variable name="errorText">
									<xsl:text>CLASS: For name="</xsl:text>
									<xsl:value-of select="$class"/>
									<xsl:text>", the memberUnit="</xsl:text>
									<xsl:value-of select="$unt"/>
								<xsl:text>" does not exist.</xsl:text>
								</xsl:variable>
								<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
							</xsl:if>
						</xsl:for-each>
					</xsl:for-each>
					<xsl:call-template name="linebreak-2indent"/>
				</xsl:copy>
			</xsl:for-each>


			<!-- ========================================================================================================= -->
			<!-- UNIT SET -->
			<xsl:for-each select="$unitNodeSet//tns:unitSet">
				<!-- Copy the parent node for context. -->
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy>
					<xsl:copy-of select="./attribute::*"/>
					<!-- ========== -->
					<!-- Now process each unit. -->
					<xsl:for-each select="./tns:unit">
						<!-- ========== -->
						<!-- Copy the node as context for any error messages. -->
						<xsl:if test="$output-mode='DETAIL'">
							<xsl:call-template name="linebreak-3indent"/>
							<xsl:copy-of select="."/>
						</xsl:if>
						<!-- ========== -->
						<!-- Variables. -->
						<xsl:variable name="symbol"><xsl:value-of select="./tns:symbol"/></xsl:variable>
						<xsl:variable name="name"><xsl:value-of select="./tns:name"/></xsl:variable>
						<xsl:variable name="base"><xsl:value-of select="./tns:baseUnit"/></xsl:variable>
						<xsl:variable name="isSI"><xsl:value-of select="./tns:isSI"/></xsl:variable>
						<xsl:variable name="reference"><xsl:value-of select="./tns:conversionRef"/></xsl:variable>
						<xsl:variable name="exact"><xsl:value-of select="./tns:isExact"/></xsl:variable>
						<xsl:variable name="category"><xsl:value-of select="./tns:category"/></xsl:variable>
						<xsl:variable name="dimension"><xsl:value-of select="./tns:dimension"/></xsl:variable>
						<xsl:variable name="description"><xsl:value-of select="./tns:description"/></xsl:variable>
						<xsl:variable name="underlying"><xsl:value-of select="./tns:underlyingDef"/></xsl:variable>
						<xsl:variable name="A"><xsl:value-of select="./tns:A"/></xsl:variable>
						<xsl:variable name="D"><xsl:value-of select="./tns:D"/></xsl:variable>
						<xsl:variable name="B">
							<xsl:call-template name="substitute-PI">
								<xsl:with-param name="value" select="./tns:B"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:variable name="C">
							<xsl:call-template name="substitute-PI">
								<xsl:with-param name="value" select="./tns:C"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:variable name="fact" as="xsd:double">
							<xsl:choose>
								<xsl:when test="$base=''">1</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$B div $C"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="isSimple">
							<xsl:choose>
								<xsl:when test="not(contains($symbol,'.')) and
										not(contains($symbol,'/')) and
										not(contains($symbol,'(')) and
										not(contains($symbol,' '))">true</xsl:when>
								<xsl:otherwise>false</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- ========== -->
						<!-- Insure that the unit name is unique. -->
						<xsl:variable name="nameCount">
							<xsl:value-of select="count($unitNodeSet//tns:unit[./tns:name=$name])"/>
						</xsl:variable>
						<xsl:if test="$nameCount!=1">
							<xsl:variable name="errorText">
								<xsl:text>UNIT: For symbol="</xsl:text>
								<xsl:value-of select="$symbol"/>
								<xsl:text>", the name="</xsl:text>
								<xsl:value-of select="$name"/>
								<xsl:text>" is not unique. count="</xsl:text>
								<xsl:value-of select="$nameCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the unit symbol is unique. -->
						<xsl:variable name="symbolCount">
							<xsl:value-of select="count($unitNodeSet//tns:unit[./tns:symbol=$symbol])"/>
						</xsl:variable>
						<xsl:if test="$symbolCount!=1">
							<xsl:variable name="errorText">
								<xsl:text>UNIT: The symbol="</xsl:text>
								<xsl:value-of select="$symbol"/>
								<xsl:text>" is not unique. count="</xsl:text>
								<xsl:value-of select="$symbolCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the conversionRef value exists. -->
						<xsl:variable name="refCount">
							<xsl:value-of select="count($referenceNodeSet//tns:referenceSet/tns:reference[./tns:ID=$reference])"/>
						</xsl:variable>
						<xsl:if test="$refCount!=1 and $reference!=''">
							<xsl:variable name="errorText">
								<xsl:text>UNIT: For symbol="</xsl:text>
								<xsl:value-of select="$symbol"/>
								<xsl:text>", the conversionRef="</xsl:text>
								<xsl:value-of select="$reference"/>
								<xsl:text>" does not exist. count="</xsl:text>
								<xsl:value-of select="$refCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test that the dimension derived from the symbol matches the dimension assigned to the unit. -->
						<xsl:variable name="generatedDimension">
							<xsl:call-template name="generateDimension">
								<xsl:with-param name="symbol" select="$symbol"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:if test="$dimension != $generatedDimension">
							<xsl:variable name="errorText">
								<xsl:text>UNIT: For symbol="</xsl:text>
								<xsl:value-of select="$symbol"/>
								<xsl:text>" the derived-dimension="</xsl:text>
								<xsl:value-of select="$generatedDimension"/>
								<xsl:text>" does not match the dimension="</xsl:text>
								<xsl:value-of select="$dimension"/>
								<xsl:text>"assigned to the unit.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test for no class membership. -->
						<xsl:if test="count($classNodeSet//tns:quantityClassSet/tns:quantityClass[tns:memberUnit=$symbol])=0">
							<!-- Not a member. -->
							<xsl:if test="$base!='' or $classNodeSet//tns:quantityClass[./tns:baseForConversion=$symbol]/tns:alternativeBase=''">
								<xsl:variable name="errorText">
									<xsl:text>UNIT: The symbol="</xsl:text>
									<xsl:value-of select="$symbol"/>
									<xsl:text>" is not a memberUnit of any class but neither is it the base of a class with an alternativeBase.</xsl:text>
								</xsl:variable>
								<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
							</xsl:if>
						</xsl:if>
						<!-- ========== -->
						<!-- Test for the existance of atoms in a derived expression. -->
						<xsl:if test="$category='derived'">
							<xsl:call-template name="checkDerived">
								<xsl:with-param name="symbol" select="$symbol"/>
									<xsl:with-param name="mode">EXIST</xsl:with-param>
							</xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the base is an existing symbol. -->
						<xsl:if test="$base!=''">
							<xsl:if test="count($unitNodeSet//tns:unit/tns:symbol[.=$base])=0">
								<xsl:variable name="errorText">
									<xsl:text>UNIT: For symbol="</xsl:text>
									<xsl:value-of select="$symbol"/>
									<xsl:text>", the baseUnit="</xsl:text>
									<xsl:value-of select="$base"/>
									<xsl:text>" does not exist.</xsl:text>
								</xsl:variable>
								<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
							</xsl:if>
						</xsl:if>
						<!-- ========== -->
						<!-- A derived symbol flagged as SI must be composed of SI components. -->
						<xsl:if test="$category='derived' and $isSI='true'">
							<xsl:call-template name="checkDerived">
								<xsl:with-param name="symbol" select="$symbol"/>
								<xsl:with-param name="mode">SI</xsl:with-param>
							</xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- If any component has a dimension of "none" then the containing symbol must have a dimension of "none". -->
						<xsl:if test="$dimension!='none'">
							<xsl:variable name="none-dimension">
								<xsl:call-template name="checkDerived">
									<xsl:with-param name="symbol" select="$symbol"/>
									<xsl:with-param name="mode">NONE</xsl:with-param>
								</xsl:call-template>
							</xsl:variable>
							<xsl:if test="contains($none-dimension,'YES')">
								<xsl:variable name="errorText">
									<xsl:text>UNIT: The symbol="</xsl:text>
									<xsl:value-of select="$symbol"/>
									<xsl:text>" has dimension="none" but it contains dimensional components.</xsl:text>
								</xsl:variable>
								<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
							</xsl:if>
						</xsl:if>
						<!-- ========== -->
						<!-- A base of dimension "none" must not have an underlying definition. -->
						<xsl:if test="$base='' and $dimension='none' and $underlying!=''">
							<xsl:variable name="errorText">
								<xsl:text>UNIT: The symbol="</xsl:text>
								<xsl:value-of select="$symbol"/>
								<xsl:text>" with dimension="none" has an underlyingDef.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that base units do not contain prefixed components (except for kg). -->
						<xsl:if test="$isSI='true' and $base=''">
							<xsl:call-template name="checkDerived">
								<xsl:with-param name="symbol" select="$symbol"/>
								<xsl:with-param name="mode">BASE</xsl:with-param>
							</xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Symbol with category='atom' cannot be SI. -->
						<xsl:if test="$isSI='true' and $category='atom'">
							<xsl:variable name="errorText">
								<xsl:text>UNIT: The symbol="</xsl:text>
								<xsl:value-of select="$symbol"/>
								<xsl:text>" is flagged as SI but has a category='atom'.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure an SI unit, atom or prefixed-atom does not contain spaces. -->
						<xsl:if test="contains($symbol,' ') and ($isSI='true' or contains($category,'atom') or $category='prefixed')">
							<xsl:variable name="errorText">
								<xsl:text>UNIT: symbol="</xsl:text>
								<xsl:value-of select="$symbol"/>
								<xsl:text>" contains a space but is flagged as SI, atom or prefixed.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Test the assigmnent of the category. -->
						<xsl:variable name="possible-exponent">
							<xsl:call-template name="get-exponent">
								<xsl:with-param name="symbol" select="$symbol"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="$category!='derived' and ($isSimple='false' or $possible-exponent!=1)">
								<xsl:variable name="errorText">
									<xsl:text>UNIT: For symbol="</xsl:text>
									<xsl:value-of select="$symbol"/>
									<xsl:text>", the category="</xsl:text>
									<xsl:value-of select="$category"/>
									<xsl:text>" is not "derived" but the symbol contains a period,slash,paren,space or exponent.</xsl:text>
								</xsl:variable>
								<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
							</xsl:when>
							<xsl:when test="$category='derived' and $isSimple='true' and $possible-exponent=1">
								<xsl:variable name="errorText">
									<xsl:text>UNIT: For symbol="</xsl:text>
									<xsl:value-of select="$symbol"/>
									<xsl:text>", the category=</xsl:text>
									<xsl:value-of select="$category"/>
									<xsl:text>" but the symbol does NOT contain a period,slash,paren,space or exponent.</xsl:text>
								</xsl:variable>
								<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
							</xsl:when>
						</xsl:choose>
						<!-- ========== -->
						<!-- Test conversion factor. -->
						<!-- Do not test "point" temperatures and other stuff without a pure "B/C" factor. -->
						<xsl:if test="$A='0' and $D='0'">
							<!-- Test that the conversion factor matches the factor implied by the components in a derived expression. -->
							<xsl:if test="$category='derived'">
								<xsl:variable name="factTest" as="xsd:double" >
									<xsl:call-template name="derived-factor">
										<xsl:with-param name="symbol" select="$symbol"/>
									</xsl:call-template>
								</xsl:variable>
								<xsl:variable name="diff" as="xsd:double">
									<xsl:value-of select="abs($fact - $factTest) div $fact"/>
								</xsl:variable>
								<xsl:choose>
									<xsl:when test="$factTest=$ERROR">
										<xsl:variable name="errorText">
											<xsl:text>UNIT: For symbol="</xsl:text>
											<xsl:value-of select="$symbol"/>
											<xsl:text>", cannot derive a conversion because a component does not exist.</xsl:text>
										</xsl:variable>
										<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
									</xsl:when>
									<xsl:when test="$diff!=0  and  $diff > $maxDiff">
										<xsl:variable name="errorText">
											<xsl:text>UNIT: For symbol="</xsl:text>
											<xsl:value-of select="$symbol"/>
											<xsl:text>", the factor does not match the factor derived from its components. factor="</xsl:text>
											<xsl:value-of select="$fact"/>
											<xsl:text>", derived factor="</xsl:text>
											<xsl:value-of select="$factTest"/>
											<xsl:text>", abs(difference/factor)="</xsl:text>
											<xsl:value-of select="$diff"/>
											<xsl:text>".</xsl:text>
										</xsl:variable>
										<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
									</xsl:when>
								</xsl:choose>
							</xsl:if>
							<!-- Test that the conversion factor matches the factor implied by the components in the underlying definition. -->
							<xsl:if test="$underlying!='' and $base!=''">
								<xsl:variable as="xsd:double" name="factTest">
									<xsl:call-template name="derived-factor">
										<xsl:with-param name="symbol" select="$underlying"/>
									</xsl:call-template>
								</xsl:variable>
								<xsl:variable name="diff" as="xsd:double">
									<xsl:value-of select="abs($fact - $factTest) div $fact"/>
								</xsl:variable>
								<xsl:choose>
									<xsl:when test="$factTest=$ERROR">
										<xsl:variable name="errorText">
											<xsl:text>UNIT: For symbol="</xsl:text>
											<xsl:value-of select="$symbol"/>
											<xsl:text>", in underlyingDef="</xsl:text>
											<xsl:value-of select="$underlying"/>
											<xsl:text> cannot derive conversion because a component does not exist.</xsl:text>
										</xsl:variable>
										<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
									</xsl:when>
									<xsl:when test="$diff!=0  and  $diff > $maxDiff">
										<xsl:variable name="errorText">
											<xsl:text>UNIT: For symbol="</xsl:text>
											<xsl:value-of select="$symbol"/>
											<xsl:text>", the factor does not match the factor derived from the underlyingDef="</xsl:text>
											<xsl:value-of select="$underlying"/>
											<xsl:text>". factor="</xsl:text>
											<xsl:value-of select="$fact"/>
											<xsl:text>", derived factor="</xsl:text>
											<xsl:value-of select="$factTest"/>
											<xsl:text>", abs(difference/factor)="</xsl:text>
											<xsl:value-of select="$diff"/>
											<xsl:text>".</xsl:text>
										</xsl:variable>
										<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
									</xsl:when>
								</xsl:choose>
							</xsl:if>
						</xsl:if>
						<!-- ========== -->
						<!-- Test the prefixed symbols. -->
						<xsl:if test="$category='prefixed'">
							<xsl:variable name="u-pos">
								<!-- Find the position() of the the underlying atom in the underlyingNodeSet. -->
								<xsl:call-template name="findUnderlyingPos">
									<xsl:with-param name="symbol" select="$symbol"/>	
								</xsl:call-template>
							</xsl:variable>
							<xsl:choose>
								<xsl:when test="$u-pos=''">
									<!-- No underlying symbol was found. -->
									<xsl:variable name="errorText">
										<xsl:text>UNIT: The symbol="</xsl:text>
										<xsl:value-of select="$symbol"/>
										<xsl:text>" is flagged as prefixed but an underlying atom was found.</xsl:text>
									</xsl:variable>
									<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
								</xsl:when>
								<xsl:otherwise>
									<!-- Found the underlying symbol. -->
									<xsl:variable name="underlyingSymbolNodeSet">
										<xsl:value-of select="$underlyingNodeSet[position()=$u-pos]"/>
									</xsl:variable>
									<xsl:variable name="u-symbol">
										<xsl:value-of select="$underlyingNodeSet[position()=$u-pos]/tns:symbol"/>
									</xsl:variable>
									<xsl:variable name="u-name">
										<xsl:value-of select="$underlyingNodeSet[position()=$u-pos]/tns:name"/>
									</xsl:variable>
									<!-- Prefix information. -->
									<xsl:variable name="pre">
										<xsl:value-of select="substring($symbol,1,string-length($symbol)-string-length($u-symbol))"/>
									</xsl:variable>
									<xsl:variable name="prefixName">
										<xsl:value-of select="$prefixNodeSet//tns:prefix[tns:symbol=$pre]/tns:name"/>
									</xsl:variable>
									<xsl:variable name="commonPrefixName">
										<xsl:value-of select="$prefixNodeSet//tns:prefix[tns:symbol=$pre]/tns:commonName"/>
									</xsl:variable>
									<xsl:variable name="prefix-mult">
										<xsl:value-of select="$prefixNodeSet//tns:prefix[tns:symbol=$pre]/tns:multiplier"/>
									</xsl:variable>
								<!-- Test the name. -->
									<xsl:variable name="u-Name">
										<xsl:choose>
											<xsl:when test="$u-symbol='psi'">
												<!-- "psi" is special. We abbreviate in derived symbols to save space. -->
												<xsl:text>psi</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="$unitNodeSet//tns:unit[./tns:symbol=$u-symbol]/tns:name"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:variable name="testName">
										<xsl:call-template name="generate-name">
											<xsl:with-param name="symbol" select="$symbol"/>
										</xsl:call-template>
									</xsl:variable>
									<xsl:if test="$name!=$testName and $name!=concat($prefixName,$u-name)">
										<xsl:variable name="errorText">
											<xsl:text>UNIT: The symbol="</xsl:text>
											<xsl:value-of select="$symbol"/>
											<xsl:text>" is flagged as prefixed but the name="</xsl:text>
											<xsl:value-of select="$name"/>
											<xsl:text>"is not a concatentation of the prefix name="</xsl:text>
											<xsl:value-of select="$prefixName"/>
											<xsl:text>" and atom name="</xsl:text>
											<xsl:value-of select="$u-Name"/>
											<xsl:text>". The derived name=</xsl:text>
											<xsl:value-of select="$testName"/>
											<xsl:text>".</xsl:text>
										</xsl:variable>
										<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
									</xsl:if>
								<!-- Test the conversion info. -->
									<xsl:variable name="u-fact">
										<xsl:choose>
											<xsl:when test="not($underlyingNodeSet[position()=$u-pos]/tns:baseUnit)">
												<!-- This is a base unit. -->
												<xsl:text>1</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:variable name="u-B">
													<xsl:call-template name="substitute-PI">
														<xsl:with-param name="value" select="$underlyingNodeSet[position()=$u-pos]/tns:B"/>
													</xsl:call-template>
												</xsl:variable>
												<xsl:variable name="u-C">
													<xsl:call-template name="substitute-PI">
														<xsl:with-param name="value" select="$underlyingNodeSet[position()=$u-pos]/tns:C"/>
													</xsl:call-template>
												</xsl:variable>
												<xsl:value-of select="$u-B div $u-C"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:variable name="diff">
										<xsl:value-of select="abs(($prefix-mult * $u-fact) - $fact)"/>
									</xsl:variable>
									<xsl:variable name="diffRatio">
										<xsl:value-of select="abs($diff div $fact)"/>
									</xsl:variable>
									<xsl:if test="$diff!=0 and $diffRatio > $maxDiff">
										<xsl:variable name="errorText">
											<xsl:text>UNIT: The symbol="</xsl:text>
											<xsl:value-of select="$symbol"/>
											<xsl:text>", is flagged as prefixed but its factor does not match the factor derived from its underlying parts.</xsl:text>
											<xsl:text>" factor="</xsl:text>
											<xsl:value-of select="$fact"/>
											<xsl:text>",  prefix="</xsl:text>
											<xsl:value-of select="$pre"/>
											<xsl:text>", prefix-multiplier="</xsl:text>
											<xsl:value-of select="$prefix-mult"/>
											<xsl:text>", atom="</xsl:text>
											<xsl:value-of select="$u-symbol"/>
											<xsl:text>", atom-factor="</xsl:text>
											<xsl:value-of select="$u-fact"/>
											<xsl:text>", abs(difference/factor)=</xsl:text>
											<xsl:value-of select="$diffRatio"/>
											<xsl:text>".</xsl:text>
										</xsl:variable>
										<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
									</xsl:if>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
					</xsl:for-each>
					<xsl:call-template name="linebreak-2indent"/>
				</xsl:copy>
			</xsl:for-each>

			<!-- ========================================================================================================= -->
			<!-- CONVERSION REFERENCE  -->
			<xsl:for-each select=".//tns:referenceSet">
				<!-- Copy the referenceSet as context for any error messages. -->
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy>
					<xsl:copy-of select="./attribute::*"/>
					<xsl:for-each select=".//tns:reference">
						<xsl:variable name="id"><xsl:value-of select="./tns:ID"/></xsl:variable>
						<!-- ========== -->
						<!-- Copy the node as context for any error messages. -->
						<xsl:if test="$output-mode='DETAIL'">
							<xsl:call-template name="linebreak-3indent"/>
							<xsl:copy-of select="."/>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the referemce ID is unique. -->
						<xsl:variable name="nodeCount">
							<xsl:value-of select="count($unitNodeSet//tns:referenceSet/tns:reference[./tns:ID=$id])"/>
						</xsl:variable>
						<xsl:if test="$nodeCount>1">
							<xsl:variable name="errorText">
								<xsl:text>REFERENCE: The ID="</xsl:text>
								<xsl:value-of select="$id"/>
								<xsl:text>" is not unique. count="</xsl:text>
								<xsl:value-of select="$nodeCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
					</xsl:for-each>
					<xsl:call-template name="linebreak-2indent"/>
				</xsl:copy>
			</xsl:for-each>


			<!-- ========================================================================================================= -->
			<!-- PREFIX  -->
			<xsl:for-each select="$prefixNodeSet//tns:prefixSet">
				<!-- Copy the parent node for context. -->
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy>
					<xsl:copy-of select="./attribute::*"/>
					<!-- Now process each prefix -->
					<xsl:for-each select="./tns:prefix">
						<!-- ========== -->
						<!-- Copy the node as context for any error messages. -->
						<xsl:if test="$output-mode='DETAIL'">
							<xsl:call-template name="linebreak-3indent"/>
							<xsl:copy-of select="."/>
						</xsl:if>
						<!-- ========== -->
						<!-- Variables. -->
						<xsl:variable name="symbol"><xsl:value-of select="./tns:symbol"/></xsl:variable>
						<xsl:variable name="multiplier"><xsl:value-of select="./tns:multiplier"/></xsl:variable>
						<!-- ========== -->
						<!-- Insure that the prefix is unique. -->
						<xsl:variable name="nodeCount">
							<xsl:value-of select="count($prefixNodeSet//tns:prefix[./tns:symbol=$symbol])"/>
						</xsl:variable>
						<xsl:if test="$nodeCount!=1">
							<xsl:variable name="errorText">
								<xsl:text>PREFIX: The symbol="</xsl:text>
								<xsl:value-of select="$symbol"/>
								<xsl:text>" is not unique. count="</xsl:text>
								<xsl:value-of select="$nodeCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the multiplier is unique. -->
						<xsl:variable name="nodeCount">
							<xsl:value-of select="count($prefixNodeSet//tns:prefix[./tns:multiplier=$multiplier])"/>
						</xsl:variable>
						<xsl:if test="$nodeCount!=1">
							<xsl:variable name="errorText">
								<xsl:text>PREFIX: For symbol="</xsl:text>
								<xsl:value-of select="$symbol"/>
								<xsl:text>, the multiplier="</xsl:text>
								<xsl:value-of select="$multiplier"/>
								<xsl:text>" is not unique, count="</xsl:text>
								<xsl:value-of select="$nodeCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
					</xsl:for-each>
					<xsl:call-template name="linebreak-2indent"/>
				</xsl:copy>
			</xsl:for-each>

		<!-- END OF DICTIONARY -->
			<xsl:call-template name="linebreak-indent"/>
		</xsl:copy>
	</xsl:for-each>



	<!-- ========================================================================================================= -->
	<!-- INTEGER UNIT CODE  -->
	<xsl:for-each select="$integerNodeSet//tns:integerCodeSet ">
		<!-- Copy the parent node for context. -->
		<xsl:call-template name="linebreak-indent"/>
		<xsl:copy>
			<xsl:copy-of select="./attribute::*"/>
			<xsl:call-template name="linebreak-2indent"/>
			<xsl:copy-of select="./child::*[name()='title']"/>
			<xsl:if test="$output-mode='DETAIL'">
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy-of select="./child::*[name()='originator']"/>
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy-of select="./child::*[name()='description']"/>
			</xsl:if>

			<!-- ========================================================================================================= -->
			<!-- INTEGER CLASS CODE  -->
			<xsl:for-each select="$integerNodeSet//tns:classCodeSet">
				<!-- Copy the parent node for context. -->
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy>
					<xsl:copy-of select="./attribute::*"/>
					<!-- Now process each class code. -->
					<xsl:for-each select="./tns:classCode">
						<!-- ========== -->
						<!-- Copy the node as context for any error messages. -->
						<xsl:if test="$output-mode='DETAIL'">
							<xsl:call-template name="linebreak-3indent"/>
							<xsl:copy-of select="."/>
						</xsl:if>
						<!-- ========== -->
						<!-- Variables. -->
						<xsl:variable name="term"><xsl:value-of select="./tns:term"/></xsl:variable>
						<xsl:variable name="code"><xsl:value-of select="./tns:code"/></xsl:variable>
						<xsl:variable name="unit"><xsl:value-of select="./tns:unit"/></xsl:variable>
						<xsl:variable name="unitCode"><xsl:value-of select="./tns:unit/@code"/></xsl:variable>
						<xsl:variable name="deprecate"><xsl:value-of select="./tns:deprecated"/></xsl:variable>
						<!-- ========== -->
						<!-- Insure that the term is unique. -->
						<xsl:variable name="nodeCount">
							<xsl:value-of select="count($integerNodeSet//tns:classCode[./tns:term=$term])"/>
						</xsl:variable>
						<xsl:if test="$nodeCount!=1">
							<xsl:variable name="errorText">
								<xsl:text>INTEGER: The term="</xsl:text>
								<xsl:value-of select="$term"/>
								<xsl:text>" is not unique. count="</xsl:text>
								<xsl:value-of select="$nodeCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the code is unique. -->
						<xsl:variable name="nodeCount">
							<xsl:value-of select="count($integerNodeSet//tns:classCode[tns:code=$code])"/>
						</xsl:variable>
						<xsl:if test="$nodeCount!=1">
							<xsl:variable name="errorText">
								<xsl:text>INTEGER: For term="</xsl:text>
								<xsl:value-of select="$term"/>
								<xsl:text>, the code="</xsl:text>
								<xsl:value-of select="$code"/>
								<xsl:text>" is not unique. count="</xsl:text>
								<xsl:value-of select="$nodeCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the term matches a class name. -->
						<xsl:variable name="nodeCount">
							<xsl:value-of select="count($classNodeSet//tns:quantityClass[tns:name=$term])"/>
						</xsl:variable>
						<xsl:if test="$nodeCount!=1 and $deprecate=''">
							<xsl:variable name="errorText">
								<xsl:text>INTEGER: The term="</xsl:text>
								<xsl:value-of select="$term"/>
								<xsl:text>" does not match a class name but is not deprecated. count="</xsl:text>
								<xsl:value-of select="$nodeCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the unit matches a base, alternative or underlying. -->
						<xsl:variable name="classBase"><xsl:value-of select="$classNodeSet//tns:quantityClass[tns:name=$term]/tns:baseForConversion"/></xsl:variable>
						<xsl:variable name="alternate"><xsl:value-of select="$classNodeSet//tns:quantityClass[tns:name=$term]/tns:alternativeBase"/></xsl:variable>
						<xsl:variable name="underlying"><xsl:value-of select="$unitNodeSet//tns:unit[tns:symbol=$classBase]/tns:underlyingDef"/></xsl:variable>
						<xsl:if test="$unit!=$classBase and $unit!=$alternate and $unit!=$underlying and $deprecate=''">
							<xsl:variable name="errorText">
								<xsl:text>INTEGER: For term="</xsl:text>
								<xsl:value-of select="$term"/>
								<xsl:text>, the unit="</xsl:text>
								<xsl:value-of select="$unit"/>
								<xsl:text>" is not deprecated and the unit is not a class base, class alternatative base or underlying definition of a class base.</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the unit code exists. -->
						<xsl:variable name="nodeCount">
							<xsl:value-of select="count($integerNodeSet//tns:unitCode[tns:term=$unit and tns:code=$unitCode])"/>
						</xsl:variable>
						<xsl:if test="$nodeCount!=1">
							<xsl:variable name="errorText">
								<xsl:text>INTEGER: For term="</xsl:text>
								<xsl:value-of select="$term"/>
								<xsl:text> with the unit="</xsl:text>
								<xsl:value-of select="$unit"/>
								<xsl:text> and @code="</xsl:text>
								<xsl:value-of select="$code"/>
								<xsl:text>", the code does not exist. count="</xsl:text>
								<xsl:value-of select="$nodeCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
					</xsl:for-each>
					<xsl:call-template name="linebreak-2indent"/>
				</xsl:copy>
				<!-- ========================================================================================================= -->
				<!-- COMPARE CLASS SET TO INTEGER SET  -->
				<xsl:for-each select="$classNodeSet//tns:quantityClass">
					<!-- ========== -->
					<!-- Variables. -->
					<xsl:variable name="class"><xsl:value-of select="./tns:name"/></xsl:variable>
					<xsl:variable name="dimension"><xsl:value-of select="./tns:dimension"/></xsl:variable>
					<xsl:variable name="represent"><xsl:value-of select="./tns:representativeUom"/></xsl:variable>
					<xsl:variable name="base"><xsl:value-of select="./tns:baseForConversion"/></xsl:variable>
					<xsl:variable name="alternative"><xsl:value-of select="./tns:alternativeBase"/></xsl:variable>
					<xsl:variable name="comment"><xsl:value-of select="./tns:description"/></xsl:variable>
					<xsl:variable name="baseUnder"><xsl:value-of select="$unitNodeSet//tns:unit[./tns:symbol=$base]/tns:underlyingDef"/></xsl:variable>
					<!-- ========== -->
					<!-- Test that the class has an assisgned integer code. -->
					<xsl:if test="not($integerNodeSet//tns:classCode[./tns:term=$class])">
						<xsl:variable name="errorText">
							<xsl:text>INTEGER: The class name="</xsl:text>
							<xsl:value-of select="$class"/>
							<xsl:text>" does not have an assigned integer code.</xsl:text>
						</xsl:variable>
						<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
					</xsl:if>
				</xsl:for-each>
			</xsl:for-each>

			<!-- ========================================================================================================= -->
			<!-- INTEGER UNIT CODE  -->
			<xsl:for-each select="$integerNodeSet//tns:unitCodeSet">
				<!-- Copy the parent node for context. -->
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy>
					<xsl:copy-of select="./attribute::*"/>
					<!-- Now process each unit code. -->
					<xsl:for-each select="./tns:unitCode">
						<!-- ========== -->
						<!-- Copy the node as context for any error messages. -->
						<xsl:if test="$output-mode='DETAIL'">
							<xsl:call-template name="linebreak-3indent"/>
							<xsl:copy-of select="."/>
						</xsl:if>
						<!-- ========== -->
						<!-- Variables. -->
						<xsl:variable name="term"><xsl:value-of select="./tns:term"/></xsl:variable>
						<xsl:variable name="code"><xsl:value-of select="./tns:code"/></xsl:variable>
						<xsl:variable name="deprecated"><xsl:value-of select="./tns:deprecated"/></xsl:variable>
						<!-- ========== -->
						<!-- Insure that the code is unique. -->
						<xsl:variable name="nodeCount">
							<xsl:value-of select="count($integerNodeSet//tns:unitCode[tns:code=$code])"/>
						</xsl:variable>
						<xsl:if test="$nodeCount!=1">
							<xsl:variable name="errorText">
								<xsl:text>INTEGER: The unit-code="</xsl:text>
								<xsl:value-of select="$code"/>
								<xsl:text>" is not unique. count="</xsl:text>
								<xsl:value-of select="$nodeCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the term is unique. -->
						<xsl:variable name="termCount">
							<xsl:value-of select="count($integerNodeSet//tns:unitCode[tns:term=$term])"/>
						</xsl:variable>
						<xsl:if test="$termCount!=1">
							<xsl:variable name="errorText">
								<xsl:text>INTEGER: The unit-term="</xsl:text>
								<xsl:value-of select="$term"/>
								<xsl:text>" is not unique. count="</xsl:text>
								<xsl:value-of select="$termCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the term exists as a unit. -->
						<xsl:variable name="unitCount">
							<xsl:value-of select="count($unitNodeSet//tns:unit[tns:symbol=$term])"/>
						</xsl:variable>
						<xsl:if test="$unitCount!=1 and $deprecated=''">
							<xsl:variable name="errorText">
								<xsl:text>INTEGER: The unit-term="</xsl:text>
								<xsl:value-of select="$term"/>
								<xsl:text>" does not match a unit symbol. count="</xsl:text>
								<xsl:value-of select="$unitCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
						<!-- ========== -->
						<!-- Insure that the term is a class base or alternative base or underlying definition of base (dimensional base). -->
						<xsl:variable name="bseCount">
							<xsl:value-of select="count($classNodeSet//tns:quantityClass[tns:baseForConversion=$term or tns:alternativeBase=$term] or
										    $unitNodeSet//tns:unit[tns:underlyingDef=$term])"/>
						</xsl:variable>
						<xsl:if test="$bseCount=0 and $deprecated=''">
							<xsl:variable name="errorText">
								<xsl:text>INTEGER: The unit-term="</xsl:text>
								<xsl:value-of select="$term"/>
								<xsl:text>"  is not deprecated but is not a class base, class alterntive base of the underlying definition of a class base. bseCount="</xsl:text>
								<xsl:value-of select="$bseCount"/>
								<xsl:text>".</xsl:text>
							</xsl:variable>
							<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
						</xsl:if>
					</xsl:for-each>
				<xsl:call-template name="linebreak-2indent"/>
			</xsl:copy>
		</xsl:for-each>

	<!-- END OF INTEGER SET -->
			<xsl:call-template name="linebreak-indent"/>
		</xsl:copy>
	</xsl:for-each>



	<!-- ========================================================================================================= -->
	<!-- CLASS MAPPING SET(S) -->
	<xsl:for-each select="$classMapNodeSet//tns:classMappingSet ">
		<!-- Copy the parent node for context. -->
		<xsl:call-template name="linebreak-indent"/>
		<xsl:copy>
			<xsl:copy-of select="./attribute::*"/>
			<xsl:call-template name="linebreak-2indent"/>
			<xsl:copy-of select="./child::*[name()='title']"/>
			<xsl:if test="$output-mode='DETAIL'">
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy-of select="./child::*[name()='originator']"/>
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy-of select="./child::*[name()='description']"/>
			</xsl:if>
			<xsl:variable name="fromNodeSet" select="."/>
			<xsl:for-each select="./tns:classMap">
				<!-- Copy the node as context for any error messages. -->
				<xsl:if test="$output-mode='DETAIL'">
					<xsl:call-template name="linebreak-2indent"/>
					<xsl:copy-of select="."/>
				</xsl:if>
				<!-- ========== -->
				<!-- Variables. -->
				<xsl:variable name="mapsFrom"><xsl:value-of select="./tns:mapsFrom"/></xsl:variable>
				<xsl:variable name="mapsTo"  ><xsl:value-of select="./tns:mapsTo"/></xsl:variable>
				<!-- ========== -->
				<!-- Insure that the FROM term is unique. -->
				<xsl:variable name="nodeCount">
					<xsl:value-of select="count($fromNodeSet//tns:classMap[./tns:mapsFrom=$mapsFrom])"/>
				</xsl:variable>
				<xsl:if test="$nodeCount!=1">
					<xsl:variable name="errorText">
						<xsl:text>CLASS-MAP: The mapsFrom="</xsl:text>
						<xsl:value-of select="$mapsFrom"/>
						<xsl:text>" is not unique. count="</xsl:text>
						<xsl:value-of select="$nodeCount"/>
						<xsl:text>".</xsl:text>
					</xsl:variable>
					<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
				</xsl:if>
				<!-- ========== -->
				<!-- Insure that the term matches a class name. -->
				<xsl:variable name="nodeCount">
					<xsl:value-of select="count($classNodeSet//tns:quantityClass[tns:name=$mapsTo])"/>
				</xsl:variable>
				<xsl:if test="$nodeCount!=1 and $mapsTo!=''">
					<xsl:variable name="errorText">
						<xsl:text>CLASS-MAP: The mapsTo="</xsl:text>
						<xsl:value-of select="$mapsTo"/>
						<xsl:text>" does not match a class name. count="</xsl:text>
						<xsl:value-of select="$nodeCount"/>
						<xsl:text>".</xsl:text>
					</xsl:variable>
					<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
				</xsl:if>
			</xsl:for-each>
			<xsl:call-template name="linebreak-indent"/>
		</xsl:copy>
	<!-- END OF CLASS MAPPING SET(S) -->
	</xsl:for-each>



	<!-- ========================================================================================================= -->
	<!-- UNIT MAPPING SET(S) -->
	<xsl:for-each select="$unitMapNodeSet//tns:unitMappingSet ">
		<!-- Copy the parent node for context. -->
		<xsl:call-template name="linebreak-indent"/>
		<xsl:copy>
			<xsl:copy-of select="./attribute::*"/>
			<xsl:call-template name="linebreak-2indent"/>
			<xsl:copy-of select="./child::*[name()='title']"/>
			<xsl:if test="$output-mode='DETAIL'">
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy-of select="./child::*[name()='originator']"/>
				<xsl:call-template name="linebreak-2indent"/>
				<xsl:copy-of select="./child::*[name()='description']"/>
			</xsl:if>
			<xsl:variable name="fromNodeSet" select="."/>
			<xsl:for-each select="./tns:unitMap">
				<!-- Copy the node as context for any error messages. -->
				<xsl:if test="$output-mode='DETAIL'">
					<xsl:call-template name="linebreak-2indent"/>
					<xsl:copy-of select="."/>
				</xsl:if>
				<!-- ========== -->
				<!-- Variables. -->
				<xsl:variable name="mapsFrom"><xsl:value-of select="./tns:mapsFrom"/></xsl:variable>
				<xsl:variable name="mapsTo"  ><xsl:value-of select="./tns:mapsTo"/></xsl:variable>
				<!-- ========== -->
				<!-- Insure that the FROM term is unique. -->
				<xsl:variable name="nodeCount">
					<xsl:value-of select="count($fromNodeSet//tns:unitMap[./tns:mapsFrom=$mapsFrom])"/>
				</xsl:variable>
				<xsl:if test="$nodeCount!=1">
					<xsl:variable name="errorText">
						<xsl:text>UNIT-MAP: The mapsFrom="</xsl:text>
						<xsl:value-of select="$mapsFrom"/>
						<xsl:text>" is not unique. count="</xsl:text>
						<xsl:value-of select="$nodeCount"/>
						<xsl:text>".</xsl:text>
					</xsl:variable>
					<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
				</xsl:if>
				<!-- ========== -->
				<!-- Insure that the term matches a class name. -->
				<xsl:variable name="nodeCount">
					<xsl:value-of select="count($unitNodeSet//tns:unit[tns:symbol=$mapsTo])"/>
				</xsl:variable>
				<xsl:if test="$nodeCount!=1 and $mapsTo!=''">
					<xsl:variable name="errorText">
						<xsl:text>UNIT-MAP: The mapsTo="</xsl:text>
						<xsl:value-of select="$mapsTo"/>
						<xsl:text>" does not match a unit symbol. count="</xsl:text>
						<xsl:value-of select="$nodeCount"/>
						<xsl:text>".</xsl:text>
					</xsl:variable>
					<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
				</xsl:if>
			</xsl:for-each>
			<xsl:call-template name="linebreak-indent"/>
		</xsl:copy>
	<!-- END OF UNIT MAPPING SET(S) -->
	</xsl:for-each>




<!-- END OF AGGREGATE -->
	<xsl:call-template name="linebreak"/>
</xsl:element>

</xsl:template>


<!-- Generate a new line. -->
<xsl:template name="linebreak">
	<!-- Inserts a line break. -->
	<xsl:text>
</xsl:text>
</xsl:template>

<xsl:template name="linebreak-indent">
	<!-- Inserts a line break plus 1 indent. -->
	<xsl:call-template name="linebreak"/>
	<xsl:value-of select="$indent"/>
</xsl:template>

<xsl:template name="linebreak-2indent">
	<!-- Inserts a line break plus 2 indents. -->
	<xsl:call-template name="linebreak"/>
	<xsl:value-of select="$indent"/>
	<xsl:value-of select="$indent"/>
</xsl:template>

<xsl:template name="linebreak-3indent">
	<!-- Inserts a line break plus 3 indents. -->
	<xsl:call-template name="linebreak"/>
	<xsl:value-of select="$indent"/>
	<xsl:value-of select="$indent"/>
	<xsl:value-of select="$indent"/>
</xsl:template>


 
<!-- Template to create an ERROR element containing the provided text.-->
<xsl:template name="ERROR">
	<xsl:param name="text"/>
	<xsl:call-template name="linebreak"/>
	<xsl:element name="ERROR" namespace="{$nameSpace}">
		<xsl:value-of select="$text"/>
	</xsl:element>
</xsl:template>


<!-- Recursive template to find and test each underlying atom in a derived expression. -->
<!-- An atom contains letters and possibly a number power but no delimiters such as space, paren, slash, period. -->
<!-- See mode parameter for output options. -->
<!-- GLOBAL REQUIREMENT: $unitNodeSet  and related index variables -->
<!-- OUTPUT: XML element named ERROR if problems found.  -->
<xsl:template name="checkDerived">
	<xsl:param name="symbol"/>		<!-- The symbol for which a conversion is desired.-->
	<xsl:param name="begin">1</xsl:param>	<!-- The beginning position of the substring to test.-->
	<xsl:param name="end">1</xsl:param>	<!-- The ending position of the substring to test. Recursive until "end" points to a delimiter (e.g., space, paren, slash, period) or end of string. -->
	<xsl:param name="mode">exist</xsl:param> <!-- If mode="NONE" then will return YES for each component which has dimension='none'. -->
						 <!-- If mode="EXIST" then will issue an error element for each component which does not exist in the unit set. -->
						 <!-- If mode="SI" then will issue an error element for each component which which has isSI='false'. -->
						 <!-- If mode="BASE" then will issue an error element for each component which which has category='prefixed'. -->
	<xsl:choose>
		<xsl:when test="$begin > string-length($symbol)">
			<!-- We are finished. -->
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="charBeg"><xsl:value-of select="substring($symbol,$begin,1)"/></xsl:variable>
			<xsl:variable name="charEnd"><xsl:value-of select="substring($symbol,$end,1)"/></xsl:variable>
			<xsl:choose>
				<xsl:when test="$begin=$end and
						($charBeg='0' or
					 	 $charBeg='1' or
						 $charBeg='2' or
						 $charBeg='3' or
						 $charBeg='4' or
						 $charBeg='5' or
						 $charBeg='6' or
						 $charBeg='7' or
						 $charBeg='8' or
						 $charBeg='9' or
						 (contains(substring($symbol,$begin),' ') and
						  ($charEnd='E' or
						   $charEnd='-' or
						   $charEnd='.' )))">
					<!-- This appears to be part of a multiplier or is an exponent. -->
					<!-- Check next substring .-->
					<xsl:call-template name="checkDerived">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="begin" select="$end +1"/>
						<xsl:with-param name="end" select="$end +1"/>
						<xsl:with-param name="mode" select="$mode"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$charEnd=' '">
					<!-- This is the terminator of a multiplier. -->
					<!-- Check next substring. -->
					<xsl:call-template name="checkDerived">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="begin" select="$end +1"/>
						<xsl:with-param name="end" select="$end +1"/>
						<xsl:with-param name="mode" select="$mode"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$charEnd='(' or
						$charEnd=')' or
						$charEnd='/' or
						$charEnd='.' or
						$charEnd=''  or
						(not(substring($symbol,$begin,$end -$begin +1)='inH2O' or 
						     substring($symbol,$begin,$end -$begin +1)='cmH2O') and
						 not(contains(substring($symbol,$begin,$end -$begin),'[')) and
						 ($charEnd='1' or
						  $charEnd='2' or
						  $charEnd='3' or
						  $charEnd='4' or
						  $charEnd='5' or
						  $charEnd='6' or
						  $charEnd='7' or
						  $charEnd='8' or
						  $charEnd='9' or
						  $charEnd='0' ))">
					<!-- Terminator or end of string or beginning of exponent. -->
					<xsl:choose>
						<xsl:when test="$begin=$end">
							<!-- Nothing but a terminator. -->
							<!-- Check next substring. -->
							<xsl:call-template name="checkDerived">
								<xsl:with-param name="symbol" select="$symbol"/>
								<xsl:with-param name="begin" select="$end +1"/>
								<xsl:with-param name="end" select="$end +1"/>
								<xsl:with-param name="mode" select="$mode"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<!-- We have identified an atom. -->
							<xsl:variable name="atom"><xsl:value-of select="substring($symbol,$begin,$end -$begin)"/></xsl:variable>
							<xsl:variable name="atomSymbol"><xsl:value-of select="$unitNodeSet//tns:unit/tns:symbol[.=$atom]"/></xsl:variable>
							<xsl:variable name="category"><xsl:value-of select="$unitNodeSet//tns:unit[tns:symbol=$atom]/tns:category"/></xsl:variable>
							<xsl:choose>
								<xsl:when test="$atom='1'">
									<!-- This presumably is just the numerator, such as in "1/s". -->
								</xsl:when>
								<xsl:when test="$mode='NONE' and $unitNodeSet//tns:unit[tns:symbol=$atom]/tns:dimension='none'">
									<!-- Return knowledge that at least one component which is non-dimensional. -->
									<xsl:text>YES</xsl:text>
								</xsl:when>
								<xsl:when test="$mode='SI' and $unitNodeSet//tns:unit[tns:symbol=$atom]/tns:isSI='false'">
									<xsl:variable name="errorText">
										<xsl:text>UNIT: Within SI symbol="</xsl:text>
										<xsl:value-of select="$symbol"/>
										<xsl:text>", atom="</xsl:text>
										<xsl:value-of select="$atom"/>
										<xsl:text>" is not SI.</xsl:text>
									</xsl:variable>
									<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
								</xsl:when>
								<xsl:when test="$mode='EXIST' and $atomSymbol=''">
									<xsl:variable name="errorText">
										<xsl:text>UNIT: Within symbol="</xsl:text>
										<xsl:value-of select="$symbol"/>
										<xsl:text>", atom="</xsl:text>
										<xsl:value-of select="$atom"/>
										<xsl:text>" does not exist.</xsl:text>
									</xsl:variable>
									<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
								</xsl:when>
								<xsl:when test="$mode='BASE' and $category='prefixed' and $atom!='kg'">
									<xsl:variable name="errorText">
										<xsl:text>UNIT: Within BASE symbol="</xsl:text>
										<xsl:value-of select="$symbol"/>
										<xsl:text>", atom="</xsl:text>
										<xsl:value-of select="$atom"/>
										<xsl:text>" has category='prefixed".</xsl:text>
									</xsl:variable>
									<xsl:call-template name="ERROR"><xsl:with-param name="text" select="$errorText"/></xsl:call-template>
								</xsl:when>
							</xsl:choose>
							<xsl:if test="$charEnd!=''">
								<!-- Not end of string. -->
								<!-- Check next substring.-->
								<xsl:call-template name="checkDerived">
									<xsl:with-param name="symbol" select="$symbol"/>
									<xsl:with-param name="begin" select="$end +1"/>
									<xsl:with-param name="end" select="$end +1"/>
									<xsl:with-param name="mode" select="$mode"/>
								</xsl:call-template>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>	
				</xsl:when>
				<xsl:otherwise>
					<!-- Keep looking. -->
					<xsl:call-template name="checkDerived">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="begin" select="$begin"/>
						<xsl:with-param name="end" select="$end +1"/>
						<xsl:with-param name="mode" select="$mode"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- Recursive template to generate a long name from from the underlying component items. -->
<!-- An item may be an atom, a prefixed-atom, an atom to a power. -->
<!-- The name associated with each component will be concatenated with the cumulative name. -->
<!-- GLOBAL REQUIREMENT: $underlyingNodeSet
			 $prefixNodeSet
			 $unitNodeSet  -->
<!-- OUTPUT: XML element named ERROR if problems found.  -->
<xsl:template name="generate-name">
	<xsl:param name="symbol"/>		<!-- The derived-symbol to be parsed for its component items. -->
	<xsl:param name="pos">1</xsl:param>	<!-- The beginning position of the substring to test.-->
	<xsl:param name="name"/>
		<!-- The current cumulative name. -->
	<xsl:choose>
		<xsl:when test="$pos > string-length($symbol)">
			<!-- We are finished. -->
			<xsl:value-of select="$name"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="start">
				<!-- Find the starting position of the next item.-->
				<xsl:call-template name="next-comp">
					<xsl:with-param name="symbol" select="$symbol"/>
					<xsl:with-param name="pos" select="$pos"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$start=0">
					<!-- No more items found.-->
					<!-- We are finished. -->
					<xsl:value-of select="$name"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="end">
						<!-- Find the terminator of the next item.-->
						<xsl:call-template name="next-term">
							<xsl:with-param name="symbol" select="$symbol"/>
							<xsl:with-param name="start" select="$start"/>
							<xsl:with-param name="pos" select="$start"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:variable name="length">
						<xsl:choose>
							<xsl:when test="$end=0">
								<xsl:value-of select="string-length($symbol) -$start +1"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$end -$start"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- Find the terminator of the next item.-->
					<xsl:variable name="item">
						<xsl:value-of select="substring($symbol,$start,$length)"/>
					</xsl:variable>
					<xsl:variable name="isSI">
						<!-- Is the combination SI? -->
						<xsl:value-of select="$unitNodeSet//tns:unit[./tns:symbol=$item]/tns:isSI"/>
					</xsl:variable>
					<xsl:variable name="category">
						<!-- Category for the combination. -->
						<xsl:value-of select="$unitNodeSet//tns:unit[./tns:symbol=$item]/tns:category"/>
					</xsl:variable>
					<xsl:variable name="u-pos">
						<xsl:call-template name="findUnderlyingPos">
							<xsl:with-param name="symbol" select="$symbol"/>	
						</xsl:call-template>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$u-pos=''">
							<!-- No underlying symbol was found. -->
							<xsl:text>ERROR: unit=</xsl:text>
							<xsl:value-of select="$symbol"/>
							<xsl:text>, NO-UNDERLYING-UNIT-FOUND.</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<!-- Found the underlying symbol. -->
							<xsl:variable name="u-symbol">
								<xsl:value-of select="$underlyingNodeSet[position()=$u-pos]/tns:symbol"/>
							</xsl:variable>
							<xsl:variable name="pre">
								<xsl:value-of select="substring($symbol,1,string-length($symbol)-string-length($u-symbol))"/>
							</xsl:variable>
							<xsl:variable name="dimension">
								<xsl:value-of select="$underlyingNodeSet[position()=$u-pos]/tns:dimension"/>
							</xsl:variable>
							<xsl:variable name="exponent">
								<xsl:call-template name="get-exponent">
									<xsl:with-param name="symbol" select="$u-symbol"/>
								</xsl:call-template>
							</xsl:variable>
							<xsl:variable name="prefixName">
								<xsl:value-of select="$prefixNodeSet//tns:prefix[tns:symbol=$pre]/tns:name"/>
							</xsl:variable>
							<xsl:variable name="commonPrefixName">
								<xsl:value-of select="$prefixNodeSet//tns:prefix[./tns:symbol=$pre]/tns:commonName"/>
							</xsl:variable>
							<xsl:variable name="u-Name">
								<xsl:choose>
									<xsl:when test="$u-symbol='psi'">
										<!-- "psi" is special. We abbreviate in derived symbols to save space. -->
										<xsl:text>psi</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$unitNodeSet//tns:unit[./tns:symbol=$u-symbol]/tns:name"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:variable name="prefixForName">
								<xsl:choose>
								<!-- Account for special cases where the final vowel of a prefix is commonly ommitted. -->
									<xsl:when test="$prefixName='mega' and $u-Name='ohm'">
										<xsl:text>meg</xsl:text>
									</xsl:when>
									<xsl:when test="$prefixName='kilo' and $u-Name='ohm'">
										<xsl:text>kil</xsl:text>
									</xsl:when>
									<xsl:when test="$prefixName='hecto' and $u-Name='are'">
										<xsl:text>hect</xsl:text>
									</xsl:when>
								<!-- Use long name for customary (i.e., non-SI) atoms. -->
									<xsl:when test="$category='prefixed' and $isSI='false' and $commonPrefixName!=''">
										<xsl:value-of select="$commonPrefixName"/>
										<xsl:text> </xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$prefixName"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:variable name="nextName">
								<xsl:if test="$name!=''"> </xsl:if>
								<xsl:choose>
									<xsl:when test="$dimension='L' or $dimension='L2' or $dimension='L3'">
										<!-- Length, area or volume is a special case. -->
										<xsl:choose>
											<xsl:when test="$exponent='2'">
												<xsl:text>square </xsl:text>
												<xsl:value-of select="$prefixForName"/>
												<xsl:value-of select="substring-after($u-Name,'square ')"/>
											</xsl:when>
											<xsl:when test="$exponent='3'">
												<xsl:text>cubic </xsl:text>
												<xsl:value-of select="$prefixForName"/>
												<xsl:value-of select="substring-after($u-Name,'cubic ')"/>
											</xsl:when>
											<xsl:when test="$exponent='4'">
												<xsl:value-of select="$prefixForName"/>
												<xsl:value-of select="substring-before($u-Name,' fourth')"/>
												<xsl:text> fourth</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="$prefixForName"/>
												<xsl:value-of select="$u-Name"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="$exponent='2'">
										<xsl:value-of select="$prefixForName"/>
										<xsl:value-of select="substring-before($u-Name,' squared')"/>
										<xsl:text> squared</xsl:text>
									</xsl:when>
									<xsl:when test="$exponent='3'">
										<xsl:value-of select="$prefixForName"/>
										<xsl:value-of select="substring-before($u-Name,' cubed')"/>
										<xsl:text> cubed</xsl:text>
									</xsl:when>
									<xsl:when test="$exponent='4'">
										<xsl:value-of select="$prefixForName"/>
										<xsl:value-of select="substring-before($u-Name,' fourth')"/>
										<xsl:text> fourth</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$prefixForName"/>
										<xsl:value-of select="$u-Name"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:call-template name="generate-name">
								<xsl:with-param name="symbol" select="$symbol"/>
								<xsl:with-param name="pos"    select="$pos +$length"/>
								<xsl:with-param name="name"   select="concat($name,$nextName)"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- Template to convert a WINDOWS/DOS path to an XSL acceptable path. -->
<xsl:template name="fixPath">
	<xsl:param name="path">1</xsl:param>
	<!-- Convert backward slash to forward slash. -->
	<xsl:variable name="temp1">
		<xsl:value-of select="translate($path,'\','/')"/>
	</xsl:variable>
	<!-- Insure that it is not terminated with a slash. -->
	<xsl:variable name="temp2">
		<xsl:choose>
			<xsl:when test="substring($temp1,string-length($temp1),1)='/'">
				<xsl:value-of select="substring($temp1,string-length($temp1)-1,1)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$temp1"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$path=''">
			<!-- Empty value. Return the same. -->
		</xsl:when>
		<xsl:when test="contains($temp2,':')">
			<!-- Remove drive letter. -->
			<xsl:value-of select="substring-after($temp2,':')"/>
			<xsl:text>/</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$temp2"/>
			<xsl:text>/</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Template extract the exponent from an atom.-->
<xsl:template name="get-exponent">
	<xsl:param name="symbol"/>
	<xsl:choose>
		<xsl:when test="ends-with($symbol,'2')">2</xsl:when>
		<xsl:when test="ends-with($symbol,'3')">3</xsl:when>
		<xsl:when test="ends-with($symbol,'4')">4</xsl:when>
		<xsl:when test="ends-with($symbol,'5')">5</xsl:when>
		<xsl:when test="ends-with($symbol,'6')">6</xsl:when>
		<xsl:when test="ends-with($symbol,'7')">7</xsl:when>
		<xsl:when test="ends-with($symbol,'8')">8</xsl:when>
		<xsl:when test="ends-with($symbol,'9')">9</xsl:when>
		<xsl:otherwise>1</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Iteratively substitute base symbols within a component set.-->
<xsl:template name="substituteBase">
	<xsl:param name="nodeSet"/>
	<xsl:choose>
		<xsl:when test="count($nodeSet//tns:component[@isBase='false'])=0">
			<!-- We are finished.-->
			<xsl:call-template name="linebreak"/>
			<xsl:copy-of select="$nodeSet//tns:component"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:for-each select="$nodeSet//tns:component">
				<xsl:sort select="./@atom"/>
				<xsl:variable name="pos"><xsl:value-of select="position()"/></xsl:variable>
				<xsl:variable name="atom"><xsl:value-of select="./@atom"/></xsl:variable>
				<xsl:variable name="isBase"><xsl:value-of select="./@isBase"/></xsl:variable>
				<xsl:variable name="power"><xsl:value-of select="./@power"/></xsl:variable>
				<xsl:choose>
					<xsl:when test="$isBase='true'">
						<!-- We are finished with this component.-->
						<xsl:call-template name="linebreak"/>
						<xsl:copy-of select="."/>
					</xsl:when>
					<xsl:otherwise>
						<!-- We need to substitute the base of this component.-->
						<xsl:variable name="base">
							<xsl:choose>
								<xsl:when test="$dictionaryNodeSet//tns:uomDictionary/tns:unitSet/tns:unit[tns:symbol=$atom]/tns:baseUnit!=''">
									<xsl:value-of select="$dictionaryNodeSet//tns:uomDictionary/tns:unitSet/tns:unit[tns:symbol=$atom]/tns:baseUnit"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$dictionaryNodeSet//tns:uomDictionary/tns:unitSet/tns:unit[tns:symbol=$atom]/tns:underlyingDef"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="componentNodeSet">
							<xsl:call-template name="parseSymbol">
								<xsl:with-param name="symbol" select="$base"/>
								<xsl:with-param name="extPower" select="$power"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:call-template name="substituteBase">
							<xsl:with-param name="nodeSet" select="$componentNodeSet"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Template to generate a canonical symbol.-->
<xsl:template name="generateCanonical">
	<xsl:param name="symbol"/>
	<xsl:variable name="componentNodeSet">
		<!-- Extract knowledge of all the components (ignoring multipliers).-->
		<xsl:call-template name="parseSymbol">
			<xsl:with-param name="symbol" select="$symbol"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="baseNodeSet">
		<!-- Iteratively substitute base for each component.-->
		<xsl:call-template name="substituteBase">
			<xsl:with-param name="nodeSet" select="$componentNodeSet"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="consolidateNodeSet">
		<xsl:for-each select="$baseNodeSet//tns:component">
			<xsl:variable name="pos"><xsl:value-of select="position()"/></xsl:variable>
			<xsl:variable name="atom"><xsl:value-of select="./@atom"/></xsl:variable>
			<xsl:if test="count($baseNodeSet//tns:component[$pos>position() and ./@atom=$atom])=0">
				<!-- This is the first encounter with this atom.-->
				<xsl:element name="component">
					<xsl:attribute name="atom"><xsl:value-of select="$atom"/></xsl:attribute>
					<xsl:attribute name="dimension"><xsl:value-of select="./@dimension"/></xsl:attribute>
					<xsl:attribute name="power">
						<xsl:value-of select="sum($baseNodeSet//tns:component[./@atom=$atom]/@power)"/>
					</xsl:attribute>
				</xsl:element>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="sortedNodeSet">
		<xsl:for-each select="$consolidateNodeSet//tns:component">
			<xsl:sort select="@atom"/>
			<xsl:copy-of select="."/>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="posCount"><xsl:value-of select="count($sortedNodeSet//tns:component[@power > 0])"/></xsl:variable>
	<xsl:variable name="negCount"><xsl:value-of select="count($sortedNodeSet//tns:component[0 > @power])"/></xsl:variable>
	<xsl:variable name="noneCount"><xsl:value-of select="count($sortedNodeSet//tns:component[@dimension='none'])"/></xsl:variable>
	<xsl:choose>
		<xsl:when test="$noneCount!=0">
			<!-- This is non-dimensional. -->
			<xsl:text>0</xsl:text>
		</xsl:when>
		<xsl:when test="$posCount=0 and $negCount=0">
			<!-- This is dimensionless. -->
			<xsl:text>Euc</xsl:text>
		</xsl:when>
		<xsl:when test="$posCount=0">
			<xsl:text>1</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:for-each select="$sortedNodeSet//tns:component[@power > 0]">
				<xsl:variable name="power"><xsl:value-of select="./@power"/></xsl:variable>
				<xsl:value-of select="./@atom"/>
				<xsl:if test="$power>1">
					<xsl:value-of select="$power"/>
				</xsl:if>
				<xsl:if test="$posCount>position()">
					<xsl:text>.</xsl:text>
				</xsl:if>
			</xsl:for-each>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:if test="$negCount>0 and $noneCount=0">
		<xsl:text>/</xsl:text>
		<xsl:if test="$negCount>1">
			<xsl:text>(</xsl:text>
		</xsl:if>
		<xsl:for-each select="$sortedNodeSet//tns:component[0 > @power]">
			<xsl:variable name="power"><xsl:value-of select="./@power"/></xsl:variable>
			<xsl:value-of select="./@atom"/>
			<xsl:if test="abs($power)>1">
				<xsl:value-of select="abs($power)"/>
			</xsl:if>
			<xsl:if test="$negCount>position()">
				<xsl:text>.</xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="$negCount>1">
			<xsl:text>)</xsl:text>
		</xsl:if>
	</xsl:if>
</xsl:template>


<!-- Recursive template to generate the dimensional equivalent of a canonical symbol (which are always SI based).-->
<xsl:template name="generateDimension">
	<xsl:param name="symbol"/>
	<xsl:variable name="componentNodeSet">
		<!-- Extract knowledge of all the components (ignoring multipliers).-->
		<xsl:call-template name="parseSymbol">
			<xsl:with-param name="symbol" select="$symbol"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="baseNodeSet">
		<!-- Iteratively substitute base for each component.-->
		<xsl:call-template name="substituteBase">
			<xsl:with-param name="nodeSet" select="$componentNodeSet"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="consolidateNodeSet">
		<xsl:for-each select="$baseNodeSet//tns:component">
			<xsl:variable name="pos"><xsl:value-of select="position()"/></xsl:variable>
			<xsl:variable name="atom"><xsl:value-of select="./@atom"/></xsl:variable>
			<xsl:if test="count($baseNodeSet//tns:component[$pos>position() and ./@atom=$atom])=0">
				<!-- This is the first encounter with this atom.-->
				<xsl:element name="component">
					<xsl:attribute name="atom"><xsl:value-of select="$atom"/></xsl:attribute>
					<xsl:attribute name="dimension"><xsl:value-of select="./@dimension"/></xsl:attribute>
					<xsl:attribute name="power">
						<xsl:value-of select="sum($baseNodeSet//tns:component[./@atom=$atom]/@power)"/>
					</xsl:attribute>
				</xsl:element>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="sortedNodeSet">
		<xsl:for-each select="$consolidateNodeSet//tns:component">
			<xsl:sort select="@dimension"/>
			<xsl:copy-of select="."/>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="posCount"><xsl:value-of select="count($sortedNodeSet//tns:component[@power > 0])"/></xsl:variable>
	<xsl:variable name="negCount"><xsl:value-of select="count($sortedNodeSet//tns:component[0 > @power])"/></xsl:variable>
	<xsl:variable name="noneCount"><xsl:value-of select="count($sortedNodeSet//tns:component[@dimension='none'])"/></xsl:variable>
	<xsl:choose>
		<xsl:when test="$noneCount!=0">
			<!-- This is non-dimensional. -->
			<xsl:text>none</xsl:text>
		</xsl:when>
		<xsl:when test="$posCount=0 and $negCount=0">
			<!-- This is dimensionless. -->
			<xsl:text>1</xsl:text>
		</xsl:when>
		<xsl:when test="$posCount=0">
			<xsl:text>1</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:for-each select="$sortedNodeSet//tns:component[@power > 0]">
				<xsl:variable name="power"><xsl:value-of select="./@power"/></xsl:variable>
				<xsl:value-of select="./@dimension"/>
				<xsl:if test="$power>1">
					<xsl:value-of select="$power"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:if test="$negCount>0 and $noneCount=0">
		<xsl:text>/</xsl:text>
		<xsl:for-each select="$sortedNodeSet//tns:component[0 > @power]">
			<xsl:variable name="power"><xsl:value-of select="./@power"/></xsl:variable>
			<xsl:value-of select="./@dimension"/>
			<xsl:if test="abs($power)>1">
				<xsl:value-of select="abs($power)"/>
			</xsl:if>
		</xsl:for-each>
	</xsl:if>

</xsl:template>



<!-- Recursive template to generate the dimensional equivalent of a canonical symbol (which are always SI based).-->
<xsl:template name="generateDimensionXXXXXXXX">
	<xsl:param name="symbol"/>		<!-- The symbol being searched.-->
	<xsl:param name="begin">1</xsl:param>	<!-- The beginning position of the substring to search.-->
	<xsl:param name="end">1</xsl:param>	<!-- The ending position of the substring to test. -->
	<xsl:choose>
		<xsl:when test="$begin > string-length($symbol)">
			<!-- We are finished.-->
		</xsl:when>
		<xsl:when test="$symbol='0'">
			<!-- We are finished. Special case of no-dimensions. -->
			<xsl:text>none</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="charEnd">
				<xsl:value-of select="substring($symbol,$end,1)"/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$charEnd='('">
					<!-- Assuming this immediately follows a slash or is the first character, start a new search.-->
					<xsl:call-template name="generateDimensionXXXXXXXX">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="begin" select="$end +1"/>
						<xsl:with-param name="end"   select="$end +1"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$charEnd='.' or $charEnd=')' or $charEnd='/' or $end=string-length($symbol) or $end>string-length($symbol)">
					<!-- We need to process the previous atom. -->
					<xsl:variable name="atom">
						<xsl:choose>
							<xsl:when test="$begin=$end">
								<!-- Presumably, charEnd is not a terminator. -->
								<xsl:value-of select="substring($symbol,$begin,1)"/>
							</xsl:when>
							<xsl:when test="$end=string-length($symbol) and ($charEnd='.' or $charEnd=')' or $charEnd='/')">
								<xsl:value-of select="substring($symbol,$begin,$end -$begin)"/>
							</xsl:when>
							<xsl:when test="$end=string-length($symbol)">
								<xsl:value-of select="substring($symbol,$begin)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="substring($symbol,$begin,$end -$begin)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="power">
						<xsl:choose>
							<xsl:when test="ends-with($atom,'2')">2</xsl:when>
							<xsl:when test="ends-with($atom,'3')">3</xsl:when>
							<xsl:when test="ends-with($atom,'4')">4</xsl:when>
							<xsl:when test="ends-with($atom,'5')">5</xsl:when>
							<xsl:when test="ends-with($atom,'6')">6</xsl:when>
							<xsl:when test="ends-with($atom,'7')">7</xsl:when>
							<xsl:when test="ends-with($atom,'8')">8</xsl:when>
							<xsl:when test="ends-with($atom,'9')">6</xsl:when>
							<xsl:otherwise></xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="str">
						<xsl:choose>
							<xsl:when test="$power=''">
								<xsl:value-of select="$atom"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="substring-before($atom,$power)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
				<!-- Generate the dimension character.-->
					<xsl:choose>
						<xsl:when test="$str='rad'"   >A</xsl:when>
						<xsl:when test="$str='cd'"    >J</xsl:when>
						<xsl:when test="$str='A'"     >I</xsl:when>
						<xsl:when test="$str='K'"     >K</xsl:when>
						<xsl:when test="$str='deltaK'">D</xsl:when>
						<xsl:when test="$str='m'"     >L</xsl:when>
						<xsl:when test="$str='kg'"    >M</xsl:when>
						<xsl:when test="$str='mol'"   >N</xsl:when>
						<xsl:when test="$str='sr'"    >S</xsl:when>
						<xsl:when test="$str='s'"     >T</xsl:when>
						<xsl:when test="$str='1'"     >1</xsl:when>
						<xsl:when test="$str='Euc'"   >1</xsl:when>
						<!-- The following are special cases which need a "1" when they are the only thing in the numerator.-->
						<xsl:when test="$str='B'    and ($charEnd='/' and starts-with($symbol,'B/'))"  >1</xsl:when>
						<xsl:when test="$str='O'    and ($charEnd='.' and starts-with($symbol,'O/'))"  >1</xsl:when>
						<xsl:when test="$str='bit'  and ($charEnd='.' and starts-with($symbol,'bit/'))">1</xsl:when>
						<!-- The following are special cases which need a NULL because they are NOT the only thing in the numerator.-->
						<xsl:when test="$str='B'"  ></xsl:when>
						<xsl:when test="$str='O'"  ></xsl:when>
						<xsl:when test="$str='bit'"></xsl:when>
						<xsl:when test="$str='('"></xsl:when>
						<xsl:when test="$str=')'"></xsl:when>
						<xsl:when test="$str='/'"></xsl:when>
						<xsl:otherwise>ERROR-ATOM</xsl:otherwise>
					</xsl:choose>
				<!-- Generate the power character (if any).-->
					<xsl:value-of select="$power"/>
				<!-- Generate the slash if needed.-->
					<xsl:if test="$charEnd='/'">/</xsl:if>
				<!-- Look for the next atom.-->
					<xsl:call-template name="generateDimensionXXXXXXXX">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="begin" select="$end +1"/>
						<xsl:with-param name="end"   select="$end +1"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<!-- Still looking for a terminator. Check the next character. -->
					<xsl:call-template name="generateDimensionXXXXXXXX">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="begin" select="$begin"/>
						<xsl:with-param name="end" select="$end +1"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- Parse a symbol into its compontents.-->
<!-- The output will be XML containing each component with its power and with a flag indicating numerator or denominator.-->
<!-- Any mutiplier will be ignored.-->
<xsl:template name="parseSymbol">
	<xsl:param name="symbol"/>
	<xsl:param name="begin">1</xsl:param>		<!-- The beginning position of the substring to search. -->
	<xsl:param name="end">1</xsl:param>		<!-- The ending position of the substring to test. -->
	<xsl:param name="level">numerator</xsl:param>	<!-- Whether the current set of components represents the overall "numerator" or "denominator". -->
	<xsl:param name="extPower">1</xsl:param>	<!-- An external power-of to be applied each components. -->
	<xsl:choose>
		<xsl:when test="$begin > string-length($symbol)">
			<!-- We are finished.-->
		</xsl:when>
		<xsl:when test="$symbol='0'">
			<!-- We are finished. Special case of no-components. -->
		</xsl:when>
		<xsl:when test="contains(substring($symbol,$begin),' ')">
			<!-- Start processing after the multiplier (ultimately after the final space - just in case there are several).-->
			<xsl:variable name="offset">
				<xsl:value-of select="string-length(substring-before(substring($symbol,$begin),' '))+1"/>
			</xsl:variable>
			<xsl:call-template name="parseSymbol">
				<xsl:with-param name="symbol"   select="$symbol"/>
				<xsl:with-param name="begin"    select="$end +$offset"/>
				<xsl:with-param name="end"      select="$end +$offset"/>
				<xsl:with-param name="level"    select="$level"/>
				<xsl:with-param name="extPower" select="$extPower"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<!-- Process the next character. -->
			<xsl:variable name="charEnd">
				<xsl:value-of select="substring($symbol,$end,1)"/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$charEnd='('">
					<!-- Assuming this immediately follows a slash or is the first character, start a new search.-->
					<xsl:call-template name="parseSymbol">
						<xsl:with-param name="symbol"   select="$symbol"/>
						<xsl:with-param name="begin"    select="$end +1"/>
						<xsl:with-param name="end"      select="$end +1"/>
						<xsl:with-param name="level"    select="$level"/>
						<xsl:with-param name="extPower" select="$extPower"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$charEnd='.' or $charEnd=')' or $charEnd='/' or $end=string-length($symbol) or $end>string-length($symbol)">
					<!-- We need to process the previous atom. -->
					<xsl:variable name="str">
						<xsl:choose>
							<xsl:when test="$begin=$end">
								<!-- Presumably, charEnd is not a terminator. -->
								<xsl:value-of select="substring($symbol,$begin,1)"/>
							</xsl:when>
							<xsl:when test="$end=string-length($symbol) and ($charEnd='.' or $charEnd=')' or $charEnd='/')">
								<xsl:value-of select="substring($symbol,$begin,$end -$begin)"/>
							</xsl:when>
							<xsl:when test="$end=string-length($symbol)">
								<xsl:value-of select="substring($symbol,$begin)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="substring($symbol,$begin,$end -$begin)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="power">
						<xsl:choose>
							<xsl:when test="ends-with($str,'2')">2</xsl:when>
							<xsl:when test="ends-with($str,'3')">3</xsl:when>
							<xsl:when test="ends-with($str,'4')">4</xsl:when>
							<xsl:when test="ends-with($str,'5')">5</xsl:when>
							<xsl:when test="ends-with($str,'6')">6</xsl:when>
							<xsl:when test="ends-with($str,'7')">7</xsl:when>
							<xsl:when test="ends-with($str,'8')">8</xsl:when>
							<xsl:when test="ends-with($str,'9')">9</xsl:when>
							<xsl:otherwise>1</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="atom">
						<xsl:choose>
							<xsl:when test="$power='1'">
								<xsl:value-of select="$str"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="substring-before($str,$power)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- Output the XML for this component.-->
					<xsl:call-template name="linebreak"/>
					<xsl:element name="component">
						<xsl:attribute name="atom"><xsl:value-of select="$atom"/></xsl:attribute>
						<xsl:attribute name="isBase">
							<xsl:value-of select="$dictionaryNodeSet//tns:uomDictionary/tns:unitSet/tns:unit[tns:symbol=$atom]/tns:isBase='' and
									      not($dictionaryNodeSet//tns:uomDictionary/tns:unitSet/tns:unit[tns:symbol=$atom]/tns:underlyingDef)"/>
						</xsl:attribute>
						<xsl:attribute name="dimension">
							<xsl:value-of select="$dictionaryNodeSet//tns:uomDictionary/tns:unitSet/tns:unit[tns:symbol=$atom]/tns:dimension"/>
						</xsl:attribute>
						<xsl:attribute name="power">
							<xsl:choose>
								<xsl:when test="$level='numerator'">
									<xsl:value-of select="$power * $extPower"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="($power * -1) * $extPower"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
					</xsl:element>
					<!-- Look for the next atom.-->
					<xsl:variable name="nextLevel">
						<xsl:choose>
							<xsl:when test="$charEnd='.'">
								<xsl:value-of select="$level"/>
							</xsl:when>
							<xsl:when test="$charEnd='/' and $level='numerator'">
								<xsl:text>denominator</xsl:text>
							</xsl:when>
							<xsl:when test="$charEnd='/' and $level='denominator'">
								<xsl:text>numerator</xsl:text>
							</xsl:when>
							<xsl:when test="$charEnd=')' and substring($symbol,$end,3)=')/('">
								<xsl:text>denominator</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$level"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="nextStart">
						<xsl:choose>
							<xsl:when test="$charEnd='.'">
								<xsl:value-of select="$end +1"/>
							</xsl:when>
							<xsl:when test="$charEnd='/' and substring($symbol,$end,2)='/('">
								<xsl:value-of select="$end +2"/>
							</xsl:when>
							<xsl:when test="$charEnd=')' and substring($symbol,$end,3)=')/('">
								<xsl:value-of select="$end +3"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$end +1"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:call-template name="parseSymbol">
						<xsl:with-param name="symbol"   select="$symbol"/>
						<xsl:with-param name="begin"    select="$nextStart"/>
						<xsl:with-param name="end"      select="$nextStart"/>
						<xsl:with-param name="level"    select="$nextLevel"/>
						<xsl:with-param name="extPower" select="$extPower"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<!-- Still looking for a terminator. Check the next character. -->
					<xsl:call-template name="parseSymbol">
						<xsl:with-param name="symbol"   select="$symbol"/>
						<xsl:with-param name="begin"    select="$begin"/>
						<xsl:with-param name="end"      select="$end +1"/>
						<xsl:with-param name="level"    select="$level"/>
						<xsl:with-param name="extPower" select="$extPower"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- Recursive template to calculate the conversion factor from the underlying components.-->
<!-- GLOBAL REQUIREMENT: $unitNodeSet and related index variables (see "get-factor" template) -->
<xsl:template name="derived-factor">
	<xsl:param                 name="symbol"/>		<!-- The derived-symbol to be parsed for its components. -->
	<xsl:param                 name="pos">1</xsl:param>	<!-- The beginning position of the substring to test.-->
	<xsl:param as="xsd:double" name="fact">1</xsl:param>	<!-- The current cumulative factor. -->
	<xsl:choose>
		<xsl:when test="$pos > string-length($symbol)">
			<!-- We are finished. -->
			<xsl:value-of select="$fact"/>
		</xsl:when>
		<xsl:when test="contains($symbol,')/(')">
			<!-- Split this into two components - a numerator and a denominator. Then divide the component factors. -->
			<xsl:variable name="numFact">
				<xsl:variable name="numSymbol">
					<xsl:value-of select="concat(substring-before($symbol,')/('),')')"/>
				</xsl:variable>
				<xsl:call-template name="derived-factor">
					<xsl:with-param name="symbol" select="$numSymbol"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="denFact">
				<xsl:variable name="denSymbol">
					<xsl:value-of select="concat('(',substring-after($symbol,')/('))"/>
				</xsl:variable>
				<xsl:call-template name="derived-factor">
					<xsl:with-param name="symbol" select="$denSymbol"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="combinedFact" as='xsd:double'>
				<xsl:value-of select="$numFact div $denFact"/>
			</xsl:variable>
			<!-- We are finished. -->
			<xsl:value-of select="$combinedFact"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="start">
				<!-- Find the starting position of the next component.-->
				<xsl:call-template name="next-comp">
					<xsl:with-param name="symbol" select="$symbol"/>
					<xsl:with-param name="pos" select="$pos"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$start=0">
					<!-- No more components found.-->
					<!-- We are finished. -->
					<xsl:value-of select="$fact"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="end">
						<!-- Find the terminator of the next component.-->
						<xsl:call-template name="next-term">
							<xsl:with-param name="symbol" select="$symbol"/>
							<xsl:with-param name="start" select="$start"/>
							<xsl:with-param name="pos" select="$start"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:variable name="length">
						<xsl:choose>
							<xsl:when test="$end=0">
								<xsl:value-of select="string-length($symbol) -$start +1"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$end -$start"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="component">
						<xsl:value-of select="substring($symbol,$start,$length)"/>
					</xsl:variable>
					<xsl:variable name="factor" as="xsd:double">
						<xsl:choose>
							<xsl:when test="starts-with($component,'.') or
									starts-with($component,'0') or
									starts-with($component,'1') or
									starts-with($component,'2') or
									starts-with($component,'3') or
									starts-with($component,'4') or
									starts-with($component,'5') or
									starts-with($component,'6') or
									starts-with($component,'7') or
									starts-with($component,'8') or
									starts-with($component,'9') ">
								<!-- This is a multiplier.-->
								<xsl:value-of select="$component"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="get-factor">
									<xsl:with-param as="xsd:string" name="symbol" select="$component"/>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="spaceIndex">
						<xsl:call-template name="find-char">
							<xsl:with-param name="symbol" select="$symbol"/>
							<xsl:with-param name="char"><xsl:text> </xsl:text></xsl:with-param>
						</xsl:call-template>
					</xsl:variable>
					<xsl:variable name="divide">
						<xsl:choose>
							<xsl:when test="$spaceIndex=0">
								<!-- There is no multipier which might have contained a slash.-->
								<xsl:choose>
									<xsl:when test="contains(substring($symbol,1,$start),'/')">
										<!-- This is in the denominator.-->
										<xsl:text>YES</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<!-- This is in the numerator.-->
										<xsl:text>NO</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="number($spaceIndex) > number($start)">
								<!-- This is in the multiplier.-->
								<xsl:choose>
									<xsl:when test="contains(substring($symbol,1,$start),'/')">
										<!-- This is in the denominator.-->
										<xsl:text>YES</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<!-- This is in the numerator.-->
										<xsl:text>NO</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:otherwise>
								<!-- This is AFTER the numerator.-->
								<xsl:choose>
									<xsl:when test="contains(substring($symbol,$spaceIndex,$start -$spaceIndex +1),'/')">
										<!-- This is in the denominator.-->
										<xsl:text>YES</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<!-- This is in the numerator.-->
										<xsl:text>NO</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable as="xsd:double" name="cumulative">
						<xsl:choose>
							<xsl:when test="$divide='YES'">
								<!-- This is in the denominator.-->
								<xsl:value-of select="$fact div $factor"/>
							</xsl:when>
							<xsl:otherwise>
								<!-- This is in the numerator.-->
								<xsl:value-of select="$fact * $factor"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$factor=$ERROR">
							<!-- A component was not found. -->
							<!-- We are finished.-->
							<xsl:value-of select="$ERROR"/>
						</xsl:when>
						<xsl:otherwise>
							<!-- Process the next component.-->
							<xsl:call-template name="derived-factor">
								<xsl:with-param name="symbol" select="$symbol"/>
								<xsl:with-param name="pos" select="$start +$length"/>
								<xsl:with-param name="fact" select="$cumulative"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- Recursive template to find the starting position of the next component (multiplier or atom-symbol) within a derived-symbol. -->
<!-- A value of zero will be returned if no component was found. -->
<!-- The component may be a multiplier. -->
<xsl:template name="next-comp">
	<xsl:param name="symbol"/>		<!-- The derived-symbol to be parsed for its components. -->
	<xsl:param name="pos">1</xsl:param>	<!-- The current position to test for a space, paren, slash, period or end of string. -->
	<xsl:choose>
		<xsl:when test="$pos > string-length($symbol)">
			<!-- Not found. -->
			<!-- We are finished. -->
			<xsl:text>0</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="char"><xsl:value-of select="substring($symbol,$pos,1)"/></xsl:variable>
			<xsl:choose>
				<xsl:when test="$char='.' and 
						$pos=1">
					<!-- This is a period for a beginning multiplier. -->
					<!-- We are finished. -->
					<xsl:value-of select="$pos"/>
				</xsl:when>
				<xsl:when test="$char=' ' or 
						$char='.' or
						$char='/' or
						$char='(' or
						$char=')' ">
					<!-- This is a delimiter. -->
					<!-- Keep looking. -->
					<xsl:call-template name="next-comp">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="pos" select="$pos +1"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<!-- This must be the beginning of a component. -->
					<!-- We are finished. -->
					<xsl:value-of select="$pos"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>



<!-- Recursive template to find the next terminator within a symbol. -->
<!-- When start=1, a period after a starting character of a number will be presumed to NOT be a termnator. -->
<!-- Zero will be returned if the end of string was encountered. -->
<!-- There is an underlying assumption that the character at start is not a delimeter (space, period (not in multiplier), slash, open paren, closed paren). -->
<xsl:template name="next-term">
	<xsl:param name="symbol"/>		<!-- The derived symbol to be parsed for its components. -->
	<xsl:param name="start">1</xsl:param>	<!-- The beginning position of the substring to test. Looking for a delimeter after this spot. -->
	<xsl:param name="pos">2</xsl:param>	<!-- The current position to test for a space, paren, slash, period or end of string. -->
	<xsl:choose>
		<xsl:when test="$pos > string-length($symbol)">
			<!-- Not found. -->
			<!-- We are finished. -->
			<xsl:text>0</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="char"><xsl:value-of select="substring($symbol,$pos,1)"/></xsl:variable>
			<xsl:variable name="char1"><xsl:value-of select="substring($symbol,$start,1)"/></xsl:variable>
			<xsl:choose>
				<xsl:when test="$char='.' and 
						$start=1  and contains($symbol,' ') and
						($char1='1' or
						 $char1='2' or
						 $char1='3' or
						 $char1='4' or
						 $char1='5' or
						 $char1='6' or
						 $char1='7' or
						 $char1='8' or
						 $char1='9' or
						 $char1='0' )">
					<!-- This is a period within a beginning multiplier. -->
					<!-- Keep looking. -->
					<xsl:call-template name="next-term">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="start" select="$start"/>
						<xsl:with-param name="pos" select="$pos +1"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$char=' ' or 
						$char='.' or
						$char='/' or
						$char=')' ">
					<!-- We are finished. -->
					<xsl:value-of select="$pos"/>
				</xsl:when>
				<xsl:when test="$char='('">
					<!-- Something is wrong. This should only occur at beginning and after a "/". -->
					<xsl:value-of select="$ERROR"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- Keep looking. -->
					<xsl:call-template name="next-term">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="start" select="$start"/>
						<xsl:with-param name="pos" select="$pos +1"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>



<!-- Template to calculate the conversion factor for a derived-symbol from the factors of its component-symbols. -->
<!-- A returned value equal to $ERROR indicates that the component was not found. -->
<!-- GLOBAL REQUIREMENT: $unitNodeSet -->
<xsl:template name="get-factor">
	<xsl:param name="symbol" as="xsd:string"/>

	<!-- Get the data if it is non-deprecated or is a valid equivalent of a non-deprecated symbol. -->
	<xsl:variable name="compNodeSet" select="$unitNodeSet//tns:unit[./tns:symbol=$symbol]"/>
	<xsl:variable name="symbTest"> <xsl:value-of select="$compNodeSet//tns:symbol"/></xsl:variable>
	<xsl:variable name="base">     <xsl:value-of select="$compNodeSet//tns:baseUnit"/></xsl:variable>
	<xsl:variable name="A">        <xsl:value-of select="$compNodeSet//tns:A"/></xsl:variable>
	<xsl:variable name="D">        <xsl:value-of select="$compNodeSet//tns:D"/></xsl:variable>
	<xsl:variable name="B">
		<xsl:call-template name="substitute-PI">
			<xsl:with-param name="value" select="$compNodeSet/tns:B"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="C">
		<xsl:call-template name="substitute-PI">
			<xsl:with-param name="value" select="$compNodeSet/tns:C"/>
		</xsl:call-template>
	</xsl:variable>

	<xsl:variable name="exponent">
		<xsl:call-template name="get-exponent">
			<xsl:with-param name="symbol" select="$symbol"/>
		</xsl:call-template>
	</xsl:variable>

	<xsl:choose>
		<xsl:when test="$symbTest='' and $exponent!=1">
			<!-- The symbol is missing but it has an exponent. See if the underlying component can be found. -->
			<xsl:variable name="u-sym">
				<!-- Get the underlying symbol without the exponent. -->
				<xsl:value-of select="substring($symbol,1,string-length($symbol) -1)"/>
			</xsl:variable>
			<xsl:variable name="u-fact">
				<!-- Get the factor of the underlying symbol. -->
				<xsl:call-template name="get-factor">
					<xsl:with-param name="symbol" select="$u-sym"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$u-fact=$ERROR">
					<!-- Not found. -->
					<xsl:value-of select="$ERROR"/>

				</xsl:when>
				<xsl:otherwise>
					<!-- Return the underlying factor raised to the power. -->
					<xsl:variable name="to-power">
						<xsl:call-template name="power">
							<!-- The underlying factor raised to the power. -->
							<xsl:with-param name="base" select="$u-fact"/>
							<xsl:with-param name="exponent" select="$exponent"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:value-of select="$to-power"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:when test="$symbTest=''">
			<!-- Not found and exponent is one. -->
			<xsl:value-of select="$ERROR"/>
		</xsl:when>
		<xsl:otherwise>
			<!-- A symbol was found. -->
			<xsl:variable as="xsd:double" name="fact">
				<xsl:choose>
					<xsl:when test="$base=''">1</xsl:when>
					<xsl:when test="$A!='0'">
						<!--Cannot handle offset. -->
						<xsl:value-of select="$ERROR"/>
					</xsl:when>
					<xsl:when test="$D!='0'">
						<!--Cannot handle non-zero D. -->
						<xsl:value-of select="$ERROR"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$B div $C"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:value-of select="$fact"/>
		</xsl:otherwise>
	</xsl:choose>

</xsl:template>

<!-- Recursive template to calculate the POSITIVE power of a value. That is,  base**exponent.-->
<xsl:template name="power">
	<xsl:param name="base"/>
	<xsl:param name="exponent"/>
	<xsl:param name="result">1</xsl:param>
	<xsl:choose>
		<xsl:when test="$exponent=$ERROR"><xsl:value-of select="$ERROR"/></xsl:when>
		<xsl:when test="0 > $exponent"><xsl:value-of select="$ERROR"/></xsl:when>
		<xsl:when test="$exponent = 0">
			<xsl:value-of select="1"/>
		</xsl:when>
		<xsl:when test="$exponent = 1">
			<xsl:value-of select="$result * $base"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="power">
				<xsl:with-param name="base" select="$base"/>
				<xsl:with-param name="exponent" select="$exponent - 1"/>
				<xsl:with-param name="result" select="$result * $base"/>
			</xsl:call-template>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- Recursive template to find the index of the next occurrence of the specified character. -->
<!-- Zero will be returned if the character was not encountered. -->
<xsl:template name="find-char">
	<xsl:param name="symbol"/>		<!-- The derived symbol to be parsed for its components. -->
	<xsl:param name="char"/>		<!-- The character to be located. -->
	<xsl:param name="pos">1</xsl:param>	<!-- The current position to test for the character. -->
	<xsl:choose>
		<xsl:when test="$pos > string-length($symbol)">
			<!-- Not found. -->
			<!-- We are finished. -->
			<xsl:text>0</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="testChar"><xsl:value-of select="substring($symbol,$pos,1)"/></xsl:variable>
			<xsl:choose>
				<xsl:when test="$testChar=$char"> 
					<!-- We are finished. -->
					<xsl:value-of select="$pos"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- Keep looking. -->
					<xsl:call-template name="find-char">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="char" select="$char"/>
						<xsl:with-param name="pos" select="$pos +1"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- Template to return a value with the numeric equivalent substituted for the string "PI", "2*PI" or "4*PI". -->
<xsl:template name="substitute-PI">
	<xsl:param name="value"/>		<!-- The value which may contain the string indicator for PI. -->
	<xsl:variable name="norValue">
		<xsl:value-of select="normalize-space($value)"/>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$norValue='PI'">
			<xsl:value-of select="$PI"/>
		</xsl:when>
		<xsl:when test="$norValue='2*PI'">
			<xsl:value-of select="2 * $PI"/>
		</xsl:when>
		<xsl:when test="$norValue='4*PI'">
			<xsl:value-of select="4 * $PI"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$norValue"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- Recursive template to find the underlying symbol in a PREFIXED symbol (i.e., NO EXPONENT). -->
<!-- This is a brute-force effort which combines all prefixes with all underlying components until a match is found. -->
<!-- The row position of the underlying unit will be returned. -->
<!-- If the underlying unit is not found then a null string will be returned. -->
<!-- GLOBAL REQUIREMENT: $prefixNodeSet     and related index variables
			 $underlyingNodeSet and related index variables -->
<xsl:template name="findUnderlyingPos">
	<xsl:param name="symbol"/>		<!-- The symbol containing the prefix. -->
	<xsl:param name="pos">1</xsl:param>	<!-- The next symbol to test in the nodeset containing all underlying component symbols. -->
	<xsl:variable name="u-symbol">
			<!-- Try the next underlying component symbol.-->
		<xsl:value-of select="$underlyingNodeSet[position()=$pos]/tns:symbol"/>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$u-symbol=''">
			<!-- We are finished. No underlying symbol found. -->
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="prefix">
				<!-- Combine each prefix with the component until we find a match with the input symbol. -->
				<xsl:value-of select="$prefixNodeSet//tns:prefix[concat(./tns:symbol,$u-symbol)=$symbol]/tns:symbol"/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$prefix!=''">
					<!-- We are finished.-->
					<xsl:value-of select="$pos"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- Try the next underlying component symbol. -->
					<xsl:call-template name="findUnderlyingPos">
						<xsl:with-param name="symbol" select="$symbol"/>
						<xsl:with-param name="pos" select="$pos +1"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


</xsl:transform>
