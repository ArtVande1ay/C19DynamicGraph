##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse census data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

library(tidyverse)

source("src/00-common.R")

# Load objects ------------------------------------------------------------

country_pop_dta_raw <- readRDS(here::here("Rds", "country_pop_dta_raw.Rds"))
us_pop_dta_raw <- readRDS(here::here("Rds", "us_pop_dta_raw.Rds"))

# Work --------------------------------------------------------------------
cat("Preparing census data... "); flush.console()

country_pop_dta <- country_pop_dta_raw %>%
  filter(
    year == 2020,
  ) %>%
  mutate(
    sub_region_1 = NA,
    year = NULL 
  ) %>%
  dplyr::rename(
    pop = midyear_population
  ) %>%
  relocate(sub_region_1, .after = country_name)

country_pop_dta$country_name[which(country_pop_dta$country_name == "Korea, South")] <- "South Korea"
country_pop_dta$country_name[which(country_pop_dta$country_name == "Korea, North")] <- "North Korea"
country_pop_dta$country_name[which(country_pop_dta$country_name == "Bahamas, The")] <- "The Bahamas"
country_pop_dta$country_name[which(country_pop_dta$country_name == "Gambia, The")] <- "The Gambia"


us_pop_dta <- us_pop_dta_raw %>%
  select(
    STNAME,
    CTYNAME,
    POPESTIMATE2019
  ) %>%
  dplyr::rename(
    sub_region_1 = STNAME,
    sub_region_2 = CTYNAME,
    pop = POPESTIMATE2019
  ) %>%
  mutate(
    country_code = "US",
    .before = sub_region_1
  ) %>%
  mutate(
    country_name = "United States",
    .after = country_code
  )

us_pop_dta <- filter(us_pop_dta, sub_region_1 == sub_region_2)
us_pop_dta$sub_region_2 <- NULL

pop_dta <- rbind(us_pop_dta, country_pop_dta)
save_object(pop_dta, "pop_dta")
cat("Done.\n"); flush.console()