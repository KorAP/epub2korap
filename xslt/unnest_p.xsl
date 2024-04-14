<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:saxon="http://saxon.sf.net/"
                exclude-result-prefixes="saxon">

    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes" saxon:line-length="1000"/>

    <xsl:template match="p/p">
        <span>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:mode on-no-match="shallow-copy"/>

</xsl:stylesheet>
