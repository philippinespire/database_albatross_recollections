# update_database(integrate_files = FALSE)
the_db <- pire_database()

dm_examine_constraints(the_db)

pull_tbl(the_db, "individuals_sheets")
pull_tbl(the_db, "lots_sheets")

pull_tbl(the_db, "sampling_sites_sheets") %>%
    filter(is.na(lot_id))

pull_tbl(the_db, "sampling_sites_sheets") %>%
    count(lot_id) %>%
    filter(n > 1)

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


anti_join(pull_tbl(the_db, "sampling_sites_sheets"),
          pull_tbl(the_db, "lots_sheets"),
          by = 'lot_id') %>%
    count(lot_id)


colnames(pull_tbl(the_db, "sampling_sites_sheets"))
anti_join(pull_tbl(the_db, "lots_sheets"),
          pull_tbl(the_db, "sampling_sites_sheets"),
          by = 'lot_id') %>%
    count(lot_id) %>%
    left_join(pull_tbl(the_db, "lots_sheets"),
              by = 'lot_id') %>%
    select(any_of(colnames(pull_tbl(the_db, "sampling_sites_sheets")))) %>%
    select(-starts_with('correction')) %>%
    mutate(barangay = NA_character_,
           local_government_unit = NA_character_,
           province = NA_character_,
           region = NA_character_,
           island_group = NA_character_)




pull_tbl(the_db, "shipments_sheets") %>%
    filter(n() > 1,
           .by = c(shipment_id, plate_box_id)) %>%
    count(shipment_id, plate_box_id)

anti_join(pull_tbl(the_db, "lots_sheets"),
          pull_tbl(the_db, "sampling_sites_sheets"),
          by = 'lot_id') 