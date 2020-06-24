##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse geocoding data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

library(ggmap)

source("R/00-common.R")

# Load objects ------------------------------------------------------------

pop_dta <- readRDS(here::here("RDS", "pop_dta.Rds"))
geocode_countries_raw <- readRDS(here::here("Rds", "geocode_countries_raw.Rds"))
geocode_counties_raw <- readRDS(here::here("Rds", "geocode_counties_raw.Rds"))

# Work --------------------------------------------------------------------


geocode_countries <- geocode_countries_raw %>%
  dplyr::rename(
    lat = latitude,
    lon = longitude,
    country_code = country,
    country_name = name
  ) %>%
  mutate(
    sub_region_1 = NA,
    sub_region_2 = NA
  )

geocode_counties <-  geocode_counties_raw %>%
  dplyr::rename(
    lat = Latitude,
    lon = Longitude,
    sub_region_2 = `County [2]` # for left_join later
  ) %>%
  mutate(
    sub_region_1 = state.name[match(State, state.abb)],
    lat = as.numeric(substr(lat, 1, nchar(lat) - 1)), # remove angle
    lon = as.numeric(substr(lat, 1, nchar(lon) - 1)), # remove angle
    sub_region_2 = paste(sub_region_2, "County"),
    country_name = "United States",
    country_code = "US"
  ) %>%
  select(
    country_code,
    lat,
    lon,
    country_name,
    sub_region_1,
    sub_region_2,
  )

geocodes <- rbind(geocode_countries, geocode_counties)

full_names_pop_dta <- paste(
  ifelse(is.na(pop_dta$sub_region_2), "", pop_dta$sub_region_2),
  paste(
    ifelse(is.na(pop_dta$sub_region_1), "", pop_dta$sub_region_1),
    ifelse(is.na(pop_dta$country_name), "", pop_dta$country_name),
    sep = ", "
  ),
  sep = ", "
)

full_names_geocodes <- paste(
  ifelse(is.na(geocodes$sub_region_2), "", geocodes$sub_region_2),
  paste(
    ifelse(is.na(geocodes$sub_region_1), "", geocodes$sub_region_1),
    ifelse(is.na(geocodes$country_name), "", geocodes$country_name),
    sep = ", "
  ),
  sep = ", "
)

w_need_to_geocode <- which(!full_names_pop_dta %in% full_names_geocodes)
new_geocodes <- geocode(full_names_pop_dta[w_need_to_geocode])
new_geocodes_df <- cbind(
  new_geocodes,
  select(pop_dta[w_need_to_geocode, ], -pop)
) %>%
  select(country_code, lat, lon, country_name, sub_region_1, sub_region_2)


geocodes <- rbind(geocodes, new_geocodes_df)

geocodes$country_code <- NULL

save_object(geocodes, "geocodes")
