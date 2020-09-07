##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse Covid-19 data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

source("src/00-common.R")

# Load objects ------------------------------------------------------------

pop_dta <- readRDS(here::here("Rds", "pop_dta.Rds"))

# Work --------------------------------------------------------------------
cat("Preparing C19 data... "); flush.console()
c19_dir <- "data/JHU_data/COVID-19-master/csse_covid_19_data/csse_covid_19_daily_reports/"
c19_files <- list.files(c19_dir)
c19_files <- c19_files[which(c19_files != "README.md")]
c19_file_dates <- c19_files %>% 
  strsplit("\\.") %>% 
  lapply(function(x) x[1]) %>% 
  unlist %>% 
  as.Date(format = "%m-%d-%Y")
c19_files <- c19_files[c19_file_dates %in% day_seq]

remove_na <- function(x) {
  x[is.na(x)]
}

read_c19_file <- function(file_name) {
  ### Takes file location, returns parsed data frame.
  file_date <- strsplit(file_name, "\\.")[[1]][1] ### Everything before .csv.
  file_date <- as.Date(file_date, format = "%m-%d-%Y")
  ### Remove extra variables.
  dta <- read.csv(here::here(c19_dir, file_name)) %>%
    mutate(
      `Last Update` = NULL,
      combined_key = NULL,
      Lat = NULL,
      Long = NULL,
      `Long_` = NULL,
      `Last_Update` = NULL,
      Combined_Key = NULL,
      `ISO3` = NULL,
      UID = NULL,
    )
  ### Fix "FIPS" col name.
  w_FIPS <- agrep("FIPS", names(dta), value = FALSE) 
  if (length(w_FIPS) > 0) {
    names(dta)[w_FIPS] <- "FIPS" ### Sometimes named weirdly, this fixes it.
  } else { ### Need to create FIPS column (even if it is all NAs).
    dta <- mutate(dta, FIPS = NA) %>%
      relocate(FIPS) ### Make first column.
  }
  
  ### Fix country_name col name.
  if ("Country/Region" %in% names(dta)) {
    dta <- dplyr::rename(dta, country_name = `Country/Region`)
  } else if ("Country.Region" %in% names(dta)) {
    dta <- dplyr::rename(dta, country_name = `Country.Region`)
  } else if ("Country_Region" %in% names(dta)) {
    dta <- dplyr::rename(dta, country_name = `Country_Region`)
  } else {
    stop("Can't find country/region column name.")
  }
  dta <- filter(dta, country_name != "US" | file_date < as.Date("2020-04-12"))
  
  country_converter <- function(country) {
    ### Renames countries to coincide with our other datasets.
    country[which(country == "Mainland China")] <- "China"
    country[which(country == "Hong Kong")] <- "China"
    country[which(country == "Bahamas")] <- "The Bahamas"
    country[which(country == "Bahamas, The")] <- "The Bahamas"
    country[which(country == " Azerbaijan")] <- "Azerbaijan"
    country[which(country == "Cape Verde")] <- "Cabo Verde"
    country[which(country == "Congo (Brazzaville)")] <- "Congo"
    country[which(country == "East Timor")] <- "Timor-Leste"
    country[which(country == "Czech Republic")] <- "Czechia"
    country[which(country == "Gambia")] <- "The Gambia"
    country[which(country == "Gambia, The")] <- "The Gambia"
    country[which(country == "Hong Kong SAR")] <- "Hong Kong"
    country[which(country == "Iran (Islamic Republic of)")] <- "Iran"
    country[which(country == "Korea, South")] <- "South"
    country[which(country == "Macao SAR")] <- "Macau"
    country[which(country == "Russian Federation")] <- "Russia"
    country[which(country == "St. Martin")] <- "Saint Martin"
    country[which(country == "Taiwan*")] <- "Taiwan"
    country[which(country == "Viet Nam")] <- "Vietnam"
    country[which(country == "UK")] <- "United Kingdom"
    country[which(country == "US")] <- "United States"
    country[which(country == "Republic of the Congo")] <- "Congo"
    country[which(country == "Republic of Korea")] <- "South Korea"
    return(country)
  }
  
  dta$country_name <- country_converter(dta$country_name)
  
  ### Fix sub_region_1 col name.
  w_province <- agrep("Province", names(dta), value = FALSE)
  dta <- dplyr::rename(dta, sub_region_1 = names(dta)[w_province])
  w_empty <- which(dta$sub_region_1 == "")
  dta$sub_region_1[w_empty] <- rep(NA, length(w_empty))
  dta$`Admin2` <- NULL
  dta$Incidence_Rate <- NULL
  dta$Case.Fatality_Ratio <- NULL
  
  ### Sum non-US countries over sub_region_1/2.
  if ("Active" %in% names(dta)) {
    dta <- dta %>%
      group_by(country_name) %>%
      summarize(
        Deaths = sum(Deaths, na.rm = TRUE),
        Confirmed = sum(Confirmed, na.rm = TRUE),
        Recovered = sum(Recovered, na.rm = TRUE),
        Active = sum(Active, na.rm = TRUE)
      ) %>%
      mutate(
        country_name = country_name,
        sub_region_1 = NA,
        FIPS = NA,
        Deaths = replace_na(Deaths, 0),
        Confirmed = replace_na(Confirmed, 0),
        Recovered = replace_na(Recovered, 0),
        Active = Active,
        Incident_Rate = NA,
        People_Tested = NA,
        People_Hospitalized = NA,
        Mortality_Rate = NA,
        Testing_Rate = NA,
        Hospitalization_Rate = NA
      ) %>% ungroup
  } else {
    dta <- dta %>%
      group_by(country_name) %>%
      summarize(
        Deaths = sum(Deaths, na.rm = TRUE),
        Confirmed = sum(Confirmed, na.rm = TRUE),
        Recovered = sum(Recovered, na.rm = TRUE)
      ) %>%
      mutate(
        country_name = country_name,
        sub_region_1 = NA,
        FIPS = NA,
        Confirmed = replace_na(Confirmed, 0),
        Deaths = replace_na(Deaths, 0),
        Recovered = replace_na(Recovered, 0),
        Active = NA,
        Incident_Rate = NA,
        People_Tested = NA,
        People_Hospitalized = NA,
        Mortality_Rate = NA,
        Testing_Rate = NA,
        Hospitalization_Rate = NA
      )
  }
  dta$date <- rep(file_date, nrow(dta))
  dta$FIPS <- NULL
  return(dta)
}

