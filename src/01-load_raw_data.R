##################################################
## Project: C19 dynamic graph analysis
## Script purpose: load all raw data sources and save to .Rds files
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

library(httr)
library(rvest)
library(jsonlite)
library(bigrquery)
library(DBI)

source("src/00-common.R")

# Directories -------------------------------------------------------------
### Make sure necessary directories present before downloading data.

found_dirs <- list.dirs()
### "." included to satisfy list.dirs() format
dirs_needed <- c("./output", "./output/data", "./output/graphs", 
                 "./output/data/daily_airflow_mao",  "./output/data/nodes",
                 "./output/data/daily_airflow_T100_2019",
                 "./output/data/daily_airflow_T100_2020",
                 "./data", "./data/JHU_data", "./Rds")
dirs_not_found <- dirs_needed[!dirs_needed %in% found_dirs]
lapply(dirs_not_found, dir.create) %>% invisible ### Hide output.

# BigQuery data -----------------------------------------------------------

#####
# Note: we are authenticating using Google & tidyverse API services.
# After running the commented-out code, the token will be saved to your machine.
# Make sure whatever email you use already has a BigQuery project configured.
# My @cmu.edu address, for example, did not allow the creation of projects,
# so I am using my personal gmail account.
#####

#bq_auth(
#  email = "fshelobolin@gmail.com",
#  path = NULL,
#  scopes = c("https://www.googleapis.com/auth/bigquery",
#             "https://www.googleapis.com/auth/cloud-platform"),
#  cache = gargle::gargle_oauth_cache(),
#  use_oob = gargle::gargle_oob_default(),
#  token = NULL
# )

my_project_ID <- "c-19analysis" # if you are not me, you need to change this

con <- dbConnect(
  bigrquery::bigquery(),
  project = my_project_ID
)

country_census_sql <- "SELECT * FROM `bigquery-public-data.census_bureau_international.midyear_population`"
country_pop_dta_raw <- dbGetQuery(con, country_census_sql)
save_object(country_pop_dta_raw, "country_pop_dta_raw")

mobility_sql <- "SELECT * FROM `bigquery-public-data.covid19_google_mobility.mobility_report`"
mobility_dta_raw <- dbGetQuery(con, mobility_sql)
save_object(mobility_dta_raw, "mobility_dta_raw")

policy_sql <- "SELECT * FROM `bigquery-public-data.covid19_govt_response.oxford_policy_tracker`"
policy_dta_raw <- dbGetQuery(con, policy_sql) %>% data.frame(.)
save_object(policy_dta_raw, "policy_dta_raw")

weather_sql <- "SELECT * FROM `bigquery-public-data.covid19_weathersource_com.county_day_history`"
weather_dta_raw <- dbGetQuery(con, weather_sql)
save_object(weather_dta_raw, "weather_dta_raw")

# Local data --------------------------------------------------------------

us_pop_dta_raw <- read_csv("data/co-est2019-alldata.csv")
save_object(us_pop_dta_raw, "us_pop_dta_raw")

download.file(
  url = "https://github.com/CSSEGISandData/COVID-19/archive/master.zip",
  destfile = "data/JHU_data/JHU.zip"
)
unzip(zipfile = "data/JHU_data/JHU.zip", exdir = "data/JHU_data")

airport_codes_raw <- read_csv("data/monthly_air_flow/Airports_2010.csv")
save_object(airport_codes_raw, "airport_codes_raw")

air_dta_raw <- read_csv("data/monthly_air_flow/Prediction_Monthly.csv")
save_object(air_dta_raw, "air_dta_raw")

T100_2019_raw <- read.csv("data/monthly_air_flow/T_100_2019.csv")
save_object(T100_2019_raw, "T100_2019_raw")

T100_2020_raw <- read.csv("data/monthly_air_flow/T_100_2020.csv")
save_object(T100_2020_raw, "T100_2020_raw")

# Web scraping ------------------------------------------------------------

fips_url <- read_html(
  "https://en.wikipedia.org/wiki/List_of_United_States_FIPS_codes_by_county"
) %>%
  html_nodes("table")
fips_table_raw <- html_table(fips_url, fill = TRUE)[[2]] ### 2nd by inspection.
save_object(fips_table_raw, "fips_table_raw")

geocode_countries_raw <- read_html(
  "https://developers.google.com/public-data/docs/canonical/countries_csv"
) %>%
  html_nodes("table") %>%
  html_table(.) %>%
  .[[1]]
save_object(geocode_countries_raw, "geocode_countries_raw")

geocode_counties_raw <- read_html(
  "https://en.wikipedia.org/wiki/User:Michael_J/County_table"
) %>%
  html_nodes("table") %>%
  html_table(.) %>%
  .[[1]]
save_object(geocode_counties_raw, "geocode_counties_raw")
