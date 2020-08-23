##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse mobility data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

source("src/00-common.R")

# Load objects ------------------------------------------------------------

pop_dta <- readRDS(here::here("Rds", "pop_dta.Rds"))
mobility_dta_raw <- readRDS(here::here("Rds", "mobility_dta_raw.Rds"))

# Work --------------------------------------------------------------------
cat("Preparing Google mobility data... "); flush.console()
mobility_dta <- mobility_dta_raw %>%
  filter(is.na(sub_region_2)) %>%
  dplyr::rename(
    country_name = country_region
  ) %>%
  mutate(
    country_region_code = NULL
  ) %>%
  select(
    country_name,
    sub_region_1,
    date,
    retail_and_recreation_percent_change_from_baseline,
    grocery_and_pharmacy_percent_change_from_baseline,
    parks_percent_change_from_baseline,
    transit_stations_percent_change_from_baseline,
    workplaces_percent_change_from_baseline,
    residential_percent_change_from_baseline
  )

w_sub_region_1_not_us <- which(
  (mobility_dta$country_name != "United States") & (complete.cases(mobility_dta$sub_region_1))
)

### Don't have any granularity of data for non-US countries.
mobility_dta <- mobility_dta[-w_sub_region_1_not_us, ]

mobility_dta <- mobility_dta %>%
  distinct(country_name, sub_region_1, date)

# Analysis of missing data ------------------------------------------------

### Countries in pop_dta but not in mobility_dta (can't fix)
setdiff(unique(pop_dta$country_name), unique(mobility_dta$country_name))

### Countries in mobility_dta but not in pop_dta (can fix if name issue)
setdiff(unique(mobility_dta$country_name), unique(pop_dta$country_name))

mobility_dta$country_name[which(mobility_dta$country_name == "Côte d'Ivoire")] <- "Cote d'Ivoire"
mobility_dta$country_name[which(mobility_dta$country_name == "Myanmar (Burma)")] <- "Burma"

### Sub_region_1 in pop_dta but not in mobility_dta (can't fix)
setdiff(unique(pop_dta$sub_region_1), unique(mobility_dta$sub_region_1))

### Sub_region_1 in mobility_dta but not in pop_dta (can fix if name issue)
setdiff(unique(mobility_dta$sub_region_1), unique(pop_dta$sub_region_1))

### Number of countries in mobility_dta
mobility_dta$country_name %>%
  unique() %>%
  length()

### Number of countries in pop_dta
pop_dta$country_name %>%
  unique() %>%
  length()

save_object(mobility_dta, "mobility_dta")
cat("Done.\n"); flush.console()