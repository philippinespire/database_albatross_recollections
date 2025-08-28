#### User Defined Variables ####
if(Sys.info()['user'] == 'jdsel'){
  onedrive_path = "~/../Old Dominion University/Carpenter Molecular Lab - Philippines_PIRE_project/Database"
} else {
  onedrive_path = "../../../../Old Dominion University/Carpenter Molecular Lab - Philippines_PIRE_project (1)/Database/"
}


###### Vector of source Excel files ######
excel_files <- 
  c(
    "Extractions_sheet.xlsx",
    "Library_Contents_sheet.xlsx",
    "Lot_sheet.xlsx",
    "Sequence_info_sheet.xlsx",
    "Individual_sheet.xlsx",
    "Library_Info_sheet.xlsx",
    "Sequence_info_sheet.xlsx",
    "Shipment_sheet.xlsx",
    "Species_sheet.xlsx"
  )

###### Corresponding destination directories (one level up from the working dir) ######
dest_dirs <- 
  c(
    "../../db_files/dna_extractions_sheets",
    "../../other_sheets",
    "../../db_files/lots_sheets",
    "../../other_sheets",
    "../../db_files/individuals_sheets",
    "../../other_sheets",
    "../../db_files/sequence_info_sheets",
    "../../db_files/shipments_sheets",
    "../../db_files/species_sheets"
  )

#### INITIALIZE ####
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#### PACKAGES ####
source("../functions.R")

install_and_load_packages(
  cran_packages    = 
    c(
      "tidyverse", 
      "janitor", 
      "readxl"
    )
)

#### convert files from xlsx to tsv and save to repo ####
###### Helper: strip ALL embedded CR/LF characters inside text cells ######
strip_newlines <- function(df) {
  df %>%
    mutate(across(where(is.character),
                  ~ str_replace_all(.x, "[\r\n]+", " ") |> str_squish()))
}


purrr::walk2(excel_files, dest_dirs, function(fname, ddir) {
  # Construct full paths
  in_path  <- file.path(onedrive_path, fname)
  out_path <- file.path(ddir, str_replace(fname, "\\.xlsx$", ".tsv"))
  
  # Create destination directory if it doesn't exist
  if (!dir.exists(ddir)) dir.create(ddir, recursive = TRUE)
  
  # Get database corrections file
  correction_database <- read_excel(file.path('../../db_files', "extractions_mislabelling_sheet.xlsx"))
  
  # Read the first sheet of the workbook and write as TSV
  in_file <- read_excel(in_path, 
             na = c('', 'NA', 'N/A', '?'),
             guess_max = 1e6) %>%
    janitor::remove_empty(which = c('rows', 'cols')) %>%
    strip_newlines() 
  
  if(fname == "Individual_sheet.xlsx"){
      
      suppressWarnings(
          #Warnings are known and related to parsing the dates not something to pay attention to
          processed_file <- mutate(in_file,
                                   Species_ID_date = case_when(str_detect(Species_ID_date, "^[0-9]{5}$") ~ as.integer(Species_ID_date) |> 
                                                                   as.Date(origin = as.Date("1899-12-30")) %>% as.character(),
                                                               TRUE ~ as.character(Species_ID_date))) %>%
              mutate(Species_ID_year = case_when(str_detect(Species_ID_date, "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ mdy(Species_ID_date) %>% year(), 
                                                 str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}[/-][0-9]{1,2}$") ~ ymd(Species_ID_date) %>% year(), 
                                                 str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}$") ~ str_c(Species_ID_date, '/', '01') %>% ymd() %>% year(), 
                                                 str_detect(Species_ID_date, "^[0-9]{4}$") ~ as.integer(Species_ID_date),
                                                 str_detect(Species_ID_date,
                                                            "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}-[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ 
                                                     str_extract(Species_ID_date, "[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") %>%
                                                     mdy() %>% year(), 
                                                 TRUE ~ NA_integer_),
                     Species_ID_month = case_when(str_detect(Species_ID_date, "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ mdy(Species_ID_date) %>% month(), 
                                                  str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}[/-][0-9]{1,2}$") ~ ymd(Species_ID_date) %>% month(), 
                                                  str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}$") ~ str_c(Species_ID_date, '/', '01') %>% ymd() %>% month(), 
                                                  str_detect(Species_ID_date, "^[0-9]{4}$") ~ NA_integer_,
                                                  str_detect(Species_ID_date,
                                                             "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}-[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ 
                                                      str_extract(Species_ID_date, "[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") %>%
                                                      mdy() %>% month(), 
                                                  TRUE ~ NA_integer_),
                     Species_ID_day = case_when(str_detect(Species_ID_date, "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ mdy(Species_ID_date) %>% day(), 
                                                str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}[/-][0-9]{1,2}$") ~ ymd(Species_ID_date) %>% day(), 
                                                str_detect(Species_ID_date, "^[0-9]{2,4}[/-][0-9]{1,2}$") ~ NA_integer_, 
                                                str_detect(Species_ID_date, "^[0-9]{4}$") ~ NA_integer_,
                                                str_detect(Species_ID_date,
                                                           "^[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}-[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") ~ 
                                                    str_extract(Species_ID_date, "[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}$") %>%
                                                    mdy() %>% day(), 
                                                TRUE ~ NA_integer_)) %>%
              relocate(Species_ID_date_originallyEntered = Species_ID_date,
                       .after = everything())
      )
      
      
  } else {
      processed_file <- in_file
  }
  
  
  
  write_tsv(processed_file, out_path, eol = "\n")
  
  message("✅ Wrote ", out_path)
})

