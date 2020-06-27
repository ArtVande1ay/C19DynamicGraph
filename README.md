# Covid-19 Dynamic Graph
> An analysis of Covid-19 spread via dynamic graphs.
> Advisor: Dr. Larry Holder, Washington State University

## Description

We are attempting a dynamic graph analysis of Covid-19 spread, using population
movement as a predictor. The primary object of analysis is a dynamic graph,
where nodes are counties/states/countries and edges are population movement.
We will be utilizing a combination of modeling, pattern discovery and anomaly 
detection, and analysis of changing characteristics of the dynamic graph.

## Directory structure

    .
    ├── data                      # Raw data
    ├── output                    # Files produced by scripts
        ├── data                  # Data produced by scripts 
        └── graphs                # Graphs produced by scripts
    ├── src                       # Scripts 
    ├── Rds                       # Temporary files created by scripts
    ├── Variable_descriptions.csv # Node data variable descriptions
    └── README.md

## Prerequisites

R4.0+ and following libraries:

* tidyverse
* here
* tempdisagg
* tsibble
* tsbox
* lubridate
* httr
* rvest
* jsonlite
* bigrquery
* DBI
* ggmap
* gaggle

## Usage

Clone the repository:
```bash
git clone https://github.com/fshelobolin/C19DynamicGraph.git
```
Ensure that you have all of the necessary libraries.

Run `main.R` in `/R`.

## Contact
Filipp Shelobolin: fshelobo(at)andrew(dot)cmu(dot)edu