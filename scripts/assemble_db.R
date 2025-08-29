#### Packages ####
source("./scripts/functions.R")

install_and_load_packages(cran_packages = c("tidyverse", 
                                            "janitor", 
                                            "readxl",
                                            "janitor",
                                            'dm'))


#### Make Primary Keys ####
db_with_pk <- compile_db_inputs() %>%
    do.call(dm, .) %>%
  dm_add_pk(sampling_sites_sheets,
            columns = c(lot_id)) %>%
  dm_add_pk(lots_sheets,
            columns = c(lot_id)) %>%
  dm_add_pk(individuals_sheets,
            columns = c(individual_id)) %>%
  dm_add_pk(table = species_sheets,
            columns = species_valid_name) %>%
  dm_add_pk(dna_extractions_sheets,
            columns = c(extraction_id)) %>%
  dm_add_pk(table = dna_extractions_gels,
            columns = gel_id) %>%
  dm_add_pk(shipments_sheets,
            columns = c(shipment_id, plate_box_id)) %>%
  # dm_add_pk(sequence_info_sheets,
  #           columns = c(sequencing_batch_id)) %>%
  identity()


# dm_get_all_pks(db_with_pk)

#### Add Foreign Keys ####
pire_db <- db_with_pk %>%
  # dm_add_fk(table = sampling_sites_sheets,
  #           columns = species_id,
  #           ref_table = species_sheets) %>%
  dm_add_fk(table = lots_sheets, 
            columns = lot_id, 
            ref_table = sampling_sites_sheets,
            ref_columns = lot_id) %>%
  dm_add_fk(table = individuals_sheets, 
            columns = lot_id, 
            ref_table = lots_sheets) %>%
    dm_add_fk(table = individuals_sheets, 
              columns = lot_id, 
              ref_table = sampling_sites_sheets) %>%
  dm_add_fk(table = individuals_sheets,
            columns = species_valid_name,
            ref_table = species_sheets,
            ref_columns = species_valid_name) %>%
  dm_add_fk(table = dna_extractions_sheets, 
            columns = individual_id, 
            ref_table = individuals_sheets) %>%
  dm_add_fk(table = dna_extractions_sheets,
            columns = plateid,
            ref_table = shipments_sheets,
            ref_col = plate_box_id)

rm(db_with_pk)
#%>% colnames()
#species_id

#### visualize db ####
erd_image <-
    pire_db %>%
    dm_draw(rankdir = "TB", view_type = "keys_only")

erd_image

# pire_db %>%
#   dm_draw(rankdir = "TB", view_type = "all")