c19_dta_global <- suppressMessages(lapply(c19_files, read_c19_file)) %>%
  rbind.fill

c19_dir_usa <- "data/JHU_data/COVID-19-master/csse_covid_19_data/csse_covid_19_daily_reports_us/"
c19_files_usa <- list.files(c19_dir_usa)
c19_files_usa <- c19_files_usa[which(c19_files_usa != "README.md")]
c19_file_dates_usa <- c19_files_usa %>% 
  strsplit("\\.") %>% 
  lapply(function(x) x[1]) %>% 
  unlist %>% 
  as.Date(format = "%m-%d-%Y")
c19_files_usa <- c19_files_usa[c19_file_dates_usa %in% day_seq]

read_c19_file_usa <- function(file_name) {
  ### Takes file location, returns parsed data frame.
  file_date <- strsplit(file_name, "\\.")[[1]][1] ### Everything before .csv.
  file_date <- as.Date(file_date, format = "%m-%d-%Y")
  ### Remove extra variables.
  dta <- read.csv(here::here(c19_dir_usa, file_name)) %>%
    mutate(
      `Last Update` = NULL,
      combined_key = NULL,
      Lat = NULL,
      Long = NULL,
      `Long_` = NULL,
      `Last_Update` = NULL,
      Combined_Key = NULL,
      `ISO3` = NULL,
      UID = NULL,
      FIPS = NULL
    )
  ### Fix country_name col name.
  if ("Country/Region" %in% names(dta)) {
    dta <- dplyr::rename(dta, country_name = `Country/Region`)
  } else if ("Country.Region" %in% names(dta)) {
    dta <- dplyr::rename(dta, country_name = `Country.Region`)
  } else if ("Country_Region" %in% names(dta)) {
    dta <- dplyr::rename(dta, country_name = `Country_Region`)
  } else {
    stop("Can't find country/region column name.")
  }
  
  ### Fix sub_region_1 col name.
  w_province <- agrep("Province", names(dta), value = FALSE)
  dta <- dplyr::rename(dta, sub_region_1 = names(dta)[w_province])
  w_empty <- which(dta$sub_region_1 == "")
  dta$sub_region_1[w_empty] <- rep(NA, length(w_empty))
  dta$date <- rep(file_date, nrow(dta))
  dta$country_name <- rep("United States", nrow(dta))
  dta <- rbind(dta, data.frame(
    sub_region_1 = NA,
    country_name = "United States",
    Confirmed = sum(dta$Confirmed, na.rm = TRUE),
    Deaths = sum(dta$Deaths, na.rm = TRUE),
    Recovered = sum(dta$Recovered, na.rm = TRUE),
    Active = sum(dta$Active, na.rm = TRUE),
    Incident_Rate = NA,
    People_Tested = sum(dta$People_Tested, na.rm = TRUE),
    People_Hospitalized = sum(dta$People_Hospitalized, na.rm = TRUE),
    Mortality_Rate = NA,
    Testing_Rate = NA,
    Hospitalization_Rate = NA,
    date = file_date
  ))
  return(dta)
}

c19_dta_usa <- suppressMessages(lapply(c19_files_usa, read_c19_file_usa)) %>%
  rbind.fill

c19_dta <- rbind(c19_dta_global, c19_dta_usa)

### Countries in pop_dta but not in c19_dta.
setdiff(unique(pop_dta$country_name), unique(c19_dta$country_name)) %>% sort()

### Countries in c19_dta but not in pop_dta.
setdiff(unique(c19_dta$country_name), unique(pop_dta$country_name)) %>% sort()

save_object(c19_dta, "c19_dta")
cat("Done.\n"); flush.console()