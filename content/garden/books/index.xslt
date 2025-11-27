<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" indent="yes"/>

<!-- key by which to group the books -->
<xsl:key name="booksByYear" match="book" use="substring(@date, 1, 4)" />

<xsl:template match="/">
<!-- provenance: garden/books.xml -->
<title>Books</title>
<nav class="secondary">
    <a href="/garden/links.html">links</a> &#183; <a href="/garden/flog/">flog</a>
</nav>
<h1>Books</h1>

<div id="tags">
<nav id="tag-select" class="secondary">
    <!-- it's definitely possible to automate this but for now the way it works
    is whenever I add a tag I have to list it here and then if I click on it,
    it filters to the ones with that tag. -->
    <a href="#reset">✕</a>
    <a href="#audiobook" class="audiobook">#audiobook</a>
</nav>
<div id="tag-list">
    <div id="reset"></div>
    <div id="audiobook"></div>
</div>
<style>
article:has(#audiobook:target) .cards .card:not(.audiobook) { display: none; }
article:has(#audiobook:target) nav#tag-select a.audiobook { font-weight: bold; }
nav#tag-select a:after { content: " "; }
div#tag-list { display: none; }
</style>
</div>

<style>
.cards {
    display: grid;
    /* fr = fractional unit */
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    justify-content: start;
    gap: 16px;
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
  /*max-height: 400px;*/
  object-fit: cover;
  border-radius: 4px;
  height: auto;
  max-height: 400px;
  width: auto;
  /*aspect-ratio: 4/5;*/
}

.cards img:hover:after {
  content: attr(title);
  font-size: 16pt;
  color: white;
  background: rgba(0,0,0,0.72);
  opacity: 1;
  margin: auto;
  text-align: center;
  padding: 5%;
}
</style>

<p>
    <span class="warning">
        <strong>Note:</strong>
        this is just a placeholder. I later on plan to write my thoughts on certain books I read…
   </span>
</p>

<xsl:apply-templates select="books" />
</xsl:template>

<xsl:template match="books">

    <!-- Meunchian method for grouping elements:
        https://stackoverflow.com/questions/2146648/how-to-apply-group-by-on-xslt-elements
        https://www.jenitennison.com/xslt/grouping/muenchian.xml
     -->
<xsl:for-each select="book[generate-id() = generate-id(key('booksByYear', substring(@date, 1, 4))[1])]">
    <section class="level2">
        <xsl:choose>
            <xsl:when test="substring(@date, 1, 4)">
                <h2>
                    <xsl:attribute name="id">
                        <xsl:value-of select="substring(@date, 1, 4)" />
                    </xsl:attribute>
                    <xsl:value-of select="substring(@date, 1, 4)" />
                </h2>
            </xsl:when>
            <xsl:otherwise>
                <h2>
                    <xsl:attribute name="id">in-progress</xsl:attribute>
                    <xsl:text>In Progress</xsl:text>
                </h2>
            </xsl:otherwise>
        </xsl:choose>

        <div class="cards">
            <!-- sort them? -->
            <xsl:apply-templates select="key('booksByYear', substring(@date, 1, 4))" />
        </div>
    </section>
</xsl:for-each>
</xsl:template>

<xsl:template match="book">
    <xsl:variable name="img-tag">
        <img loading="lazy">
            <xsl:attribute name="src">
                <xsl:value-of select="concat('/assets/img/garden/books/', @img)" />
            </xsl:attribute>
            <xsl:attribute name="id">
                <xsl:value-of select="substring-before(@img, '.')" />
            </xsl:attribute>
            <xsl:attribute name="alt">
                <xsl:value-of select="concat(@title, ' by ', @author)" />
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="concat(@title, ' by ', @author)" />
            </xsl:attribute>
        </img>
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

