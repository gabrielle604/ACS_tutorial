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
