## Part 1: The American Community Survey, R, and tidycensus

install.packages(c("tidycensus", "tidyverse"))

install.packages(c("mapview", "plotly", "ggiraph", "survey", "survyr"))

# census_api_key("YOUR KEY GOES HERE")
# census_api_key("236521509424fe73f0f4bc383e04ef99d26e9279", install = TRUE)

## Start running the code here
library(tidycensus)

median_income <- get_acs(
  geography = "county",
  variables = "B19013_001",
  year = 2021
)

median_income
# GEOID is like a FIPS code
# MOE = margin of error around that estimate (for census is at 90%)

# 1-year ACS data are more current
# but are only available for geographies of population 65,000 and greater

# Access 1-year ACS data with the argument survey = "acs1"; defaults to "acs5"

median_income_1yr <- get_acs(
  geography = "county",
  variables = "B19013_001",
  year = 2021,
  survey = "acs1"
)

# First characters before the underscore represent the table name
# Variable_specific data point
# Table parameter can be used to obtain all related variables in a "table" at once

income_table <- get_acs(
  geography = "county", 
  table = "B19001",
  year = 2021
)

income_table

# Querying by state
mn_income <- get_acs(
  geography = "county", 
  variables = "B19013_001", 
  state = "MN",
  year = 2021
)

mn_income

# Searching for variables
# Tens of thousands of variables in the ACS

# To search for variables, use the "load_variables()" function along with a year 
## and dataset
# The "View()" function in RStudio allows for interactive browsing and filtering

vars <- load_variables(2021, "acs5")
View(vars)

# Available ACS datasets in tidycensus
## Detailed Tables
## Data Profile (add "/profile" for variable lookup)
## Subject Tables (add "/subject")
## Comparison Profile (add "/cprofile")
## Supplemental Estimates (use "acsse")
## Migration Flows (access with get_flows())

# The tidy, or long-form data
# The default data structure returned by tidycensus is "tidy" or long-form data, 
## with variables by geography stacked by row

age_sex_table <- get_acs(
  geography = "state", 
  table = "B01001", 
  year = 2021,
  survey = "acs1",
)

# Showing ^ Alabama for a given variable

# Wide-form: spreads the data
# The argument output = "wide" spreads Census variables across the columns, 
## returning one row per geographic unit (state, or state equivalent) and one 
## column per variable

age_sex_table_wide <- get_acs(
  geography = "state", 
  table = "B01001", 
  year = 2021,
  survey = "acs1",
  output = "wide"
)

# Using named vectors of variables
## but there are MANY variables that have the same name

# Replacing with a custom name
## Census variables can be hard to remember; using a named vector to request 
### variables will replace the Census IDs with a custom input
## In long form, these custom inputs will populate the variable column; in 
### wide form, they will replace the column names

ca_education <- get_acs(
  geography = "county",
  state = "CA",
  variables = c(percent_high_school = "DP02_0062P",
                percent_bachelors = "DP02_0065P",
                percent_graduate = "DP02_0066P"),
  year = 2021
)

# Part 2: Analyzing and visualizing ACS data
## tibble: representation of rectangular datasets

library(tidyverse)
arrange(median_income, estimate)
# "estimate" is the column I want to use to sort the data
# ascending order (default) of median income

arrange(median_income, desc(estimate))
# descending order 

# Remove Puerto Rico from the median income dataset
income_states_dc <- filter(median_income, !str_detect(NAME, "Puerto Rico"))
arrange(income_states_dc, estimate)

# Group-wise Census Data Analysis
## The group_by() and summarize() functions in dplyr are used to implement the 
## split-apply-combine method of data analysis

highest_incomes <- median_income %>%
  separate(NAME, into = c("county", "state"), sep = ", ") %>%
  group_by(state) %>%
  filter(estimate == max(estimate))

# The default "tidy" format returned by tidycensus is designed to work well
## with group-wise Census data analysis workflows

