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

#### Find Files ####

list.files("../db_files", 
           pattern = 'tsv$',
           full.names = TRUE, 
           recursive = TRUE) %>%
  tibble(file = .) %>%
  mutate(file_type = dirname(file) %>%
           str_remove('^.*/db_files/')) %>%
  slice(8) %>%
  rowwise %>%
  mutate(sheet = read_delim(file, 
                            delim = '\t', 
                            show_col_types = FALSE, 
                            na = c("", "NA", "None")) %>%
           list())
