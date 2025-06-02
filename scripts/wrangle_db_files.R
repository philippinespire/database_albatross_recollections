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

#### Find & Read Files ####
initial_database <- list.files("../db_files", 
                                   pattern = 'tsv$',
                                   full.names = TRUE, 
                                   recursive = TRUE) %>%
  tibble(file = .) %>%
  mutate(file_type = dirname(file) %>%
           str_remove('^.*/db_files/')) %>%
  rowwise %>%
  mutate(sheet = read_delim(file, 
                            delim = '\t', 
                            show_col_types = FALSE, 
                            na = c("", "NA", "None"),
                            id = str_c(file_type, 'file_path'),
                            guess_max = 1e6) %>%
           list()) %>%
  ungroup %>%
  summarise(sheet = bind_rows(sheet) %>%
              list(),
            .by = file_type) %>%
  rowwise %>%
  mutate(sheet = distinct(sheet) %>%
           list()) %>%
  ungroup %>%
  mutate(sheet = set_names(sheet, file_type)) %>%
  pull(sheet)

