##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse passenger flow data from Mao paper
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

source("R/00-common.R")

# Load objects ------------------------------------------------------------

airport_codes <- readRDS(here::here("Rds", "airport_codes.Rds"))
air_dta <- readRDS(here::here("Rds", "air_dta_raw.Rds"))

# Work --------------------------------------------------------------------

air_dta$date <- paste(air_dta$Month, "-1-2020", sep = "") %>%
  as.Date(format = "%m-%d-%Y")

air_dta$Month <- NULL
air_dta$lower <- NULL
air_dta$upper <- NULL

air_dta_origin_country_info <- airport_country_matcher(air_dta$Origin, "Origin", 
                                                       airport_codes)
air_dta <- cbind(air_dta, air_dta_origin_country_info)
air_dta <- air_dta[complete.cases(air_dta$origin_country_name), ]

air_dta_dest_country_info <- airport_country_matcher(air_dta$Dest, "Dest", 
                                                     airport_codes)
air_dta <- cbind(air_dta, air_dta_dest_country_info)
air_dta <- air_dta[complete.cases(air_dta$dest_country_name), ]

air_dta <- group_by(air_dta, origin_country_name, origin_sub_region_1,
                    origin_FIPS, dest_country_name, dest_sub_region_1,
                    dest_FIPS, date) %>%
  dplyr::summarize(Prediction = sum(Prediction, na.rm = TRUE))

air_dta$code <- make_unique_air_code(air_dta)

air_dta <- arrange(air_dta, code)

save_object(air_dta, "air_dta")

disaggregate_in_parts(air_dta, "output/data/daily_airflow_mao/", 10)
