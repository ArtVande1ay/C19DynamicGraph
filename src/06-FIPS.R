##################################################
## Project: C19 dynamic graph analysis
## Script purpose: parse FIPS data.
## Author: Filipp Shelobolin
##################################################

###
# *
# NOTE: This data not currently used. Previously integrated county data,
# however, due to lack of accurately tracking population movement between counties,
# we are just focusing on US States and countries.
# *
###

# Libraries ---------------------------------------------------------------

source("src/00-common.R")

if ("fips_table.Rds" %in% list.files("Rds")) {
  stop_quietly()
}

# Load objects ------------------------------------------------------------

fips_table <- readRDS(here::here("Rds", "fips_table_raw.Rds"))

# Work --------------------------------------------------------------------
cat("Preparing FIPS code data..."); flush.console()
fips_table$FIPS <- as.character(fips_table$FIPS)
fips_table$FIPS <- lapply(fips_table$FIPS, FIPS_converter) %>%
  unlist()
names(fips_table) <- c("FIPS", "sub_region_2", "sub_region_1")
fips_table$country_name <- "United States"
### Remove bracketed references from Wiki table
fips_table$sub_region_2 <- lapply(fips_table$sub_region_2, function(x) {
  strsplit(x, "\\[")[[1]][1]
}) %>% unlist()

save_object(fips_table, "fips_table")
cat("Done.\n"); flush.console()