# Visualizing ACS estimates
## As opposed to decennial US Census data, ACS estimates include information on 
## uncertainty, represented by the margin of error in the moe column
## This means that in some cases, visualization of estimates without reference to 
## the margin of error can be misleading
## Walkthrough: building a margin of error visualization with ggplot2

md_rent <- get_acs(
  geography = "county",
  variables = "B25031_001",
  state = "MD",
  year = 2021
)

# A basic plot
## To visualize a dataset with ggplot2, we define an aesthetic and a geom

ggplot(md_rent, aes(x = estimate, y = NAME)) + 
  geom_point()

# Problems with the plot:
## The data are not sorted by value, making comparisons difficult
## The axis and tick labels are not intuitive
## The Y-axis labels contain repetitive information (" County, Maryland")
## We've made no attempt to customize the styling

# "reorder" to sort counties by their estimates

md_plot <- ggplot(md_rent, aes(x = estimate, 
                               y = reorder(NAME, estimate))) +
  geom_point(color = "darkred", size = 2)

md_plot

# Cleaning up tick-labels
## using a combination of functions in the scales package and custom-defined 
## functions, tick labels can be formatted any way you want

library(scales)

md_plot <- md_plot + 
  scale_x_continuous(labels = label_dollar()) +
  scale_y_discrete(labels = function(x) str_remove(x, " County, Maryland|, Maryland"))

md_plot

# this is saying: for every label x, remove county, maryland, or maryland
# plus, labeling units: median gross dollars

md_plot <- md_plot + 
  labs(title = "Median gross rent, 2017-2021 ACS",
       subtitle = "Counties in Maryland",
       caption = "Data acquired with R and tidycensus",
       x = "ACS estimate",
       y = "") + 
  theme_minimal(base_size = 12)

md_plot

# this can be misleading, because the dot isn't taking into account/visualizing 
## the margin of error (moe)

md_rent %>%
  arrange(desc(estimate)) %>%
  slice(5:9)

# How to visualize uncertainty in an intuitive way?

md_plot_errorbar <- ggplot(md_rent, aes(x = estimate, 
                                        y = reorder(NAME, estimate))) + 
  geom_errorbar(aes(xmin = estimate - moe, xmax = estimate + moe),
                width = 0.5, linewidth = 0.5) +
  geom_point(color = "darkred", size = 2) + 
  scale_x_continuous(labels = label_dollar()) + 
  scale_y_discrete(labels = function(x) str_remove(x, " County, Maryland|, Maryland")) + 
  labs(title = "Median gross rent, 2017-2021 ACS",
       subtitle = "Counties in Maryland",
       caption = "Data acquired with R and tidycensus. Error bars represent margin of error around estimates.",
       x = "ACS estimate",
       y = "") + 
  theme_minimal(base_size = 12)

md_plot_errorbar

# Making Plots Interactive
# think: gapminder hans rosling interactive bubbles
## Quick interactivity with ggplotly()
## The plotly R package is an interface to the Plotly JavaScript library for 
## full-featured interactive plotting
## Resource: _Interactive web-based data visualization with R, plotly, and Shiny
## ggplotly() automatically (and intelligently) converts ggplot2 graphics to 
## interactive charts

library(plotly)
ggplotly(md_plot_errorbar, tooltip = "x")
# use your cursor on the "viewer" of the plot to zoom in and out!

# Interactivity with ggiraph
# ggiraph: Alternative approach for making ggplot2 graphics interactive
## Includes *_interactive() versions of ggplot2 geoms that can bring chart elements to life
## Next week: we'll use ggiraph for interactive mapping!

# ggiraph example: 

