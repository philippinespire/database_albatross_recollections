#### User Defined Variables ####
onedrive_path = "../../../Old Dominion University/Carpenter Molecular Lab - Philippines_PIRE_project (1)/Database/"

#### Packages ####
source("functions.R")

install_and_load_packages(
  cran_packages    = 
    c(
      "tidyverse", 
      "janitor", 
      "readxl"
    )
)

#### ####
list.files("../db_files", full.names = TRUE, recursive = TRUE)
