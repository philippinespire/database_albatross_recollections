setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source('../../scripts/assemble_db.R')

site_sheet_initial <- pire_db %>% 
    dm_flatten_to_tbl(individuals_sheets, 
                      species_sheets,
                      lots_sheets) %>%
    distinct(lot_id,
             site_id, 
             species_code,
             match_id,
             collection_site = collection_site.individuals_sheets,
             latitude,
             longitude, 
             species_albatross_name, 
             species_valid_name)


### Useful code to interactively merge manual additions into database prior to final creation
# site_prep <- read_delim('site_sheet_initial.tsv') %>%
#     rename(collection_site = collection_site.individuals_sheets,
#            species_valid_name = species_valid_name.individuals_sheets) %>%
#     select(-species_valid_name, -species_albatross_name, -site_species, -species_code) %>%
#     distinct()
# 
# colnames(site_prep)
# colnames(site_sheet_initial)
# 
# full_join(mutate(site_prep, in_prep = TRUE),
#           mutate(site_sheet_initial, in_sheet = TRUE)) %>%
#     select(lot_id, starts_with('in'), everything()) %>%
#     mutate(across(starts_with('in'),
#                   ~replace_na(., FALSE))) %>%
#     filter(in_prep != in_sheet)
# 
# 
# site_sheet <- full_join(mutate(site_prep, in_prep = TRUE),
#           mutate(site_sheet_initial, in_sheet = TRUE)) %>%
#     select(lot_id, starts_with('in'), everything()) %>%
#     select(-coordinates, -starts_with('in'))
# 
# write_tsv(site_sheet, "site_sheet_initial.tsv")