library(ggiraph)
md_plot_ggiraph <- ggplot(md_rent, aes(x = estimate, 
                                       y = reorder(NAME, estimate),
                                       tooltip = estimate,
                                       data_id = GEOID)) +
  geom_errorbar(aes(xmin = estimate - moe, xmax = estimate + moe), 
                width = 0.5, size = 0.5) + 
  geom_point_interactive(color = "darkred", size = 2) +
  scale_x_continuous(labels = label_dollar()) + 
  scale_y_discrete(labels = function(x) str_remove(x, " County, Maryland|, Maryland")) + 
  labs(title = "Median gross rent, 2017-2021 ACS",
       subtitle = "Counties in Maryland",
       caption = "Data acquired with R and tidycensus. Error bars represent margin of error around estimates.",
       x = "ACS estimate",
       y = "") + 
  theme_minimal(base_size = 12)
girafe(ggobj = md_plot_ggiraph) %>%
  girafe_options(opts_hover(css = "fill:cyan;"))

# To save an interactive plot to a standalone HTML file for display on your 
## website, use the saveWidget() function in the htmlwidgets package

library(htmlwidgets)
plotly_plot <- ggplotly(md_plot_errorbar, tooltip = "x")
saveWidget(plotly_plot, file = "md_plotly.html")

# Part 3: Working with ACS microdata
## Using microdata in tidycensus

# Basic usage of get_pums()
## get_pums() requires specifying one or more variables and the state for which 
## you'd like to request data. state = 'all' can get data for the entire USA, 
## but it takes a while!

# The function defaults to the 5-year ACS with survey = "acs5"; 1-year ACS data 
## is available with survey = "acs1".

# The default year is 2021 in the latest version of tidycensus; data are 
## available back to 2005 (1-year ACS) and 2005-2009 (5-year ACS). 2020 1-year 
## data are not available.

# Grab data for Hawaii, age, household type, sex; using the 1 year ACS

library(tidycensus)
hi_pums <- get_pums(
  variables = c("SEX", "AGEP", "HHT"),
  state = "HI",
  survey = "acs1",
  year = 2021
)

# Some columns are returned by default:
## Household ID/serial number
## Gives you people organized into households; can do family level analyses
# a household of female age 32, male age 31, male age 12, male age 9, female age 2

# this household of 5 with this structure (2 adults, 3 children); roughly 
## representative of 134 households in Hawaii

# woman, age 32 in this type of household represents 133 other women like her in Hawaii

# Understanding default data from get_pums()
## get_pums() returns some technical variables by default without the user needing to request them specifically. These include:
  
# SERIALNO: a serial number that uniquely identifies households in the sample;
# SPORDER: the order of the person in the household; when combined with SERIALNO, uniquely identifies a person;
# WGTP: the household weight;
# PWGTP: the person weight

# weights allow us to take population level data and make inferences

# Specific question: How many people are age 39 approximately in Hawaii??

hi_age_39 <- filter(hi_pums, AGEP == 39)
print(sum(hi_pums$PWGTP))
## [1] 1441553
print(sum(hi_age_39$PWGTP))
## [1] 17381

# Are these estimates accurate?
## PUMS weights are calibrated to population and household totals, so larger 
## tabulations should align with published estimates

get_acs("state", "B01003_001", state = "HI", survey = "acs1", year = 2021)

# Smaller tabulations will be characterized by more uncertainty, and may deviate 
## from published estimates

# how to calculate the error of the number of 39 year olds in Hawaii

# Workflows with PUMS data

View(pums_variables)
# detailed info about all the variables in the pums; browse!
# variable code used to "fetch" data

# The pums_variables dataset is your one-stop shop for browsing variables in the 
## ACS PUMS

# It is a long-form dataset that organizes specific value codes by variable so 
## you know what you can get. You'll use information in the var_code column to 
## fetch variables, but pay attention to the var_label, val_code, val_label, and 
## data_type columns

# Recoding PUMS variables
## The recode = TRUE argument in get_pums() appends recoded columns to your 
## returned dataset based on information available in pums_variables

hi_pums_recoded <- get_pums(
  variables = c("SEX", "AGEP", "HHT"),
  state = "HI",
  survey = "acs1",
  year = 2021,
  recode = TRUE
)

