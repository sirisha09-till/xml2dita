<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://sample.com/ns/xslt/functions" xmlns:py="https://www.python.org"
    exclude-result-prefixes="#all">
    <xsl:import href="./python_api.xsl"/>
    <xsl:strip-space elements="*"/>


    <!-- parameters -->
    <xsl:param name="xmlDir" select="''"/>
    <xsl:param name="ditaDir" select="''"/>

    <!-- global variables -->
    <xsl:variable name="xmldirpath"
        select="concat('file:/', replace(concat($xmlDir, '/'), '[\\/]+', '/'))"/>
    <xsl:variable name="outdirpath"
        select="concat('file:/', replace(concat($ditaDir, '/'), '[\\/]+', '/'))"/>

    <!-- convert current rst to output dita filename with relative path to ditadir -->
    <xsl:function name="fn:ditafilepath">
        <xsl:param name="doc"/>
        <xsl:choose>
            <xsl:when test="$xmlDir">
                <xsl:value-of
                    select="replace(replace(substring-after($doc, $xmldirpath), '\.xml', '.dita'), ' ', '%20')"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of
                    select="replace(replace(replace($doc, '.*/', ''), '\.xml', '.dita'), ' ', '%20')"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- dita filename only  -->
    <xsl:function name="fn:ditafilename">
        <xsl:param name="doc"/>
        <xsl:value-of select="replace(replace($doc, '.*/', ''), '\.xml', '.dita')"/>
    </xsl:function>

    <xsl:template name="main">
        <xsl:for-each select="collection(concat($xmldirpath, '?select=*.xml;recurse=yes'))">
            <xsl:variable name="file" select="fn:ditafilepath(document-uri(.))"/>
            <xsl:variable name="filePath" select="concat($outdirpath, $file)"/>
            <xsl:message select="$file"/>
            <xsl:result-document href="{$filePath}" method="xml" encoding="UTF-8" indent="no">
                <xsl:choose>
                    <xsl:when test="count(/*/*)">
                        <xsl:call-template name="document">
                            <xsl:with-param name="file" select="$file"/>
                        </xsl:call-template>                        
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates/>
                    </xsl:otherwise>
                </xsl:choose>                
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="document">
        <xsl:param name="file"/>
        <topic>
            <xsl:attribute name="id">
                <xsl:value-of select="''"/>
            </xsl:attribute>
            <title/>
            <body/>
        </topic>
    </xsl:template>

    <xsl:template match="document">
        <xsl:apply-templates select="section[1]"/>
    </xsl:template>

    <xsl:template match="section">
        <topic>
            <xsl:choose>
                <xsl:when test="preceding-sibling::target">
                    <xsl:attribute name="id">
                        <xsl:value-of select="preceding-sibling::target/@refid"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                <xsl:apply-templates select="@ids"/>
                </xsl:otherwise>
            </xsl:choose>
            <title>
                <xsl:value-of select="title"/>
            </title>
            <xsl:apply-templates select="subtitle"/>
            <xsl:choose>
                <xsl:when test="parent::document and child::field_list">
                    <prolog>
                        <xsl:for-each select="field_list/field">
                            <xsl:choose>
                                <xsl:when test="contains(lower-case(field_name), 'author') or contains(lower-case(field_name),'Author')">                                   
                                    <data name="author">
                                        <xsl:attribute name="value">
                                            <xsl:value-of select="normalize-space(field_body//paragraph)"/>                     
                                        </xsl:attribute>                                        
                                    </data>
                                </xsl:when>
                                <xsl:when test="contains(lower-case(field_name), 'copyright')">
                                    <data name="copyright">
                                        <xsl:attribute name="value">
                                            <xsl:value-of
                                                select="normalize-space(field_body//paragraph)"/>
                                        </xsl:attribute>
                                    </data>
                                </xsl:when>
                                <xsl:otherwise>
                                    <data name="{lower-case(field_name)}">
                                        <xsl:attribute name="value">
                                            <xsl:value-of select="field_body//paragraph"/>
                                        </xsl:attribute>
                                    </data>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                        <xsl:apply-templates select="meta" mode="prolog"/>
                    </prolog>
                </xsl:when>
                <xsl:when test="parent::document and not(child::field_list) and child::meta">
                    <prolog>
                        <xsl:apply-templates select="meta" mode="prolog"/>
                    </prolog>
                </xsl:when>
            </xsl:choose>
            <body>
                <xsl:apply-templates select="*[not(self::section)]"/>
            </body>
            <xsl:apply-templates select="section"/>
        </topic>
    </xsl:template>

    <xsl:template match="section[child::desc[@domain = 'py']]">
        <xsl:apply-imports/>
    </xsl:template>

    <xsl:template match="subtitle">
        <shortdesc>
            <xsl:apply-templates/>
        </shortdesc>
    </xsl:template>

    <xsl:template match="meta" mode="prolog">
        <data name="{@name}" value="{@content}" xml:lang="{@lang}"/>
    </xsl:template>

    <xsl:template match="*">
        <required-cleanup>
            <xsl:copy-of select="."/>
        </required-cleanup>
    </xsl:template>

    <xsl:template match="title"/>
    <xsl:template match="section[1]/field_list"/>

    <xsl:template match="compound[@classes = 'toctree-wrapper']"/>

    <xsl:template match="paragraph | line">
        <p>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="@translatable">
        <xsl:attribute name="translate" select="
                if (. = 'False') then
                    'no'
                else
                    'yes'"/>
    </xsl:template>

    <xsl:template match="line_block">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="block_quote">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="comment">
        <xsl:comment><xsl:apply-templates/></xsl:comment>
    </xsl:template>

    <xsl:template match="note | versionmodified">
        <note>
            <xsl:apply-templates/>
        </note>
    </xsl:template>

    <xsl:template match="important | attention">
        <note type="attention">
            <xsl:apply-templates/>
        </note>
    </xsl:template>

    <xsl:template match="hint | tip">
        <note type="tip">
            <xsl:apply-templates/>
        </note>
    </xsl:template>

    <xsl:template match="error">
        <xsl:message>
            <xsl:value-of select="name(.)"/> 'Unsupported note type' </xsl:message>
        <note type="note">
            <xsl:apply-templates/>
        </note>
    </xsl:template>

    <xsl:template match="warning | caution">
        <note type="warning">
            <xsl:apply-templates/>
        </note>
    </xsl:template>

    <xsl:template match="danger">
        <note type="danger">
            <xsl:apply-templates/>
        </note>
    </xsl:template>

    <xsl:template match="attribution">
        <p outputclass="attribution">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="figure">
        <fig>
            <xsl:apply-templates select="caption"/>
            <xsl:apply-templates select="image"/>
        </fig>
    </xsl:template>

    <xsl:template match="caption">
        <title>
            <xsl:value-of select="."/>
        </title>
    </xsl:template>

    <xsl:template match="image">
        <xsl:if test="@title">
            <xsl:value-of select="@title"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="starts-with(@uri,'http')">
                <image href="{@uri}" scope="external"/>   
            </xsl:when>
            <xsl:otherwise>
                <!-- rest image path in xml is relative to the root directory so translate to "relative to here" -->
                <xsl:variable name="doubledots"
                    select="count(tokenize(fn:ditafilepath(document-uri(/)), '/')) - 1"/>
                <xsl:variable name="relativepath">
                    <xsl:for-each select="tokenize(fn:ditafilepath(document-uri(/)), '/')">
                        <xsl:if test="not(position() = 1)">
                            <xsl:value-of select="'../'"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <image href="{$relativepath}{@uri}">
                    <xsl:copy-of select="@* except (@candidates, @width, @uri, @title)"/>
                    <xsl:choose>
                        <xsl:when test="@title">
                            <xsl:attribute name="placement">
                                <xsl:value-of select="'break'"/>
                            </xsl:attribute>
                        </xsl:when>
                        <!--convert percent to pixel-->
                        <xsl:when test="matches(@width, '\d%')"> 
                            <xsl:attribute name="width">
                                <xsl:value-of select="concat(0.16*number(replace(@width,'%','')),'px')"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:when test="matches(@width, '\d\D')">
                            <xsl:attribute name="width">
                                <xsl:value-of select="@width"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:when test="matches(@width, '\d')">
                            <xsl:attribute name="width">
                                <xsl:value-of select="concat(@width, 'px')"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </image>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@classes">
        <xsl:attribute name="outputclass" select="."/>
    </xsl:template>

    <xsl:template match="table">
        <table>
            <xsl:apply-templates select="@* | node()"/>
        </table>
    </xsl:template>

    <xsl:template match="tgroup">
        <tgroup>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="*"/>
        </tgroup>
    </xsl:template>

    <xsl:template match="colspec">
        <colspec>
            <xsl:choose>
                <xsl:when test="not(@colwidth)">
                    <xsl:message terminate="no"> Warning: colwidth cannot be empty </xsl:message>
                    <xsl:attribute name="colwidth" select="1"/>
                    <xsl:attribute name="colname" select="concat('c', position())"/>
                </xsl:when>
                <xsl:when test="matches(@colwidth, '\D')">
                    <xsl:copy-of select="@colwidth"/>
                    <xsl:attribute name="colname" select="concat('c', position())"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="colwidth" select="concat(@colwidth, '*')"/>
                    <xsl:attribute name="colname" select="concat('c', position())"/>
                </xsl:otherwise>
            </xsl:choose>
        </colspec>
    </xsl:template>

    <xsl:template match="thead | tbody | row">
        <xsl:element name="{local-name()}">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="*"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="entry">
        <xsl:choose>
            <xsl:when test="@morecols">
                <xsl:variable name="start"
                    select="position() + sum(preceding-sibling::entry/@morecols)"/>
                <xsl:variable name="end" select="$start + @morecols"/>
                <entry namest="{concat('c',$start)}" nameend="{concat('c',$end)}">
                    <xsl:apply-templates/>
                </entry>
            </xsl:when>
            <xsl:otherwise>
                <entry>
                    <xsl:apply-templates select="@*"/>
                    <xsl:apply-templates/>
                </entry>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="entry/@classes">
        <xsl:choose>
            <xsl:when test=". = 'text-left'">
                <xsl:attribute name="align" select="'left'"/>
            </xsl:when>
            <xsl:when test=". = 'text-right'">
                <xsl:attribute name="align" select="'right'"/>
            </xsl:when>
            <xsl:when test=". = 'text-center'">
                <xsl:attribute name="align" select="'center'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="legend">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="legend/table">
        <p>
            <table>
                <xsl:apply-templates/>
            </table>
        </p>
    </xsl:template>

    <!-- lists and data structures -->

    <xsl:template match="option_list">
        <simpletable outputclass="option_list">
            <xsl:apply-templates/>
        </simpletable>
    </xsl:template>

    <xsl:template match="option_list_item">
        <strow>
            <xsl:apply-templates/>
        </strow>
    </xsl:template>

    <xsl:template match="option_group">
        <stentry>
            <xsl:apply-templates/>
        </stentry>
    </xsl:template>

    <xsl:template match="description">formuladirpathformuladirpath        <stentry>
            <xsl:apply-templates/>
        </stentry>
    </xsl:template>

    <xsl:template match="option">
        <synph>
            <xsl:apply-templates/>
        </synph>
        <xsl:if test="position() != last()">, </xsl:if>
    </xsl:template>

    <xsl:template match="option_string">
        <kwd>
            <xsl:apply-templates/>
        </kwd>
    </xsl:template>

    <xsl:template match="option_argument">
        <xsl:if test="@delimiter">
            <delim>
                <xsl:value-of select="@delimiter"/>
            </delim>
        </xsl:if>
        <var>
            <xsl:apply-templates/>
        </var>
    </xsl:template>

    <xsl:template match="todo_node">
        <dl>
            <dlentry>
                <dt>
                    <xsl:apply-templates select="title"/>
                </dt>
                <xsl:apply-templates select="paragraph" mode="dd"/>
            </dlentry>
        </dl>
    </xsl:template>

    <xsl:template match="paragraph" mode="dd">
        <dd>
            <xsl:apply-templates/>
        </dd>
    </xsl:template>

    <xsl:template match="bullet_list">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>

    <xsl:template match="list_item">
        <li>
            <xsl:apply-templates/>
        </li>
    </xsl:template>

    <xsl:template match="enumerated_list">
        <ol>
            <xsl:apply-templates/>
        </ol>
    </xsl:template>


    <xsl:template match="field_list">
        <dl outputclass="field_list">
            <xsl:apply-templates/>
        </dl>
    </xsl:template>

    <xsl:template match="field">
        <dlentry>
            <xsl:apply-templates/>
        </dlentry>
    </xsl:template>

    <xsl:template match="field_name">
        <dt>
            <xsl:apply-templates/>
        </dt>
    </xsl:template>

    <xsl:template match="field_body">
        <dd>
            <xsl:apply-templates/>
        </dd>
    </xsl:template>


    <xsl:template match="definition_list">
        <dl outputclass="definition_list">
            <xsl:apply-templates/>
        </dl>
    </xsl:template>

    <xsl:template match="definition_list_item">
        <dlentry>
            <xsl:apply-templates/>
        </dlentry>
    </xsl:template>

    <xsl:template match="term">
        <dt>
            <xsl:apply-templates/>
            <xsl:apply-templates select="following-sibling::classifier" mode="term"/>
        </dt>
    </xsl:template>

    <xsl:template match="classifier" mode="term"> (<xsl:apply-templates/>) </xsl:template>

    <xsl:template match="classifier"/>

    <xsl:template match="definition">
        <dd>
            <xsl:apply-templates/>
        </dd>
    </xsl:template>


    <!-- refs -->

    <xsl:template match="reference">
        <xsl:choose>
            <xsl:when test="
                    starts-with(@refuri, 'http:')
                    or starts-with(@refuri, 'https:')
                    or starts-with(@refuri, 'mailto:')">
                <xref href="{@refuri}" scope="external" format="html">
                    <xsl:apply-templates/>
                </xref>
            </xsl:when>
            <!-- file reference as text only  -->
            <xsl:when test="starts-with(@refuri, 'file:')">
                <filepath>
                    <xsl:value-of select="text()"/>
                </filepath>
            </xsl:when>
            <!-- local file reference -->
            <xsl:when test="starts-with(@refuri, '#') or @refid">
                <xsl:variable name="refid">
                    <xsl:choose>
                        <xsl:when test="starts-with(@refuri, '#')">
                            <xsl:value-of select="substring-after(@refuri, '#')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@refid"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="target" select="//*[@ids = $refid]"/>
                <xsl:choose>
                    <xsl:when test="name($target) = ('section','desc_signature')">
                        <xref href="#{$refid}"/>
                    </xsl:when>
                    <!-- Unknown target -->
                    <xsl:otherwise>
                        <xsl:message select="concat('WARNING: Unknown reference: ', @refuri)"/>
                        <xsl:value-of select="text()"/>
                    </xsl:otherwise>
                </xsl:choose>
               <!-- <xsl:variable name="topicid"
                    select="//*[@ids = $refid]/ancestor-or-self::section[1]/@ids"/>
                
                <xsl:choose>
                    <xsl:when test="$target">
                        <xref href="{fn:ditafilename(document-uri(/))}#{$topicid}">
                            <xsl:apply-templates/>
                        </xref>
                    </xsl:when>-->
                    <!-- Unknown target -->
                   <!-- <xsl:otherwise>
                        <xsl:message select="concat('WARNING: Unknown reference: ', @refuri)"/>
                        <xsl:value-of select="text()"/>
                    </xsl:otherwise>
                </xsl:choose>-->
            </xsl:when>
            <!-- external file reference -->
            <xsl:when test="contains(@refuri, '#')">
                <xref>
                    <xsl:attribute name="href">
                        <xsl:value-of select="concat(replace(@refuri,'#.*',''),'.dita#',replace(@refuri,'.*#',''))"/>
                    </xsl:attribute>
                    <xsl:apply-templates/>
                </xref>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Unknown reference: </xsl:text>
                    <xsl:apply-templates select="@*" mode="debug"/>
                    <xsl:text> text=</xsl:text>
                    <xsl:value-of select="text()"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="a">
        <xref>
            <xsl:attribute name="href">
                <xsl:value-of select="@href"/>
            </xsl:attribute>
            <xsl:value-of select="."/>
        </xref>
    </xsl:template>

    <xsl:template match="footnote_reference">
        <xsl:variable name="footnoteid" select="@refid"/>
        <xsl:choose>
            <xsl:when test="count(preceding::footnote_reference[@refid = $footnoteid]) = 0">
                <fn id="{@refid}">
                    <xsl:apply-templates select="//footnote[@ids = $footnoteid]" mode="footnoteref"
                    />
                </fn>
            </xsl:when>
            <xsl:otherwise>
                <xref href="#./{$footnoteid}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="footnote" mode="footnoteref">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="footnote"/>
    <xsl:template match="label"/>

    <xsl:template match="reference[@refname]">
        <xref href="{@refuri}" outputclass="reference-refname"><xsl:value-of select="@refname"/>:
            <xsl:apply-templates/></xref>
    </xsl:template>

    <!-- inlines -->

    <xsl:template match="strong">
        <b>
            <xsl:apply-templates/>
        </b>
    </xsl:template>

    <xsl:template match="emphasis">
        <i>
            <xsl:apply-templates/>
        </i>
    </xsl:template>

    <xsl:template match="literal_emphasis">
        <i>
            <codeph>
                <xsl:apply-templates/>
            </codeph>
        </i>
    </xsl:template>

    <xsl:template match="abbreviation">
        <keyword outputclass="abbreviation">
            <xsl:apply-templates/>
        </keyword>
    </xsl:template>

    <xsl:template match="acronym">
        <keyword outputclass="acronym">
            <xsl:apply-templates/>
        </keyword>
    </xsl:template>

    <xsl:template match="seealso">
        <xsl:choose>
            <xsl:when test="child::bullet_list">
                <xsl:apply-imports/>
            </xsl:when>
            <xsl:otherwise>
                <note>
                    <xsl:text>See also: </xsl:text>
                    <xsl:apply-templates select="paragraph"/>
                </note>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="subscript">
        <sub>
            <xsl:apply-templates/>
        </sub>
    </xsl:template>

    <xsl:template match="superscript">
        <sup>
            <xsl:apply-templates/>
        </sup>
    </xsl:template>

    <xsl:template match="inline">
        <ph outputclass="{@classes}">
            <xsl:apply-templates/>
        </ph>
    </xsl:template>

    <xsl:template match="desc_parameterlist"> (<xsl:apply-templates/>) </xsl:template>

    <xsl:template match="section/desc">
        <topic id="{generate-id()}">
            <title>
                <xsl:apply-templates select="desc_signature/desc_name" mode="title"/>
            </title>
            <shortdesc>
                <xsl:apply-templates select="desc_signature"/>
            </shortdesc>
            <body>
                <p/>
                <xsl:apply-templates select="*[not(self::desc_signature)]"/>
            </body>
        </topic>
    </xsl:template>

    <xsl:template match="plantuml">
        <fig>
            <image>
                <xsl:attribute name="href">
                    <xsl:value-of select="@link"/>
                </xsl:attribute>
            </image>
        </fig>
    </xsl:template>

    <xsl:template match="desc_sig_name">
        <parmname>
            <xsl:apply-templates/>
        </parmname>
    </xsl:template>

    <xsl:template match="desc_annotation">
        <i>
            <xsl:apply-templates/>
        </i>
    </xsl:template>

    <xsl:template match="desc_name" mode="title">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="desc_name">
        <b>
            <xsl:apply-templates/>
        </b>
    </xsl:template>

    <xsl:template match="desc_returns"> → <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="literal_block">
        <xsl:choose>
            <xsl:when test="contains(@language, 'default') or not(@language)">
                <pre>
                   <xsl:apply-templates/>
               </pre>
            </xsl:when>
            <xsl:otherwise>
                <codeblock>
                    <xsl:attribute name="outputclass" select="concat('language-', @language)"/>
                    <xsl:apply-templates/>
                </codeblock>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="literal[contains(@classes, 'py')]">
        <xsl:apply-imports/>
    </xsl:template>

    <xsl:template match="literal | title_reference">
        <codeph>
            <xsl:apply-templates/>
        </codeph>
    </xsl:template>

    <xsl:template match="literal_strong">
        <b>
            <codeph>
                <xsl:apply-templates/>
            </codeph>
        </b>
    </xsl:template>

    <xsl:template match="topic">
        <section>
            <title>
                <xsl:value-of select="title"/>
            </title>
            <xsl:apply-templates/>
        </section>
    </xsl:template>

    <xsl:template match="math_block">
        <xsl:variable name="count" select="count(preceding::math_block)"/>
        <xsl:variable name="filePath"
            select="concat(replace(@docname, '/', '_'), '_', $count + 1, '.mathml')"/>
        <mathml/> 
    </xsl:template>

    <xsl:template match="rubric">
        <p outputclass="rubric">
            <b>
                <xsl:apply-templates/>
            </b>
        </p>
    </xsl:template>

    <xsl:template
        match="substitution_reference | footer | citation | citation_reference | header | generated | system_message | transition | problematic | pending | compound | container | container | transition | raw | sidebar | version | meta | inheritance_diagram">
        <xsl:message>
            <xsl:value-of select="name(.)"/> : Not yet supported </xsl:message>
    </xsl:template>

    <!-- ignore these elemtents because handled otherwise -->
    <xsl:template match="target | substitution_definition | tabular_col_spec | index"/>

    <xsl:template match="@ids">
        <xsl:attribute name="id" select="tokenize(., '\s+')[1]"/>
    </xsl:template>

    <xsl:template match="autosummary_table">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="@*"/>

    <xsl:template match="@*" mode="debug">
        <xsl:value-of select="concat('@', name(.), '=', ., ' ')"/>
    </xsl:template>

    <xsl:template match="glossary">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- support GitHub section-detail block -->
    <xsl:template match="raw[starts-with(normalize-space(text()[1]),'&lt;details')]">
        <!-- remove all elements from raw block and replace special TM entity with character -->
        <xsl:variable name="sectiontitle" select="replace(
            replace(text(),
            '&lt;.*?&gt;',''),
            '&amp;trade;','™')"/>
        
        <xsl:choose>
            <xsl:when test="parent::section">
                <xsl:text disable-output-escaping="yes">&lt;section&gt;</xsl:text>
                <title>
                    <xsl:value-of select="$sectiontitle"/>
                </title>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text disable-output-escaping="yes">&lt;div class="wh_expand_btn collapsed"&gt;</xsl:text>
                <xsl:text disable-output-escaping="yes">&lt;div outputclass="wh_expand_btn collapsed"&gt;</xsl:text>
                <b>
                    <xsl:value-of select="$sectiontitle"/>
                </b>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <!-- github closing element -->
    <xsl:template match="raw[starts-with(normalize-space(text()[1]),'&lt;/details&gt;')]">
        <xsl:choose>
            <xsl:when test="parent::section">
                <xsl:text disable-output-escaping="yes">&lt;/section&gt;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text disable-output-escaping="yes">&lt;/div&gt;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ignore br in all combinations -->
    <!-- TBD: put a <p/> in here? -->
    <xsl:template match="raw[matches(text()[1], '^\s*&lt;\s*br\s*/*\s*&gt;\s*')]"/>

    <xsl:template match="doctest_block[@classes = 'doctest']">
        <xsl:apply-imports/>
    </xsl:template>

</xsl:stylesheet>
