#### Packages ####
here::i_am("scripts/assemble_db.R")
source(here::here("scripts", "functions.R"))
# source("./scripts/functions.R")

install_and_load_packages(cran_packages = c("tidyverse", 
                                            "janitor", 
                                            "readxl",
                                            "janitor",
                                            'dm'))
#### Create Database ####
pire_db <- database_assembly()


