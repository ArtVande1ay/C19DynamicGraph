##################################################
## Project: C19 dynamic graph analysis
## Script purpose: create node list from data
## Author: Filipp Shelobolin
##################################################

# Libraries ---------------------------------------------------------------

source("src/00-common.R")

# Load objects ------------------------------------------------------------

pop_dta <- readRDS(here::here("Rds", "pop_dta.Rds"))
geocodes <- readRDS(here::here("Rds", "geocodes.Rds"))
mobility_dta <- readRDS(here::here("Rds", "mobility_dta.Rds"))
policy_dta <- readRDS(here::here("Rds", "policy_dta.Rds"))
c19_dta <- readRDS(here::here("Rds", "c19_dta.Rds"))
airport_codes <- readRDS(here::here("Rds", "airport_codes.Rds"))

# Work --------------------------------------------------------------------
cat("Creating nodes... "); flush.console()
### Plan: left join everything to pop_dta.
nodes <- pop_dta 
nodes <- left_join(nodes, geocodes, by = c(
  c("country_name", "sub_region_1")
))

sum(is.na(nodes$lat)) ### = 0
sum(is.na(nodes$lon)) ### = 0 hooray!

### The rest of our data is organized by day, so we duplicate the current
### node data once for each date.
dates <- seq.Date(from = start_date, to = end_date, by = "day")
nodes <- lapply(dates, function(date) cbind(nodes, date)) %>%
  rbind.fill

nodes <- left_join(nodes, mobility_dta, by = c(
  c("country_name", "sub_region_1", "date")
))

nodes <- left_join(nodes, c19_dta, by = c(
  c("country_name", "sub_region_1", "date")
))

nodes <- left_join(nodes, policy_dta, by = c(
  c("country_name", "sub_region_1", "date")
))

m <- match(nodes$sub_region_1, state.name)
w <- which(complete.cases(m))
nodes$sub_region_1[w] <- state.abb[m[w]]

nodes$ID <- make_node_ID(nodes, "country_code", "sub_region_1")

save_object(nodes, "nodes")

write_in_parts <- function(x, K, folder) {
  breaks <- seq(1, nrow(x), length.out = K + 1) %>% floor
  breaks[length(breaks)] <- breaks[length(breaks)] + 1
  lapply(1:K, function(k) {
    w_subset <- breaks[k]:(breaks[k+1] - 1)
    x_subset <- x[w_subset, ]
    write.csv(
      x_subset,
      paste(paste(folder, "/nodes", sep=""), 
            paste(as.character(k), ".csv", sep = ""),
            sep = "")
    )
  })
}

nodes_usa <- filter(nodes, complete.cases(sub_region_1))
nodes_usa <- nodes_usa[,-which(apply(nodes_usa, 2, function(x) sum(complete.cases(x))) == 0)]

nodes_global <- filter(nodes, is.na(sub_region_1))
nodes_global <- nodes_global[,-which(apply(nodes_global, 2, function(x) sum(complete.cases(x))) == 0)]

write_in_parts(nodes_usa, nodes_usa_file_count, "output/data/nodes/usa")
write_in_parts(nodes_global, nodes_global_file_count, "output/data/nodes/global")
cat("Done.\n"); flush.console()
