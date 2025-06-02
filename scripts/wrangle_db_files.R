#### User Defined Variables ####
# onedrive_path = "../../../Old Dominion University/Carpenter Molecular Lab - Philippines_PIRE_project (1)/Database/"

#### Packages ####
source("functions.R")

install_and_load_packages(
  cran_packages    = 
    c(
      "tidyverse", 
      "janitor", 
      "readxl",
      'dm'
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
  pull(sheet) %>%
  do.call(dm, .)

#### Identify Primary and Foreign Keys ####

# Samples with either duplicated of missing Extraction IDs
initial_database$dna_extractions_sheets %>%
  filter(n() > 1 | is.na(Extraction_ID),
         .by = Extraction_ID) %>%
  distinct(Individual_ID, Extraction_ID)





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

#### Make Primary Keys ####
names(initial_database)

initial_database$shipments_sheets

db_with_pk <- initial_database %>%
  dm_add_pk(table = dna_extractions_gels,
            columns = gel_id) %>%
  dm_add_pk(table = species_sheets,
            columns = Species_Code) %>%
  dm_add_pk(dna_extractions_sheets,
            columns = c(Plate_ID, Extraction_ID)) %>%
  dm_add_pk(individuals_sheets,
            columns = c(Individual_ID)) %>%
  dm_add_pk(lots_sheets,
            columns = c(Lot_ID)) %>%
  dm_add_pk(sampling_sites_sheets,
            columns = c(site_id)) %>%
  dm_add_pk(shipments_sheets,
            columns = c(Shipment_ID)) %>%
  dm_add_pk(sequence_info_sheets,
            columns = c()) 


dm_get_all_pks(db_with_pk)

#### Identify Foreign Keys ####



#### Add Foreign Keys ####
db_with_pk


