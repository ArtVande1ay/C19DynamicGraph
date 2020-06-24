# Covid-19 Dynamic Graph
> An analysis of Covid-19 spread via dynamic graphs.

## Description

We are attempting a dynamic graph analysis of Covid-19 spread, using population
movement as a predictor. The primary object of analysis is a dynamic graph,
where nodes are counties/states/countries and edges are population movement.
We will be utilizing a combination of modeling, pattern discovery and anomaly 
detection, and analysis of changing characteristics of the dynamic graph.

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

## Installation

Clone the repository:
```Python
git clone https://github.com/fshelobolin/C19DynamicGraph.git
```
Ensure that you have all of the necessary libraries.
Ensure that the following folders exist: `/output/data` and `/output/graphs`, 
and `/Rds`.


Run `main.R` in `/R`.

## Contact
Filipp Shelobolin: fshelobo(at)andrew(dot)cmu(dot)edu