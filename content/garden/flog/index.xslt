<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" indent="yes"/>

<!-- key by which to group the books -->
<xsl:key name="filmsByYear" match="film" use="substring(@date, 1, 4)" />

<xsl:template match="/">
<!-- provenance: garden/flog/index.xml -->
<title>Flog (Film Log)</title>
<nav class="secondary">
    <a href="/garden/books.html">books</a>
</nav>
<h1>Flog <!-- film log --></h1>

<p>See also: my <a href="https://letterboxd.com/gschare/">Letterboxd</a></p>

<style>
.cards {
    display: grid;
    /* fr = fractional unit */
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    justify-content: start;
    grid-auto-rows: 400px;
    gap: 16px;
}

@media screen and (min-width: 400px) and (max-width: 800px) {
    .cards {
        grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    }
}

@media screen and (max-width: 400px) {
    .cards {
        grid-template-columns: 1fr;
        text-align: center;
    }
}

.cards img {
  /*margin: revert;
  min-width: 10vw;
  max-width: 15vw;*/
    /*max-height: 400px;*/
  object-fit: cover;
  border-radius: 4px;
    /*overflow: hidden;*/
  height: 100%;
    /*aspect-ratio: 4/5;*/
}
</style>

<p><span class="warning"><strong>Note:</strong> this is just a
placeholder. I later on plan to write my thoughts on certain films I
watch…</span></p>

<xsl:apply-templates select="films" />
</xsl:template>

<xsl:template match="films">

    <!-- Meunchian method for grouping elements:
        https://stackoverflow.com/questions/2146648/how-to-apply-group-by-on-xslt-elements
        https://www.jenitennison.com/xslt/grouping/muenchian.xml
     -->

<xsl:for-each select="film[generate-id() = generate-id(key('filmsByYear', substring(@date, 1, 4))[1])]">
    <h2>
        <xsl:attribute name="id">
            <xsl:value-of select="substring(@date, 1, 4)" />
        </xsl:attribute>
        <xsl:value-of select="substring(@date, 1, 4)" />
    </h2>

    <div class="cards">
        <!-- sort them? -->
        <xsl:apply-templates select="key('filmsByYear', substring(@date, 1, 4))" />
    </div>
</xsl:for-each>
</xsl:template>

<xsl:template match="film">
    <img loading="lazy">
        <xsl:attribute name="src">
            <xsl:value-of select="@img" />
        </xsl:attribute>
        <xsl:attribute name="alt">
            <xsl:value-of select="concat(@title, ' (', @year, ') dir. ', @dir)" disable-output-escaping="yes" />
        </xsl:attribute>
        <xsl:attribute name="title">
            <xsl:value-of select="concat(@title, ' (', @year, ') dir. ', @dir)" disable-output-escaping="yes" />
        </xsl:attribute>
    </img>
</xsl:template>

</xsl:stylesheet>
