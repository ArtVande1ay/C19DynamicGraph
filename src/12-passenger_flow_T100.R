##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse T-100 passenger flow data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

source("src/00-common.R")
library(tempdisagg)
library(tsibble)
library(tsbox)

# Load objects ------------------------------------------------------------

T100_2019_raw <- readRDS(here::here("Rds", "T100_2019_raw.Rds"))
T100_2020_raw <- readRDS(here::here("Rds", "T100_2020_raw.Rds"))
airport_codes <- readRDS(here::here("Rds", "airport_codes.Rds"))

# Work --------------------------------------------------------------------

parse_T100 <- function(x) {
  x %>%
    dplyr::rename(
      Prediction = PASSENGERS,
      Origin = ORIGIN,
      Dest = DEST
    ) %>%
    mutate(
      date = as.Date(
        paste(
          as.character(YEAR),
          paste(as.character(MONTH), "-01", sep = ""),
          sep = "-"
        ),
        format = "%Y-%m-%d"
      ),
      ORIGIN_AIRPORT_ID = NULL,
      ORIGIN_STATE_ABR = NULL,
      Dest_AIRPORT_ID = NULL,
      DEST_STATE_ABR = NULL,
      X = NULL,
      YEAR = NULL,
      MONTH = NULL
    )
}

T100_2019 <- parse_T100(T100_2019_raw)

T100_2019$date <- T100_2019$date + years(1)

T100_2019_origin_country_info <- airport_country_matcher(T100_2019$Origin, 
                                                         "Origin",
                                                         airport_codes)
T100_2019 <- cbind(T100_2019, T100_2019_origin_country_info)
T100_2019 <- T100_2019[complete.cases(T100_2019$origin_country_name), ]

T100_2019_dest_country_info <- airport_country_matcher(T100_2019$Dest, "Dest",
                                                       airport_codes)
T100_2019 <- cbind(T100_2019, T100_2019_dest_country_info)
T100_2019 <- T100_2019[complete.cases(T100_2019$dest_country_name), ]

T100_2019 <- group_by(T100_2019, origin_country_name, origin_sub_region_1,
                      origin_FIPS, dest_country_name, dest_sub_region_1,
                      dest_FIPS, date) %>%
  dplyr::summarize(Prediction = sum(Prediction, na.rm = TRUE))

T100_2019$origin_ID <- make_node_ID(T100_2019, "origin_FIPS",
                                  "origin_country_name", "origin_sub_region_1")
T100_2019$dest_ID<- make_node_ID(T100_2019, "dest_FIPS",
                                  "dest_country_name", "dest_sub_region_1")
T100_2019$ID <- make_edge_ID(T100_2019)

T100_2019 <- arrange(T100_2019, ID)

save_object(T100_2019, "T100_2019")

disaggregate_in_parts(T100_2019, "output/data/daily_airflow_T100_2019/", 10) %>%
  invisible

T100_2020 <- parse_T100(T100_2020_raw)

T100_2020_origin_country_info <- airport_country_matcher(T100_2020$Origin, 
                                                         "Origin",
                                                         airport_codes)
T100_2020 <- cbind(T100_2020, T100_2020_origin_country_info)
T100_2020 <- T100_2020[complete.cases(T100_2020$origin_country_name), ]

T100_2020_dest_country_info <- airport_country_matcher(T100_2020$Dest, "Dest",
                                                       airport_codes)
T100_2020 <- cbind(T100_2020, T100_2020_dest_country_info)
T100_2020 <- T100_2020[complete.cases(T100_2020$origin_country_name), ]

T100_2020 <- group_by(T100_2020, origin_country_name, origin_sub_region_1,
                      origin_FIPS, dest_country_name, dest_sub_region_1,
                      dest_FIPS, date) %>%
  dplyr::summarize(Prediction = sum(Prediction, na.rm = TRUE))

T100_2020$origin_ID <- make_node_ID(T100_2020, "origin_FIPS",
                                  "origin_country_name", "origin_sub_region_1")
T100_2020$dest_ID<- make_node_ID(T100_2020, "dest_FIPS",
                                  "dest_country_name", "dest_sub_region_1")
T100_2020$ID <- make_edge_ID(T100_2020)
T100_2020 <- arrange(T100_2020, ID)

save_object(T100_2020, "T100_2020")

disaggregate_in_parts(T100_2020, "output/data/daily_airflow_T100_2020/", 10) %>%
  invisible
