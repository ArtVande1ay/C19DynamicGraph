##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse passenger flow data from Mao paper
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

source("src/00-common.R")
library(tempdisagg)
library(tsibble)
library(tsbox)

# Load objects ------------------------------------------------------------

airport_codes <- readRDS(here::here("Rds", "airport_codes.Rds"))
mao_dta <- readRDS(here::here("Rds", "mao_dta_raw.Rds"))

# Work --------------------------------------------------------------------
cat("Preparing Mao passenger flow data... "); flush.console()
mao_dta$date <- paste(mao_dta$Month, "-1-2020", sep = "") %>%
  as.Date(format = "%m-%d-%Y")

mao_dta$Month <- NULL

mao_dta_origin_country_info <- airport_country_matcher(mao_dta$Origin, "Origin", 
                                                       airport_codes)
mao_dta <- cbind(mao_dta, mao_dta_origin_country_info)
mao_dta <- mao_dta[complete.cases(mao_dta$origin_country_name), ]

mao_dta_dest_country_info <- airport_country_matcher(mao_dta$Dest, "Dest", 
                                                     airport_codes)
mao_dta <- cbind(mao_dta, mao_dta_dest_country_info)
mao_dta <- mao_dta[complete.cases(mao_dta$dest_country_name), ]

mao_dta <- group_by(mao_dta, origin_country_name, origin_sub_region_1,
                    dest_country_name, dest_sub_region_1, date) %>%
  dplyr::summarize(Prediction = sum(Prediction, na.rm = TRUE)) %>%
  ungroup()


mao_dta_usa <- filter(mao_dta, complete.cases(origin_sub_region_1), complete.cases(dest_sub_region_1))

mao_dta_usa$origin_ID <- make_node_ID(mao_dta_usa, "origin_country_name", "origin_sub_region_1")
mao_dta_usa$dest_ID<- make_node_ID(mao_dta_usa, "dest_country_name", "dest_sub_region_1")
mao_dta_usa$ID <- make_edge_ID(mao_dta_usa)

mao_dta_usa <- arrange(mao_dta_usa, ID)

mao_dta_global_with_usa <- filter(mao_dta, origin_country_name == "US" | dest_country_name == "US",
                                  dest_country_name != "US") %>%
  group_by(
    origin_country_name,
    dest_country_name,
    date
  ) %>%
  summarize(Prediction = sum(Prediction, na.rm = TRUE)) %>%
  ungroup() %>%
  select(
    date,
    Prediction,
    origin_country_name,
    dest_country_name
  ) %>%
  mutate(origin_sub_region_1 = NA,
         dest_sub_region_1 = NA)

mao_dta_global_with_usa$origin_ID <- make_node_ID(mao_dta_global_with_usa, "origin_country_name", "origin_sub_region_1")
mao_dta_global_with_usa$dest_ID<- make_node_ID(mao_dta_global_with_usa, "dest_country_name", "dest_sub_region_1")
mao_dta_global_with_usa$ID <- make_edge_ID(mao_dta_global_with_usa)

mao_dta_global <- filter(mao_dta, is.na(origin_sub_region_1), is.na(dest_sub_region_1))

mao_dta_global$origin_ID <- make_node_ID(mao_dta_global, "origin_country_name", "origin_sub_region_1")
mao_dta_global$dest_ID<- make_node_ID(mao_dta_global, "dest_country_name", "dest_sub_region_1")
mao_dta_global$ID <- make_edge_ID(mao_dta_global)

mao_dta_global <- rbind(mao_dta_global, mao_dta_global_with_usa)

mao_dta_global <- arrange(mao_dta_global, ID)

mao_dta_usa <- mutate(mao_dta_usa,
                  origin_country_name = NULL,
                  origin_sub_region_1 = NULL,
                  dest_country_name = NULL,
                  dest_sub_region_1 = NULL)

mao_dta_global <- mutate(mao_dta_global,
                  origin_country_name = NULL,
                  origin_sub_region_1 = NULL,
                  dest_country_name = NULL,
                  dest_sub_region_1 = NULL)

save_object(mao_dta_usa, "mao_dta_usa")
save_object(mao_dta_global, "mao_dta_global")
cat("Done.\n"); flush.console()
cat("Writing Mao passenger flow data to file...")
disaggregate_in_parts(mao_dta_global, "output/data/daily_airflow_mao/global/", passenger_flow_file_count) %>%
  invisible
disaggregate_in_parts(mao_dta_usa, "output/data/daily_airflow_mao/usa/", passenger_flow_file_count) %>%
  invisible
cat("Done.\n")