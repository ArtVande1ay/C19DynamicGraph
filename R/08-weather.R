##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse weather data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

source("R/00-common.R")

# Load objects ------------------------------------------------------------

weather_dta_raw <- readRDS(here::here("Rds", "weather_dta_raw.Rds"))

# Work --------------------------------------------------------------------

weather_dta <- weather_dta_raw %>%
  dplyr::rename(
    FIPS = county_fips_code,
  ) %>%
  mutate(
    country = NULL ### Not needed.
  )

save_object(weather_dta, "weather_dta")