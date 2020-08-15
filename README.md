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
    
## Outputs

* `outputs/data/nodes/global` contains a node list with all attributes available for countries.
* `outputs/data/nodes/usa` contains a node list with all attributes available for States in the USA. It does not contain any other countries.
* `outputs/data/daily_airflow_mao/global` contains an edge list containing only countries created by Mao's 2015 estimates (more info below). 
* `outputs/data/daily_airflow_mao/usa` contains an edge list containing only States in the USA created by Mao's 2015 estimates (more info below). It does not contain any other countries.
* `outputs/data/daily_airflow_T100_2019/usa` contains an edge list containing only States in the USA from the BTS T-100 datasource (more info below). It does not contain any other countries.

Mao's estimates are found using the model described in the 2015 paper "Modeling monthly flows of global air travel passengers: An open-access data resource". The data is fairly accurate (verify by reading the paper), but is not guaranteed to be comprehensive. For accurate data, it would be better to use the T100 datasource. The T100 database is created the BTS of the US Government, and counts the passenger flow between airports. It is accurate, but does not contain passenger flow in other countries.

For edge lists, `origin_ID` and `dest_ID` columns correspond to the `ID` column in nodes. The data is disaggregated from monthly estimates of passenger flow (both Mao and T100 data sources are montly estimates) using the Chow-Lin method.

Graphs (plots) of the dynamic graph have not yet been added. They will be added soon.

## Prerequisites

R4.0+ and following libraries:

* tidyverse
* here
* tempdisagg
* tsibble
* plyr
* tsbox
* lubridate
* httr
* rvest
* jsonlite
* bigrquery
* DBI
* ggmap
* gaggle

## Generating data

Clone the repository:
```bash
git clone https://github.com/fshelobolin/C19DynamicGraph.git
```

Ensure that you have all of the necessary libraries.

Set up a BigQuery account at google (see https://cloud.google.com/bigquery) and create an ID. Create (and save) a token using lines 46-54 in `src/01-load_raw_data.R`. Place your project ID on line 56 of the same file.

Create a Google geocoding API key (see https://developers.google.com/maps/documentation/geocoding/get-api-key). Insert it on line 27 of `src/03-geocoding.R`.

Change your working directory to the main directory and run `src/main.R`.

## Contact
Filipp Shelobolin: fshelobo(at)andrew(dot)cmu(dot)edu