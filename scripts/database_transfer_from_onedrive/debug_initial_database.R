source('scripts/assemble_db.R')


#### Find Missing Primary Keys ####
missing_pk_data <- dm_get_all_pks(full_db) %>%
    rowwise(table, pk_col) %>%
    summarise(missing_pk = list(find_missing_pks(full_db,
                                                 table,
                                                 pk_col)),
              number_missing_rows = nrow(missing_pk),
              .groups = 'drop') %>%
    filter(number_missing_rows > 0) 
missing_pk_data
with(missing_pk_data,
     walk2(table, 
           missing_pk,
           ~write_csv(.y, str_c('problem_notes/missing_PK_', .x, '.csv'))))


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
    select(-extraction_id2) %>%
    write_csv('problem_notes/duplicate_extraction_ids.csv')


pull_tbl(pire_db, "individuals_sheets") %>%
    # select(individual_id, extraction_id) %>%
    filter(!is.na(individual_id)) %>%
    mutate(individual_id2 = str_replace_all(individual_id, '-', '_')) %>%
    filter(n() > 1,
           .by = individual_id2) %>%
    arrange(individual_id2) %>%
    select(-individual_id2)  %>%
    write_csv('problem_notes/duplicate_individual_ids.csv')
     

pull_tbl(pire_db, "dna_extractions_sheets") %>%
    mutate(individual_id2 = str_replace_all(individual_id, '-', '_') %>% str_to_lower,
           extraction_id2 = str_replace_all(extraction_id, '-', '_') %>% str_to_lower %>%
               str_remove('_e(x)?.*$')) %>%
    # select(individual_id2, extraction_id2) %>%
    filter(individual_id2 != extraction_id2) %>%
    select(-individual_id2, -extraction_id2) %>% #select(extraction_id)
    write_csv('problem_notes/indID_notMatch_extID.csv')
