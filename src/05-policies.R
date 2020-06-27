##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse policies data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

source("src/00-common.R")

# Load objects ------------------------------------------------------------

policy_dta_raw <- readRDS(here::here("RDS", "policy_dta_raw.Rds"))
pop_dta <- readRDS(here::here("RDS", "pop_dta.Rds"))

# Work --------------------------------------------------------------------

policy_dta <- policy_dta_raw %>%
  select(-c(
    "alpha_3_code",
    "confirmed_cases",
    "deaths"
  )) %>%
  mutate(
    sub_region_1 = NA, ### For left_join.
    sub_region_2 = NA ### For left_join.
  )

### Countries in pop_dta but not in policy_dta.
setdiff(unique(pop_dta$country_name), unique(policy_dta$country_name)) %>% sort

### Countries in policy_dta but not in pop_dta.
setdiff(unique(policy_dta$country_name), unique(pop_dta$country_name)) %>% sort

policy_dta$country_name[which(policy_dta$country_name == "Czech Republic")] <- "Czechia"
policy_dta$country_name[which(policy_dta$country_name == "Kyrgyz Republic")] <- "Kyrgyzstan"
policy_dta$country_name[which(policy_dta$country_name == "Slovak Republic")] <- "Slovakia"
policy_dta$country_name[which(policy_dta$country_name == "Myanmar")] <- "Burma"
policy_dta$country_name[which(policy_dta$country_name == "Macao")] <- "Macau"
policy_dta$country_name[which(policy_dta$country_name == "Gambia")] <- "The Gambia"
policy_dta$country_name[which(policy_dta$country_name == "Democratic Republic of Congo")] <- "Congo"

save_object(policy_dta, "policy_dta")
