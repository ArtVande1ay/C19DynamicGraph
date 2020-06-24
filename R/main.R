##################################################
## Project: C19 dynamic graph analysis
## Script purpose: run all scripts
## Author: Filipp Shelobolin
##################################################

file_names <- list.files("./R")
file_names <- file_names[file_names != "main.R"]
for (file_name in file_names) {
  source(paste("R/", file_name, sep = ""))
  rm(list=ls()) ### Minimizes RAM usage.
}