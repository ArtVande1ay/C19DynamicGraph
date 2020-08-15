##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse weather data
## Author: Filipp Shelobolin
##################################################

###
# *
# NOTE: This data not currently used. Previously integrated county data,
# however, due to lack of accurately tracking population movement between counties,
# we are just focusing on US States and countries.
# *
###

# Libraries ---------------------------------------------------------------

source("src/00-common.R")

# Load objects ------------------------------------------------------------

weather_dta_raw <- readRDS(here::here("Rds", "weather_dta_raw.Rds"))

# Work --------------------------------------------------------------------
cat("Preparing weather data... "); flush.console()
weather_dta <- weather_dta_raw %>%
  dplyr::rename(
    FIPS = county_fips_code,
  ) %>%
  mutate(
    country = NULL
  )

save_object(weather_dta, "weather_dta")
cat("Done.\n"); flush.console()

