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

source('wrangle_db_files.R')


#### Make Primary Keys ####
db_with_pk <- initial_database %>%
  dm_add_pk(table = dna_extractions_gels,
            columns = gel_id) %>%
  dm_add_pk(table = species_sheets,
            columns = Species_Code) %>%
  dm_add_pk(dna_extractions_sheets,
            columns = c(Extraction_ID)) %>%
  dm_add_pk(individuals_sheets,
            columns = c(Individual_ID)) %>%
  dm_add_pk(lots_sheets,
            columns = c(Lot_ID)) %>%
  dm_add_pk(sampling_sites_sheets,
            columns = c(site_id)) %>%
  dm_add_pk(shipments_sheets,
            columns = c(Shipment_ID)) %>%
  # dm_add_pk(sequence_info_sheets,
  #           columns = c(sequencing_batch_id)) %>%
  identity()


dm_get_all_pks(db_with_pk)

#### Add Foreign Keys ####
full_db <- db_with_pk %>%
  dm_add_fk(table = individuals_sheets, 
            columns = Lot_ID, 
            ref_table = lots_sheets) %>%
  dm_add_fk(table = individuals_sheets, 
            columns = Species_valid_name, 
            ref_table = species_sheets,
            ref_columns = Species_valid_name) %>%
  dm_add_fk(table = individuals_sheets, 
            columns = Collection_site, 
            ref_table = sampling_sites_sheets) %>%
  dm_add_fk(table = dna_extractions_sheets, 
            columns = Individual_ID, 
            ref_table = individuals_sheets) %>%
  dm_add_fk(table = lots_sheets, 
            columns = Site_ID, 
            ref_table = sampling_sites_sheets)
  
full_db %>%
  dm_draw(rankdir = "TB", view_type = "all")