hi_pums_recoded

# Using variable filters
# PUMS datasets - especially from the 5-year ACS - can get quite large. The 
## variables_filter argument can return a subset of data from the API, reducing 
## long download times

hi_pums_filtered <- get_pums(
  variables = c("SEX", "AGEP", "HHT"),
  state = "HI",
  survey = "acs5",
  variables_filter = list(
    SEX = 2,
    AGEP = 30:49
  ),
  year = 2021
)

hi_pums_filtered

# Public Use Microdata Areas (PUMAs)
## What is a PUMA?

## Public Use Microdata Areas (PUMAs) are the smallest available geographies at 
## which records are identifiable in the PUMS datasets

## PUMAs are redrawn with each decennial US Census, and typically are home to 
## 100,000-200,000 people. The 2021 ACS uses 2010 PUMAs; the 2022 ACS will align
## with the new 2020 PUMAs

## In large cities, a PUMA will represent a collection of nearby neighborhoods; 
## in rural areas, it might represent several counties across a large area of a state

## Let's preview some of next week's spatial tools to understand PUMA geography in Hawaii

library(tigris)
library(mapview)
options(tigris_use_cache = TRUE)
# Get the latest version of 2010 PUMAs
hi_pumas <- pumas(state = "HI", cb = TRUE, year = 2019)
hi_puma_map <- mapview(hi_pumas)

hi_puma_map


# Working with PUMAs in PUMS data

## To get PUMA information in your output data, use the variable code PUMA

hi_age_by_puma <- get_pums(
  variables = c("PUMA", "AGEP"),
  state = "HI",
  survey = "acs5"
)

hi_age_by_puma

# Handling uncertainty in tabulated PUMS estimates

# Uncertainty in PUMS data
## PUMS data represent a smaller sample than the regular ACS, so understanding 
## error around tabulated estimates is critical

## The Census Bureau recommends using successive difference replication to 
## calculate standard errors, and provides replicate weights to do this

## tidycensus includes tools to help you get replicate weights and format your 
## data for appropriate survey-weighted analysis

# Getting replicate weights
## We can acquire either housing or person replicate weights with the rep_weights argument

hi_pums_replicate <- get_pums(
  variables = c("AGEP", "PUMA"),
  state = "HI",
  survey = "acs1",
  year = 2021,
  rep_weights = "person"
)


hi_pums_replicate


# Handling complex survey samples

## tidycensus links to the survey and srvyr packages for managing PUMS data as 
## complex survey samples

## The to_survey() function will format your data with replicate weights for 
## correct survey-weighted estimation

install.packages("srvyr")
library(srvyr)
hi_survey <- to_survey(
  hi_pums_replicate,
  type = "person"
)
class(hi_survey)

# Survey-weighted tabulations
## srvyr conveniently links R's survey infrastructure to familiar tidyverse-style workflows

## Standard errors can be multiplied by 1.645 to get familiar 90% confidence level margins of error

library(srvyr)
hi_survey %>%
  filter(AGEP == 39) %>%
  survey_count() %>%
  mutate(n_moe = n_se * 1.645)

# Group-wise survey data analysis
## A familiar group-wise tidyverse workflow can be applied correctly by srvyr 
## for the calculation of medians and other summary statistics

hi_survey %>%
  group_by(PUMA) %>%
  summarize(median_age = survey_median(AGEP)) %>%
  mutate(median_age_moe = median_age_se * 1.645)

# Checking our answers
## Tabulated median ages are not identical to published estimates, but are 
## very close

## Use published estimates if available; use PUMS data to generate estimates 
## that aren't available in the published tables

hi_age_puma <- get_acs(
  geography = "puma",
  variables = "B01002_001",
  state = "HI",
  year = 2021,
  survey = "acs1"
)

hi_age_puma
# not yet, maybe now?
