update_database(integrate_files = TRUE)
the_db <- pire_database()

dm_examine_constraints(the_db)

pull_tbl(the_db, "individuals_sheets")
pull_tbl(the_db, "lots_sheets")

pull_tbl(the_db, "dna_extractions_sheets") %>%
    filter(is.na(extraction_id))

anti_join(pull_tbl(the_db, "dna_extractions_sheets"),
          pull_tbl(the_db, "individuals_sheets"),
          by = 'individual_id') %>%
    count(individual_id) %>% View

anti_join(pull_tbl(the_db, "individuals_sheets"),
          pull_tbl(the_db, "sampling_sites_sheets"),
          by = 'lot_id') %>%
    count(lot_id)

anti_join(pull_tbl(the_db, "individuals_sheets"),
          pull_tbl(the_db, "lots_sheets"),
          by = 'lot_id') %>%
    count(lot_id)
