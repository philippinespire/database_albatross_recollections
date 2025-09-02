setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source('../../scripts/assemble_db.R')

site_sheet_prep <- pire_db %>% 
    dm_flatten_to_tbl(individuals_sheets,species_sheets,lots_sheets) %>%
    select(site_id,species_code,match_id,collection_site.individuals_sheets,
           latitude,longitude, species_albatross_name, lot_id,species_valid_name.individuals_sheets) %>%
    distinct() %>%
    mutate(site_species = paste(site_id, species_code, sep = "-")) %>%
    relocate(site_species, .before = site_id) %>%
    collect()

write_tsv(site_sheet_prep, "site_sheet_prep.tsv")


