<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:saxon="http://saxon.sf.net/"
                exclude-result-prefixes="saxon">

    <xsl:output method="xml" indent="yes" saxon:line-length="1000"
    doctype-public="-//IDS//DTD IDS-I5 1.0//EN"
    doctype-system="http://corpora.ids-mannheim.de/I5/DTD/i5.dtd"
    />

    <xsl:mode on-no-match="shallow-copy"/>

    <xsl:template match="p[not(normalize-space())]" priority="1.0"/>

    <xsl:template match="div[not(normalize-space())]" priority="1.0"/>

    <xsl:template match="p[descendant::div|descendant::p]" priority="0.9">
        <div type="section">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="(ref|emph|hi|text())[parent::div]" priority="0.9">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="head[parent::p]">
        <hi rend="bold">
            <xsl:value-of select="."/>
        </hi>
    </xsl:template>

    <xsl:template match="hi[parent::div]">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="p[normalize-space(.) = '&#160;']"/>

</xsl:stylesheet>