#### User Defined Variables ####
if(Sys.info()['user'] == 'jdsel'){
  onedrive_path = "~/../Old Dominion University/Carpenter Molecular Lab - Philippines_PIRE_project/Database"
} else {
  onedrive_path = "../../../Old Dominion University/Carpenter Molecular Lab - Philippines_PIRE_project (1)/Database/"
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
    "../db_files/dna_extractions_sheets",
    "../other_sheets",
    "../db_files/lots_sheets",
    "../other_sheets",
    "../db_files/individuals_sheets",
    "../other_sheets",
    "../db_files/sequence_info_sheets",
    "../db_files/shipments_sheets",
    "../db_files/species_sheets"
  )

#### INITIALIZE ####
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

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
  
  # Read the first sheet of the workbook and write as TSV
  read_excel(in_path, 
             na = c('', 'NA', 'N/A', '?'),
             guess_max = 1e6) %>%
    janitor::remove_empty(which = c('rows', 'cols')) %>%
    strip_newlines() %>%
    write_tsv(out_path, eol = "\n")
  
  message("✅ Wrote ", out_path)
})

