<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" indent="yes"/>

<!-- TODO: a way to mark rewatches -->

<!-- key by which to group the books -->
<xsl:key name="filmsByYear" match="film" use="substring(@date, 1, 4)" />

<xsl:template match="/">
<!-- provenance: garden/flog/index.xml -->
<title>Flog (Film Log)</title>
<nav class="secondary">
    <a href="/garden/books/">books</a>
    · <a href="/garden/film/"><u>film</u></a>
</nav>
<h1>Flog <!-- film log --></h1>

<p>See also: my <a href="https://letterboxd.com/gschare/">Letterboxd</a></p>

<p><span class="warning"><strong>Note:</strong> this is just a
placeholder. I later on plan to write my thoughts on certain films I
watch…</span></p>

<div id="tags">
<nav id="tag-select" class="secondary">
    <!-- it's definitely possible to automate this but for now the way it works
    is whenever I add a tag I have to list it here and then if I click on it,
    it filters to the ones with that tag. -->
    <a href="#reset">✕</a>
    <a href="#cinema" class="cinema" title="watched in theaters!">#cinema</a>
    <a href="#horror-tuesdays" class="horror-tuesdays">#horror-tuesdays</a>
</nav>
<div id="tag-list">
    <div id="reset"></div>
    <div id="cinema"></div>
    <div id="horror-tuesdays"></div>
</div>
<style>
article:has(#cinema:target) .cards .card:not(.cinema) { display: none; }
article:has(#cinema:target) nav#tag-select a.cinema { font-weight: bold; }
article:has(#horror-tuesdays:target) .cards .card:not(.horror-tuesdays) { display: none; }
article:has(#horror-tuesdays:target) nav#tag-select a.horror-tuesdays { font-weight: bold; }
nav#tag-select a:after { content: " "; }
div#tag-list { display: none; }
</style>
</div>

<style>
.cards {
    display: grid;
    /* fr = fractional unit */
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    gap: 16px;
    justify-content: start;
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
  object-fit: cover;
  border-radius: 4px;
  width: 100%;
  height: auto
  /*aspect-ratio: 2/3;*/
}

h2 {
    border-bottom: 2px solid var(--fg-light);
    margin: 16px auto 8px;
    padding: 16px 0 4px 0;
    width: 100%;
    position: sticky;
    top: 0;
    font-size: 32pt;
    background-color: var(--bg-light);
    z-index: 10;
}

.dark-mode h2 {
    border-bottom: 2px solid var(--fg-dark);
    background-color: var(--bg-dark);
}

@media screen and (max-width: 800px) {
    h2 {
        text-align: center;
    }
}
</style>

<xsl:apply-templates select="films" />
</xsl:template>

<xsl:template match="films">

    <!-- Meunchian method for grouping elements:
        https://stackoverflow.com/questions/2146648/how-to-apply-group-by-on-xslt-elements
        https://www.jenitennison.com/xslt/grouping/muenchian.xml
     -->

<xsl:for-each select="film[generate-id() = generate-id(key('filmsByYear', substring(@date, 1, 4))[1])]">
    <section class="level2">
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
    </section>
</xsl:for-each>
</xsl:template>

<xsl:template match="film">
    <xsl:variable name="img-tag">
        <img loading="lazy" src="{@img}">
            <xsl:attribute name="alt">
                <xsl:value-of select="concat(@title, ' (', @year, ') dir. ', @dir)" disable-output-escaping="yes" />
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="concat(@title, ' (', @year, ') dir. ', @dir)" disable-output-escaping="yes" />
            </xsl:attribute>
        </img>
        <xsl:text>
        </xsl:text>
    </xsl:variable>
    <div>
        <xsl:attribute name="class">
            <xsl:text>card </xsl:text>
            <xsl:value-of select="@tags"/>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="@link">
                <a href="{@link}">
                    <xsl:copy-of select="$img-tag" />
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$img-tag" />
            </xsl:otherwise>
        </xsl:choose>
    </div>
</xsl:template>

</xsl:stylesheet>

