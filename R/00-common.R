##################################################
## Project: C19 dynamic graph analysis
## Script purpose: common constants and functions
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

library(tidyverse)
library(here)
library(tempdisagg)
library(tsibble)
library(tsbox)
library(lubridate)

# Constants ---------------------------------------------------------------

start_date <- as.Date("01-01-2020", format = "%m-%d-%Y")
end_date <- as.Date("12-31-2020", format = "%m-%d-%Y")

# Functions ---------------------------------------------------------------

### Given object, extract name and save to /Rds.
save_object <- function(x, object_name) {
  saveRDS(x, paste("Rds/",
    paste(object_name, ".Rds", sep = ""),
    sep = ""
    )
  )
}

### Turning monthly passenger flow data into daily data with linear smoothing.
### We use a fast approximation of Chow-Lin method for temporal disaggregation.
### This fulfills the aggregation constraint (monthly total = sum of daily).
disaggregate <- function(x) {
  ### Given a data_frame and variable to disaggregate, returns disaggregated
  ### data going from 2020-01-01 to 2020-12-31
  x_sub <- x %>%
    ungroup %>%
    select(date, "Prediction") %>%
    dplyr::rename(
      value = Prediction,
      time = date
    )
  if (length(unique(x_sub$value)) == 1) {
    return(rep(0, 366))
  } else {
    td(x_sub ~ 1, to = "daily", method = "fast") %>%
      predict() %>%
      .$value
  }
}


### Given subset of air_dta with unique origin & dest, disaggregate
### prediction & lower/upper bounds.
### If missing data, approximate as mean of available predictions.
parse_origin_dest_dta <- function(y) {
  y <- distinct(y, date, .keep_all = TRUE)
  if (length(y$date) < 12) {
    dates_remaining <- seq.Date(from = start_date, to = end_date, by = "month")
    dates_remaining <- dates_remaining[!dates_remaining %in% y$date] %>%
      as.Date(origin="1970-01-01")
    n <- length(dates_remaining)
    y_add <- data.frame(
      origin_country_name = rep(y$origin_country_name[1], n),
      origin_sub_region_1 = rep(y$origin_sub_region_1[1], n),
      origin_FIPS = rep(y$origin_FIPS[1], n),
      dest_country_name = rep(y$dest_country_name[1], n),
      dest_sub_region_1 = rep(y$dest_sub_region_1[1], n),
      dest_FIPS = rep(y$dest_FIPS[1], n),
      date = dates_remaining,
      Prediction = rep(mean(y$Prediction), n),
      code = rep(y$code[1], n)
    )
    y <- rbind(y, y_add) %>%
      dplyr::arrange(date)
  }
  y_Prediction <- disaggregate(y)
  return(data.frame(
    origin_country_name = rep(y$origin_country_name[1], 366), 
    origin_sub_region_1 = rep(y$origin_sub_region_1[1], 366), 
    origin_FIPS = rep(y$origin_FIPS[1], 366),
    dest_country_name = rep(y$dest_country_name[1], 366), 
    dest_sub_region_1 = rep(y$dest_sub_region_1[1], 366), 
    dest_FIPS = rep(y$dest_FIPS[1], 366),
    date=seq.Date(from = start_date, to = end_date, by = "day"), 
    Prediction = y_Prediction, 
    code = rep(y$code[1], 366)
    )
  )
}

### Disaggregates data and saves to to K .csv files.
### Hugely decreases RAM usages.
disaggregate_in_parts <- function(dta, folder, K) {
  breaks <- seq(1, nrow(dta), length.out = K + 1) %>% floor
  breaks[length(breaks)] <- breaks[length(breaks)] + 1
  lapply(1:K, function(k) {
    w_subset <- breaks[k]:(breaks[k+1] - 1)
    dta_subset <- dta[w_subset, ]
    disaggrogated <- split(dta_subset, dta_subset$code) %>%
      lapply(., parse_origin_dest_dta) %>%
      rbind.fill
    write.csv(
      disaggrogated,
      paste(folder, 
            paste(as.character(k), ".csv", sep = ""),
            sep = "")
    )
    rm(disaggrogated)
    rm(dta_subset)
    cat("interation ", k, "done\n")
    flush.console()
  })
}

### Takes vector of airports, col_type=="Origin" or "Dest", and airport_codes.
### Returns a data.frame of country_name/sub_region_1/FIPS for each airport.
airport_country_matcher <- function(airports, col_type, airport_codes) {
  n = length(airports)
  if (col_type == "Origin") {
    countries <- data.frame(
      origin_country_name = rep(NA, n),
      origin_sub_region_1 = rep(NA, n),
      origin_FIPS = rep(NA, n)
    )
  } else if (col_type == "Dest") {
    countries <- data.frame(
      dest_country_name = rep(NA, n),
      dest_sub_region_1 = rep(NA, n),
      dest_FIPS = rep(NA, n)
    )
  }
  lapply(unique(airports), function(x) {
    w_in_airports <- which(airports == x)
    w_in_airport_codes <- which(airport_codes$airport_code == x)
    country <- airport_codes[w_in_airport_codes, 2:4]
    if (nrow(country) == 0) {
      return()
    }
    countries[w_in_airports, ] <<- country
  })
  return(countries)
}

### Takes an char->integer converted FIPS code, returns corrected version.
FIPS_converter <- function(x) {
  if (is.na(x)) {
    return(NA)
  }
  zeros_needed <- 5 - nchar(x) ### Every FIPS value should have 5 characters.
  zeros <- paste(rep("0", zeros_needed), collapse = "")
  return(paste(zeros, x, sep = ""))
}

### Given a dataset with variables origin_country_name, origin_sub_region_1,
### origin_FIPS, dest_country_name, dest_sub_region_1, dest_FIPS, create a
### unique code for each entry.
make_unique_air_code <- function(x) {
  origin_code <- paste(
    ifelse(is.na(x$origin_FIPS), "", x$origin_FIPS),
    paste(
      ifelse(is.na(x$origin_sub_region_1), "", x$origin_sub_region_1),
      ifelse(is.na(x$origin_country_name), "", x$origin_country_name),
      sep = ", "
    ),
    sep = ", "
  )
  
  dest_code <- paste(
    ifelse(is.na(x$dest_FIPS), "", x$dest_FIPS),
    paste(
      ifelse(is.na(x$dest_sub_region_1), "", x$dest_sub_region_1),
      ifelse(is.na(x$dest_country_name), "", x$dest_country_name),
      sep = ", "
    ),
    sep = ", "
  )
  
  return(paste(origin_code, dest_code))
}
