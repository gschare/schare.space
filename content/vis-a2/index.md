<style>
:root {
  --bg-light: white !important;
}
h1, h2, p, ul, ol, span, table { max-width: 45rem; margin-left: auto; margin-right: auto; }
h1 { font-size: revert; }
h2 { padding-right: 0; }
img, figure img, p img { max-width: 60rem; margin-left: auto; margin-right: auto; display: block; }
figcaption { text-align: center; }
table th { border-bottom: 1px solid black; }
table th + th { border-left: 1px solid black; padding-left: 0.5rem; padding-right: 0.5rem; }
table td + td { border-left: 1px solid black; }
table, th, td { border-collapse: collapse; }
</style>

# Assignment 2 | 6.C85 Vis & Society
[Carmel Schare (schare@mit.edu)]{.subtitle}
[21 Feb 2026 (3 late days used)]{.date}

## Transit-Oriented Development
I chose the [transit-oriented development (TOD) theme](https://vis-society.github.io/theme/transportation.html).

Transit-oriented development (TOD) is the strategy of building higher-density
housing and mixed-use developments centered around transit stations in order to
foster good quality of living: access to jobs, education, housing, and services,
all without requiring urban residents to own a car. TOD argues that, just as
shops tend to cluster in town centers and jobs in commercial districts, compact
housing should cluster around transit stations to provide mobility options to as
many people as possible and stimulate the economy of the area and neighboring
communities. Its skeptics tend to be concerned about the effect of upzoning and
increased density on the character of the neighborhood.

The difficulties of TOD include coordinating different stakeholders (including
local government, real estate developers, residents, business owners, and
transit agencies), strategically choosing locations for targeted development,
and obtaining funding for these necessarily large, complex, and expensive projects. 
The method is becoming increasingly popular.  I had the chance to FaceTime with
Redmond Councilmember Vivek Prakriya---the youngest councilmember in the
US---who just helped pass a transit-oriented development plan sponsored by major
tech companies.

In Massachusetts, the MBTA Communities Act requires all Metro Boston
municipalities served by the MBTA to upzone single-family housing to allow
multifamily housing near some rail rapid transit stations. [Critics have pointed
out](https://www.wbur.org/news/2024/03/22/mbta-communities-zoning-overstated-impact-luc-schuster)
that the law may be less effective than intended. Some municipalities were
non-compliant, which led to tensions and lawsuits between the city and state
governments.

## Questions
1. What are the demographics of the towns and cities in Greater Boston that
   resisted the MBTA Communities Act? Do they lean wealthier and whiter and with
   more single-family zoning?
2. Where are the areas of highest potential for TOD according to the 3 Vs: node
   value, place value, and market potential value? In particular, where is there a
   high disparity between existing transit connections and economic value?
3. How many rail stops are there are in each municipality? What does this
   correlate with?

## Dataset
We have three datasets have available to help answer these questions:

- Census
- MBTA (stops and lines)
- Redlining

The zoning and census data comes from MAPC's Zoning Atlas. It covers 101 Metro
Boston municipalities; for each one it gives the percentage of residential land
zoned exclusively for single-family housing, whether it is an MBTA Community,
census data from the 2010 Decennial US Census, including population,
distribution of age brackets and race/ethnicity categories, and income bracket
census data from the 2014–2018 American Community Survey.

We also have municipal boundaries from MassGIS, which will help relate the census data to the MBTA data.

The transit dataset includes stops and lines derived from MBTA's GTFS feed, converted to GeoJSON and processed to remove duplicates.

The redlining dataset contains spatial data labeling areas according to the
1935-1940 HOLC City Survey Files (from the National Archives). These historical
grades were used by real estate professionals to assess lending risk and are infamously racist.
The data is from the Mapping Inequality project at the University of Richmond.
We can use this to compare with current transit and zoning.

## Exploration
Before approaching the questions, I played around in Tableau to do some
sense-making of the data.

The most obvious initial thing to do, for me, was to use the GeoJSON data to plot the
municipalities and make sure they appeared correctly. Then I superimposed the
routes and stops. The result is busy, but mostly matches what I'd expect.

![ []{} ](img/tableau/geo.png)

The one surprise is that many cities far away from Boston have no
single-family-only zoning. My assumption (based on intuition that Boston is
surrounded mostly by suburbs made up predominantly of single-family homes) is
that they are in practice still mostly single-family housing, but with no areas
*solely* zoned for that. It is also possible that the entire municipality has
been upzoned but existing houses remain in place. Without more data we cannot
say for certain, so I'll let this question rest.

The next thing I thought to do is relate the municipality data to the MBTA stops
data and count how many stops there are per municipality.

As expected, the distribution is dramatic.

![ []{} ](img/tableau/stops_by_muni.png)

If we map it using the spatial data we can see how the transit stop density
decreases radially outward from Boston, the transit hub.

![ []{} ](img/tableau/stops_by_muni_geo.png)

An interesting aspect of visualization psychology emerges here. The bar chart I
just showed follows an exponential curve, but it is quite readable so there is
no reason to use a logarithmic scale. When mapping the same measure onto color,
however, it is much harder to tell the relative difference. For that reason I
experimented with with mapping the logarithm of the number of stops onto the
same color scale.

![ []{} ](img/tableau/stops_by_muni_log_geo.png)

I decided to create a small multiples chart to get a sense of how transit stop
density correlates with population.

![ []{} ](img/tableau/stops_by_pop.png)

This alerted me to the first and only problem I encountered with data quality.
The population is wrong! Salem doesn't have more people than Boston! At first I
wondered if this was just how censuses work---maybe they take a representative
sample instead of the actual population count---but after reviewing the
metadata, the source of the data on the US Decennial Census, and searching the
internet, I learned that this was definitely a mistake in the data. Then I
called my friend who confirmed it was not just me, and that the TAs are aware.
(Sometimes sanity-checking data means asking another human.)

So while we can't rely on using population directly, we might be able to *treat
it* (for the purposes of the assignment) as a representative sample, if we can
confirm that the proportions are realistic. We can assess the distribution of
income, race, and sex and compare them to common sense.

The income data comes in brackets, which makes it slightly awkward to work with
in Tableau. I made a pivot table along the income bracket fields and then used
that to create a stacked bar chart displaying the (binned) distributions for
each municipality.

![ []{} ](img/tableau/income_stacked.png)

This is a fairly reasonable distribution, with some municipalities having very
extreme distributions. A quick look confirms basic common sense: Cambridge is
wealthier than Boston, Winthrop is very poor, Dover is very rich. No surprises here.

When I tried to do the same pivot for race and sex categories, Tableau became
unresponsive. After many attempts to fix it, I gave up. This was the straw that
broke my back in terms of frustrations with Tableau. While the interaction
experience was positive and productive for exploration, the software was
sluggish and crashed so frequently as to be unusable.

In order to proceed I switched to Python, heavily assisted by Cursor. My
workflow involved iteratively looking at the visualizations it created and
instructing the agent what changes to make or which new visualizations to
generate, asking questions about data transformations, and inspecting the
analysis code to make tweaks as necessary.

With this new workflow I could return to the question of the sensibility of the proportionality of the demographic data.

I visualized the racial/ethnic breakdown of the population by municipality with another stacked bar chart.
(Note that this is a slice of the top 35 by population, so it does not include
all municipalities. This was to avoid taking up too much space or making the
chart too dense like it was in the Tableau visualizations.)

![ []{} ](img/zoning_population_by_ethnicity.png)

This seems basically plausible, just like the income. We can finish this
investigation by looking at the sex ratio, which should be basically balanced.

![ []{} ](img/zoning_population_by_gender.png)

Fun fact: Salem does indeed have a significant difference between male and female populations.

I believe this settles the question: we can use the demographic data as long as
we do it proportionally by municipality instead of absolutely. Note that I would
definitely not proceed with this clearly incorrect data in a real-world analysis.

## Investigation
Having gotten a sense of the data I found that some of my questions were
intractable because of the lack of relevant data in the datasets.

The datasets have no info about implementation or response to the MBTA
Communities act, so we cannot answer the first question directly. Instead we can
look at which municipalities are "MBTA Communities" and get a sense of how Metro
Boston would be impacted by the policy.

![ []{} ](img/mbta_communities.png)

MBTA Communities notably do not include Boston; the purpose of the designation
is to encourage development in areas that are served by the MBTA but less dense
and less well-connected than cities closer to the metropolitan center. The other
non-MBTA communities are Bolton, Hudson, and Milford---all municipalities not
connected to the MBTA, with small populations. This insight is important in a
non-flashy way. We don't have a very interesting visualization to show for
it---unless we follow the Don Norman approach and consider a simple list a
powerful representation. Consider this an "anti-visualization."

|Municipality|MBTA Community?|Population (2020 census)|
|:---:|:---:|:---:|
|Boston|No|675,647|
|Milford|No|30,379|
|Hudson|No|20,092|
|Bolton|No|5,665|

As for the second question, these datasets have no very good proxy for place
value or market potential value that we can use in identifying areas of high
potential for transit-oriented development. Ideally we would rely on economic
activity indicators (e.g.  business density, job growth, granular population
maps, historical trends, and of course housing density) and detailed transit
data (route ridership, node connections) and assess how those correlate with
each other. Then we would then generate visualizations identifying which areas
display high disparity between the variables, and recommend further
investigation into building transits nodes there. But the data is not available,
and the granularity---municipalities, rather than neighborhoods or blocks---is
too coarse to carry out precise analysis of station area value. 

Nevertheless I can gesture at the type of analysis we might perform by using
income data at the municipal scale, compared against MBTA maps and zoning data,
to make some very tentative claims about which cities would benefit from
transit-oriented development.

Basically the hypothesis goes that areas mostly zoned for single-family housing
only but which have a high number of existing transit connections are likely to
benefit from transit-oriented development.



We can also look into how those variables correlate with income and race.

TODO: 

Given that one of my questions became intractable, I'll throw you one more fun
piece of data investigation: how do the inner core cities (Boston, Cambridge,
Brookline, Somerville) compare to the rest of Metro Boston?

First, let us look within the inner core cities themselves.

![ []{} ](img/explore_inner_core_indicators.png)

This accords with intuition. However, it is hard to tell which cities are most
dense because Boston is so much larger than the other inner core cities. We can
use the spatial data to normalize over the area.

![ []{} ](img/explore_inner_core_rail_stops_per_area.png)

Now with a good sense of the inner core cities, let us compare to the rest of Metro Boston.

![ []{} ](img/explore_inner_core_aggregate.png)

![ []{} ](img/inner_core_ethnicity.png)



## Summary

The data on transit-oriented development cannot address other concerns I have
about the topic, such as the fact that the buildings erected are often 5-over-1s
and supremely ugly. (I simply do not wish for the new face of dynamic
transit-oriented American cities to look identical to Graduate Junction.)

I am strongly in favor of transit-oriented development. At various junctures in
my life I opted to live in walkable cities instead of the alternative. Where I
live now I am a few minutes walk from major bus lines and a 15 minute walk from
a major subway station. When I lived in Brooklyn, I was a 2 minute walk from a
major subway station. The difference between those experiences is dramatic, but
nothing compared to the experience of not having reasonable access to transit.
Where I grew up in the suburbs, the nearest bus stop was a 30 minute walk away.
I never once rode the bus until New Year's Eve a couple of months ago, when the
transit authority subsidized it with free service to discourage drunk driving.
With total sincerity I can say that this assignment gave me an appreciation for
the work that data analysts and transportation researchers do in helping build
more livable, more equitable, more sustainable, and more vibrant cities.