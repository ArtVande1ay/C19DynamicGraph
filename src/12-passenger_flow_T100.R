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

T100_raw <- readRDS(here::here("Rds", "T100_raw.Rds"))
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
cat("Preparing T100 passenger air flow data... ")
T100 <- parse_T100(T100_raw)

T100_origin_country_info <- airport_country_matcher(T100$Origin, 
                                                         "Origin",
                                                         airport_codes)
T100 <- cbind(T100, T100_origin_country_info)
T100 <- T100[complete.cases(T100$origin_country_name), ]

T100_dest_country_info <- airport_country_matcher(T100$Dest, "Dest",
                                                       airport_codes)
T100 <- cbind(T100, T100_dest_country_info)
T100 <- T100[complete.cases(T100$dest_country_name), ]

T100 <- group_by(T100, origin_country_name, origin_sub_region_1, dest_country_name, dest_sub_region_1, date) %>%
  dplyr::summarize(Prediction = sum(Prediction, na.rm = TRUE))

T100$origin_ID <- make_node_ID(T100, "origin_country_name", "origin_sub_region_1")
T100$dest_ID<- make_node_ID(T100, "dest_country_name", "dest_sub_region_1")
T100$ID <- make_edge_ID(T100)

T100 <- arrange(T100, ID)

save_object(T100, "T100")
cat("Done.\n")
cat("Writing T100 data in parts...")
disaggregate_in_parts(T100, "output/data/daily_airflow_T100_2020/usa/", passenger_flow_file_count) %>%
  invisible
cat("Done.\n")