##################################################
## Project: C19 dynamic graph analysis
## Script purpose: create node list from data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

library(tidyverse)

source("R/00-common.R")

# Load objects ------------------------------------------------------------

pop_dta <- readRDS(here::here("Rds", "pop_dta.Rds"))
geocodes <- readRDS(here::here("Rds", "geocodes.Rds"))
mobility_dta <- readRDS(here::here("Rds", "mobility_dta.Rds"))
policy_dta <- readRDS(here::here("Rds", "policy_dta.Rds"))
fips_table <- readRDS(here::here("Rds", "fips_table.Rds"))
c19_dta <- readRDS(here::here("Rds", "c19_dta.Rds"))
weather_dta <- readRDS(here::here("Rds", "weather_dta.Rds"))
airport_codes <- readRDS(here::here("Rds", "airport_codes.Rds"))

# Work --------------------------------------------------------------------

### Plan: left join everything to pop_dta.
nodes <- pop_dta 
nodes <- left_join(nodes, geocodes, by = c(
  c("country_name", "sub_region_1", "sub_region_2")
))

sum(is.na(nodes$lat)) ### = 0
sum(is.na(nodes$lon)) ### = 0 hooray!

nodes <- left_join(nodes, fips_table, by = c(
  c("country_name", "sub_region_1", "sub_region_2")
))

### The rest of our data is organized by day, so we duplicate the current
### node data once for each date.
dates <- seq.Date(from = start_date, to = end_date, by = "day")
nodes <- lapply(dates, function(date) cbind(nodes, date)) %>%
  rbind.fill

nodes <- left_join(nodes, mobility_dta, by = c(
  c("country_name", "sub_region_1", "sub_region_2", "date")
))

nodes <- left_join(nodes, c19_dta, by = c(
  c("country_name", "sub_region_1", "FIPS", "date")
))

nodes <- left_join(nodes, policy_dta, by = c(
  c("country_name", "sub_region_1", "sub_region_2", "date")
))

nodes <- left_join(nodes, weather_dta, by = c(
  c("FIPS", "date")
))

save_object(nodes, "nodes")

write_in_parts <- function(x, K, folder) {
  breaks <- seq(1, nrow(x), length.out = K + 1) %>% floor
  breaks[length(breaks)] <- breaks[length(breaks)] + 1
  lapply(1:K, function(k) {
    w_subset <- breaks[k]:(breaks[k+1] - 1)
    x_subset <- x[w_subset, ]
    write.csv(
      x_subset,
      paste(folder, 
            paste(as.character(k), ".csv", sep = ""),
            sep = "")
    )
  })
}

write_in_parts(nodes, 10, here::here("output", "data", "nodes"))
