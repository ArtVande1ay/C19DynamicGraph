##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse geocoding data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

library(ggmap)

source("src/00-common.R")

if ("geocodes.Rds" %in% list.files("Rds")) {
  stop_quietly()
}

# Load objects ------------------------------------------------------------

pop_dta <- readRDS(here::here("Rds", "pop_dta.Rds"))
geocode_countries_raw <- readRDS(here::here("Rds", "geocode_countries_raw.Rds"))
geocode_states_raw <- readRDS(here::here("Rds", "geocode_states_raw.Rds"))

# Google API key ----------------------------------------------------------
### Follow instructions here to get an API key:
### https://developers.google.com/maps/documentation/geocoding/get-api-key
### write=TRUE will save key to your .Renviron
# register_google(key="your_key", write=TRUE)

# Work --------------------------------------------------------------------
cat("Geocoding... "); flush.console()
geocode_countries <- geocode_countries_raw %>%
  dplyr::rename(
    lat = latitude,
    lon = longitude,
    country_code = country,
    country_name = name
  ) %>%
  mutate(
    sub_region_1 = NA
  )

geocode_states <- geocode_states_raw %>%
  rename(
    sub_region_1 = `Place Name`,
    lat = Latitude,
    lon = Longitude
  ) %>% mutate(., country_code = rep("US", nrow(.)),
         lat = lat,
         lon = lon, 
         country_name = rep("United States", nrow(.)),
         sub_region_1 = sub_region_1)

geocode_states$sub_region_1 <- geocode_states$sub_region_1 %>%
  strsplit(",") %>%
  lapply(., function(x) x[1]) %>%
  unlist

geocodes <- rbind(geocode_countries, geocode_states)

full_names_pop_dta <- paste(
    ifelse(is.na(pop_dta$sub_region_1), "", pop_dta$sub_region_1),
    ifelse(is.na(pop_dta$country_name), "", pop_dta$country_name),
    sep = ", "
  )

full_names_geocodes <- paste(
    ifelse(is.na(geocodes$sub_region_1), "", geocodes$sub_region_1),
    ifelse(is.na(geocodes$country_name), "", geocodes$country_name),
    sep = ", "
)

w_need_to_geocode <- which(!full_names_pop_dta %in% full_names_geocodes)
new_geocodes <- geocode(full_names_pop_dta[w_need_to_geocode])
new_geocodes_df <- cbind(
  new_geocodes,
  select(pop_dta[w_need_to_geocode, ], -pop)
) %>%
  select(country_code, lat, lon, country_name, sub_region_1)


geocodes <- rbind(geocodes, new_geocodes_df)

geocodes$country_code <- NULL

save_object(geocodes, "geocodes")
cat("Done.\n"); flush.console()