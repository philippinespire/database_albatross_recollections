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

source('wrangle_db_files.R')


#### Identify Primary and Foreign Keys ####
dir.create('../troubleshooting_files')
# Samples with either duplicated of missing Extraction IDs
initial_database$dna_extractions_sheets %>%
  filter(n() > 1 | is.na(Extraction_ID),
         .by = Extraction_ID) %>%
  distinct(Individual_ID, Extraction_ID) %>%
  write_csv('../troubleshooting_files/Extractions_sheet_xlsx_issues.csv')


initial_database$dna_extractions_gels %>%
  filter(n() > 1 | is.na(gel_id),
         .by = gel_id)


initial_database$species_sheets %>%
  filter(n() > 1 | is.na(Species_Code),
         .by = Species_Code)


initial_database$individuals_sheets %>%
  filter(is.na(Individual_ID))

initial_database$individuals_sheets %>%
  filter(n() > 1 | is.na(Individual_ID),
         .by = Individual_ID) %>%
  distinct(Individual_ID) %>%
  filter(!is.na(Individual_ID)) %>%
  write_csv('../troubleshooting_files/Individual_sheet_xlsx_issues.csv')
  
  
initial_database$lots_sheets %>%
  filter(n() > 1 | is.na(Lot_ID),
         .by = Lot_ID) %>%
  distinct(Lot_ID)

initial_database$shipments_sheets %>%
  filter(n() > 1 | is.na(Shipment_ID),
         .by = Shipment_ID) %>%
  distinct(Shipment_ID) %>%
  write_csv('../troubleshooting_files/Shipment_sheet_xlsx_issues.csv')


  dm_add_pk(sampling_sites_sheets,
            columns = c(site_id)) %>%
  dm_add_pk(sequence_info_sheets,
            columns = c(sequencing_batch_id)) 




names(initial_database)
initial_database$dna_extractions_sheets %>% colnames
filter(Individual_ID == 'Ssp-AAtu_008') %>%
  select(Individual_ID, Extraction_ID)

initial_database$dna_extractions_sheets %>%
  filter(is.na(Extraction_ID)) %>%
  select(Individual_ID, Extraction_ID)

initial_database$dna_extractions_sheets %>%
  filter(Individual_ID == 'Dba-CKal_001') %>%
  select(Individual_ID, Extraction_ID)

initial_database$dna_extractions_sheets %>%
  filter(Extraction_ID == 'Gma-ARag_001-Ex1') %>% View

initial_database %>%
  dm_enum_pk_candidates(table = 'dna_extractions_sheets')

