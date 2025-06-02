#### Setup stuff ####
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#### User Defined Variables ####
data_path_lots = "../db_files/lots_sheets/lot_sheet.tsv"
out_file = "../sandbox/data_opihi_genetics.tsv"


#### PACKAGES ####
source("functions.R")

install_and_load_packages(
  cran_packages    = 
    c(
      "tidyverse", 
      "janitor", 
      "readxl"
    )
)

#### Fix Date Columns in Lots ####

data_lots <-
  read_tsv(
    data_path_lots
  ) %>%
  clean_names() %>%
  mutate(
    collection_year_start = NA_integer_,
    collection_month_start = NA_integer_,
    collection_day_start = NA_integer_,
    collection_year_end = NA_integer_,
    collection_month_end = NA_integer_,
    collection_day_end = NA_integer_,
    .before = date_collected
  )

str(data_lots)

data_lots$date_collected
