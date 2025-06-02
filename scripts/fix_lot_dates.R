#### Setup stuff ####
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#### User Defined Variables ####
data_path_lots = "../Lot_sheet.xlsx"
data_path_genetics = "../data/pure_f1_f2_etc_individuals.tsv"
out_file = "../sandbox/data_opihi_genetics.tsv"
identity_poster_probability_threshold = 0.95


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
  read_excel(
    data_path_lots
  )
