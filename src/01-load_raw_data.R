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
options(scipen = 20) ### Credit to Hadley Wickham... otherwise large queries give errors.

# Directories -------------------------------------------------------------
cat("Checking for relevant directories... "); flush.console()

found_dirs <- list.dirs()
### "." included to satisfy list.dirs() format
dirs_needed <- c("./output", "./output/data", "./output/graphs", 
                 "./output/data/daily_airflow_mao",  
                 "./output/data/daily_airflow_mao/global",
                 "./output/data/daily_airflow_mao/usa",
                 "./output/data/nodes",
                 "./output/data/nodes/global", "./output/data/nodes/usa",
                 "./output/data/daily_airflow_T100_2019",
                 "./output/data/daily_airflow_T100_2019/usa",
                 "./data", "./data/JHU_data", "./Rds")
cat("Done.\n"); flush.console()
dirs_not_found <- dirs_needed[!dirs_needed %in% found_dirs]
if (length(dirs_not_found) > 0) {
  cat("Creating directories... "); flush.console()
  lapply(dirs_not_found, dir.create) %>% invisible ### Hide output.
  cat("Done.\n"); flush.console()
}

# BigQuery data -----------------------------------------------------------

#####
# Note: we are authenticating using Google & tidyverse API services.
# After running the commented-out code, the token will be saved to your machine.
# Make sure whatever email you use already has a BigQuery project configured.
# My @cmu.edu address, for example, did not allow the creation of projects,
# so I am using my personal gmail account.
#####

#bq_auth(
#  email = "your_email",
#  path = NULL,
#  scopes = c("https://www.googleapis.com/auth/bigquery",
#             "https://www.googleapis.com/auth/cloud-platform"),
#  cache = gargle::gargle_oauth_cache(),
#  use_oob = gargle::gargle_oob_default(),
#  token = NULL
#)
cat("Creating BigQuery connection... "); flush.console()
my_project_ID <- "c-19analysis" # if you are not me, you need to change this

con <- dbConnect(
  bigrquery::bigquery(),
  project = my_project_ID
)
cat("Done.\n"); flush.console() 
cat("Loading data from BigQuery... "); flush.console() 

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
cat("Done.\n"); flush.console()

# Local data --------------------------------------------------------------
cat("Loading local data and C19 data... "); flush.console()

if (!"us_pop_dta_raw.Rds" %in% list.files("Rds")){
  us_pop_dta_raw <- read_csv("data/co-est2019-alldata.csv")
  save_object(us_pop_dta_raw, "us_pop_dta_raw")
}

download.file(
  url = "https://github.com/CSSEGISandData/COVID-19/archive/master.zip",
  destfile = "data/JHU_data/JHU.zip"
)
unzip(zipfile = "data/JHU_data/JHU.zip", exdir = "data/JHU_data")

if (!"airport_codes_raw.Rds" %in% list.files("Rds")) {
  airport_codes_raw <- read_csv("data/monthly_air_flow/Airports_2010.csv")
  save_object(airport_codes_raw, "airport_codes_raw")
}

if (!"mao_dta_raw.Rds" %in% list.files("Rds")){
  mao_dta_raw <- read_csv("data/monthly_air_flow/Prediction_Monthly.csv")
  save_object(mao_dta_raw, "mao_dta_raw")
}

if (!"T100_raw.Rds" %in% list.files("Rds")){
  T100_raw <- read.csv("data/monthly_air_flow/T_100_2019.csv")
  save_object(T100_raw, "T100_raw")
}

cat("Done.\n"); flush.console()

# Web scraping ------------------------------------------------------------

cat("Web scraping... "); flush.console()

if (!"fips_table_raw.Rds" %in% list.files("Rds")){
  fips_url <- read_html(
    "https://en.wikipedia.org/wiki/List_of_United_States_FIPS_codes_by_county"
  ) %>%
    html_nodes("table")
  fips_table_raw <- html_table(fips_url, fill = TRUE)[[2]] ### 2nd by inspection.
  save_object(fips_table_raw, "fips_table_raw")
}

if (!"geocode_countries_raw.Rds" %in% list.files("Rds")){
  geocode_countries_raw <- read_html(
    "https://developers.google.com/public-data/docs/canonical/countries_csv"
  ) %>%
    html_nodes("table") %>%
    html_table(.) %>%
    .[[1]]
  save_object(geocode_countries_raw, "geocode_countries_raw")
}

if (!"geocode_states_raw.Rds" %in% list.files("Rds")){
  geocode_states_raw <- read_html(
    "https://www.latlong.net/category/states-236-14.html",
  ) %>%
    html_nodes("table") %>%
    html_table(., fill = TRUE) %>%
    .[[1]]
  save_object(geocode_states_raw, "geocode_states_raw")
}

cat("Done.\n"); flush.console()