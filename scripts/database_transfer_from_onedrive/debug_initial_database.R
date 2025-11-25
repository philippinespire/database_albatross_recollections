pire_db <- pire_database()

dm::dm_examine_constraints(pire_db)

pull_tbl(pire_db, "sequence_filename_sheets") %>%
    select(-starts_with('correction')) %>%
    anti_join(pull_tbl(pire_db, "dna_extractions_sheets")) %>%
    select(-starts_with('correction')) %>%
    select(-sequence_filename_sheetsfile_path) %>%
    filter(str_detect(extraction_id, 'Sde'))

pull_tbl(pire_db, 'dna_extractions_sheets') %>%
    filter(str_detect(extraction_id, 'Sde-CTlk')) %>%
    select(extraction_id)

#### Identify Duplicate IDs differentiated by '-' vs '_' ####
pull_tbl(pire_db, "dna_extractions_sheets") %>%
    # select(extraction_id) %>%
    filter(!is.na(extraction_id)) %>%
    filter(n() > 1,
           .by = extraction_id)

pull_tbl(pire_db, "dna_extractions_sheets") %>%
    # select(individual_id, extraction_id) %>%
    filter(!is.na(extraction_id)) %>%
    mutate(extraction_id2 = str_replace_all(extraction_id, '-', '_')) %>%
    filter(n() > 1,
           .by = extraction_id2) %>%
    select(-extraction_id2) 


pull_tbl(pire_db, "individuals_sheets") %>%
    # select(individual_id, extraction_id) %>%
    filter(!is.na(individual_id)) %>%
    mutate(individual_id2 = str_replace_all(individual_id, '-', '_')) %>%
    filter(n() > 1,
           .by = individual_id2) %>%
    arrange(individual_id2) %>%
    select(-individual_id2)  


pull_tbl(pire_db, "dna_extractions_sheets") %>%
    mutate(individual_id2 = str_replace_all(individual_id, '-', '_') %>% str_to_lower,
           extraction_id2 = str_replace_all(extraction_id, '-', '_') %>% str_to_lower %>%
               str_remove('_e(x)?.*$')) %>%
    # select(individual_id2, extraction_id2) %>%
    filter(individual_id2 != extraction_id2) %>%
    select(-individual_id2, -extraction_id2) %>%
    select(individual_id, extraction_id) %>%
    left_join(pull_tbl(pire_db, "sequence_filename_sheets"))



