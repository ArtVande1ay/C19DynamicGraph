##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse Covid-19 data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

source("src/00-common.R")

# Load objects ------------------------------------------------------------

pop_dta <- readRDS(here::here("RDS", "pop_dta.Rds"))

# Work --------------------------------------------------------------------

c19_dir <- "data/JHU_data/COVID-19-master/csse_covid_19_data/csse_covid_19_daily_reports/"
c19_files <- list.files(c19_dir)
c19_files <- c19_files[which(c19_files != "README.md")]

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
  
  country_converter <- function(country) {
    ### Renames countries to coincide with our other datasets.
    country[which(country == "US")] <- "United States"
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
    country[which(country == "Republic of the Congo")] <- "Congo"
    country[which(country == "Republic of Korea")] <- "South Korea"
    return(country)
  }
  
  dta$country_name <- country_converter(dta$country_name)
  
  ### Fix sub_region_1 col name.
  w_province <- agrep("Province", names(dta), value = FALSE)
  dta <- dplyr::rename(dta, sub_region_1 = names(dta)[w_province])
  
  ### Fix sub_region_2 col name.
  if ("Admin2" %in% names(dta)) {
    dta_us <- filter(dta, country_name == "United States")
    dta <- filter(dta, country_name != "United States")
    dta_us <- dta_us %>%
      dplyr::rename(
        sub_region_2 = `Admin2`
      ) %>%
      filter(
        sub_region_2 != "Unassigned"
      ) %>%
      mutate(
        sub_region_2 = NULL ### Badly named, just use FIPS.
      ) %>%
      select(
        country_name,
        sub_region_1,
        FIPS,
        Deaths,
        Confirmed,
        Recovered,
        Active,
      )
  } else {
    dta$sub_region_1 <- NA
    dta_us <- NULL
  }
  
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
        Active = replace_na(Active, 0)
      )
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
        Deaths = replace_na(Deaths, 0),
        Confirmed = replace_na(Confirmed, 0),
        Recovered = replace_na(Recovered, 0),
        Active = NA
      )
  }
  dta <- rbind(dta, dta_us)
  dta$date <- file_date
  dta$FIPS <- lapply(as.character(dta$FIPS), FIPS_converter) %>% unlist()
  return(dta)
}

c19_dta <- suppressMessages(lapply(c19_files, read_c19_file)) %>%
  rbind.fill


### Countries in pop_dta but not in c19_dta.
setdiff(unique(pop_dta$country_name), unique(c19_dta$country_name)) %>% sort()

### Countries in c19_dta but not in pop_dta.
setdiff(unique(c19_dta$country_name), unique(pop_dta$country_name)) %>% sort()


### Can't do any modeling without C19 data, might as well remove.
no_c19_dta <- setdiff(unique(pop_dta$country_name), unique(c19_dta$country_name))
w_no_c19_dta <- which(pop_dta$country_name %in% no_c19_dta)
pop_dta <- pop_dta[-w_no_c19_dta, ]

save_object(pop_dta, "pop_dta")
save_object(c19_dta, "c19_dta")
