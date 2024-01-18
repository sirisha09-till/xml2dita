<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://sample.com/ns/xslt/functions" xmlns:py="https://www.python.org"
    exclude-result-prefixes="#all">

    <xsl:template match="section[child::desc[@domain = 'py']]">
            <topic id="{replace(@ids,' .*','')}">
            <title>
                <xsl:value-of select="title"/>
            </title>
            <body>
                <xsl:apply-templates
                    select="*[not(self::desc[@domain = 'py']) and not(self::section[1])]"/>
            </body>
            <xsl:apply-templates select="desc[@domain = 'py']|section" mode="py"/>
        </topic>
    </xsl:template>
    
    
    <xsl:template match="desc[@domain = 'py']" mode="py">
        <topic id="{desc_signature/@ids}">
            <xsl:apply-templates mode="py">
                <xsl:with-param name="desctype" select="@desctype"/>
            </xsl:apply-templates>
        </topic>
    </xsl:template>

    <xsl:template match="desc_signature" mode="py">
        <xsl:param name="desctype"/>
        <title>
            <xsl:apply-templates mode="py">
                <xsl:with-param name="desctype" select="$desctype"/>
                <xsl:with-param name="classes" select="substring-before(@classes, ' ')"/>
            </xsl:apply-templates>
        </title>
    </xsl:template>

    <xsl:template match="desc_annotation" mode="py">
        <xsl:param name="classes"/>
        <ph>
            <xsl:attribute name="outputclass" select="concat('api', $classes, '__annotation')"/>
            <xsl:apply-templates mode="py">
                <xsl:with-param name="classes" select="substring-before(@classes, ' ')"/>
            </xsl:apply-templates>
        </ph>
    </xsl:template>

    <xsl:template match="desc_sig_space" mode="py"/>

    <xsl:template match="desc_addname" mode="py">
        <xsl:param name="classes"/>
        <codeph>
            <xsl:attribute name="outputclass" select="concat('api', $classes, '__addname')"/>
            <xsl:apply-templates/>
        </codeph>
    </xsl:template>

    <xsl:template match="desc_name" mode="py">
        <xsl:param name="desctype"/>
        <xsl:param name="classes"/>
        <codeph>
            <xsl:attribute name="outputclass" select="concat('api', $classes, '__', $desctype)"/>
            <xsl:apply-templates/>
        </codeph>
    </xsl:template>

    <xsl:template match="desc_parameterlist" mode="py">
        <ph outputclass="apisig__params">
            <xsl:text>(</xsl:text>
            <xsl:for-each select="desc_parameter">
                <ph outputclass="apisig__param">
                    <xsl:variable name="pos" select="position()"/>
                    <xsl:apply-templates mode="py"/>
                    <xsl:if test="$pos != last()">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                </ph>
            </xsl:for-each>
            <xsl:text>)</xsl:text>
        </ph>
    </xsl:template>

    <xsl:template match="desc_sig_name" mode="py">
        <codeph outputclass="apisig__name">
            <xsl:apply-templates/>
        </codeph>
    </xsl:template>

    <xsl:template match="desc_sig_operator" mode="py">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="inline" mode="py">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="desc_content" mode="py">
        <body>
            <xsl:apply-templates select="*[not(self::desc[@domain = 'py'])]"/>
        </body>
        <xsl:apply-templates select="desc[@domain = 'py']" mode="py"/>
    </xsl:template>

    <xsl:template match="seealso[child::bullet_list]">
        <div outputclass="seealso">
            <p>See also: </p>
            <xsl:apply-templates/>
        </div>
    </xsl:template>


    <xsl:template match="doctest_block[contains(@classes, 'doctest')]">
        <codeblock>
            <xsl:attribute name="outputclass" select="'doctest_block language-python'"/>
            <xsl:apply-templates/>
        </codeblock>
    </xsl:template>

    <xsl:template match="literal[contains(@classes, 'py')]">
        <codeph outputclass="language-python">
            <xsl:apply-templates/>
        </codeph>
    </xsl:template>

    <xsl:template match="section" mode="py">
        <topic>
            <xsl:attribute name="id" select="@ids"/>
            <title>
                <xsl:value-of select="title"/>
            </title>
            <body>
                <xsl:apply-templates/>
            </body>
        </topic>
    </xsl:template>
</xsl:stylesheet>
