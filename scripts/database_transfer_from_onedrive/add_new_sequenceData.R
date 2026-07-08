the_db <- pire_database()

names(the_db)

pull_tbl(the_db, 'dna_extractions_sheets') %>%
    filter(extraction_id == 'Sde-CPla_003-Ex1')

pull_tbl(the_db, 'individuals_sheets') %>%
    filter(individual_id == 'Sde-CPla_003')

pull_tbl(the_db, 'dna_extractions_sheets') %>%
    filter(individual_id == 'Sde-CPla_003')

pull_tbl(the_db, 'sequence_filename_sheets') %>%
    filter(str_detect(extraction_id, 'Sd'))

#1. make filelist.txt `ls /archive/carpenterlab/pire/raw_sequence_archive/spratelloides_delicatulus/20260629_Sde-lcwgs/*fq.gz > /archive/carpenterlab/pire/raw_sequence_archive/spratelloides_delicatulus/20260629_Sde-lcwgs/filelist.txt`
#2. Get SequenceDecode from sequencing facility/Sharon

file_info <- read_tsv('~/../Downloads/filelist.txt',
         col_names = 'full_path',
         show_col_types = FALSE) %>%
    mutate(hpc_path = dirname(full_path),
           file = basename(full_path),
           .keep = 'unused') %>%
    mutate(direction = case_when(str_extract(file, '[12].fq.gz') == '1.fq.gz' ~ 'file_forward',
                         TRUE ~ 'file_reverse'),
           file_prefix = str_remove(file, '_[12].fq.gz$')) %>%
    pivot_wider(names_from = direction,
                values_from = file) %>%
    mutate(join_term = str_extract(file_prefix, '[0-9A-Za-z]+')) %>%
    select(join_term, file_prefix, hpc_path, file_forward, file_reverse)

decode_names <- read_tsv('~/../Downloads/Sde_WGS-June2026_SequenceNameDecode.tsv',
         col_names = c('join_term', 'extraction_treatment'),
         skip = 1, show_col_types = FALSE) %>%
    mutate(extraction_id = str_extract(extraction_treatment, 'Sde-[A-Z]{2}[a-z]{2}_[0-9]{3}[-_]E([xX])?[0-9]'),
           extraction_id = str_replace(extraction_id, 'EX', 'Ex'),
           extraction_id = str_replace(extraction_id, '_E', '-E'),
           extraction_id = str_replace(extraction_id, 'E1', 'Ex1'))

filter(decode_names, is.na(extraction_id))
filter(decode_names, !str_detect(extraction_id, '-Ex'))

anti_join(decode_names,
          file_info,
          by = 'join_term')

anti_join(file_info, 
          decode_names,
          by = 'join_term')

joined_files <- full_join(decode_names,
          file_info,
          by = 'join_term') %>%
    select(-join_term, -extraction_treatment) %>%
    mutate(hpc_name = 'wahab',
           sequencing_type = 'lcwgs',
           duplicated_sequence_pair = NA_character_) %>%
    select(extraction_id, file_prefix, hpc_path, hpc_name, sequencing_type,
           duplicated_sequence_pair, file_forward, file_reverse)


#### Make necessary extraction/tissue sheets ####
extraction_sheet_cols <- read_tsv('staging/dna_extractions_sheets/EXAMPLE_extractions_sheet.tsv',
         show_col_types = FALSE) %>%
    colnames()


tissue_sheet_cols <- read_tsv('staging/tissues_sheets/EXAMPLE_tissues_sheet.tsv',
                              show_col_types = FALSE) %>%
    colnames()

updated_full_extractions <- read_tsv("C:/Users/jdsel/Texas A&M University-Corpus Christi/Bird, Chris - GCL_2.0/Customers/Bird, Chris/prj_bird_spratelloides-delicatulus_albatross-recollection/dna_extraction/Extractions_sheet_2024-2025.txt",
         show_col_types = FALSE) %>%
    janitor::clean_names() %>% 
    rename(extraction_tubeid = extraction_tube_id,
           plateid = plate_id,
           num_elutions = elutions,
           elution1_plateid = elution1_plate_id, 
           elution2_plateid = elution2_plate_id,
           elution3_plateid = elution3_plate_id,
           elution4_plateid = elution4_plate_id) %>% #colnames()
    select(all_of(extraction_sheet_cols),
           all_of(tissue_sheet_cols)) %>% 
    mutate(extraction_id = str_replace(extraction_id, 'EX1', 'Ex1'),
           extraction_id = str_replace(extraction_id, '_Ex', '-Ex'),
           mg_tissue_extracted = case_when(mg_tissue_extracted == '15-Oct' ~ '10-15',
                                           mg_tissue_extracted == '20-Oct' ~ '10-20',
                                           TRUE ~ mg_tissue_extracted))

new_extractions_update <- anti_join(joined_files,
          pull_tbl(the_db, 'dna_extractions_sheets') %>%
              select(individual_id, tissue_id, extraction_id),
          by = 'extraction_id') %>%
    distinct(extraction_id) %>%
    left_join(updated_full_extractions,
              by = 'extraction_id') %>%
    select(all_of(extraction_sheet_cols))

count(new_extractions_update, mg_tissue_extracted)


new_tissue_update <- joined_files %>%
    mutate(individual_id = str_remove(extraction_id, '-Ex[0-9]+')) %>%
    distinct(individual_id, extraction_id) %>%
    anti_join(pull_tbl(the_db, 'tissues_sheets') %>%
                  select(individual_id, tissue_id),
              by = 'individual_id') %>%
    distinct(extraction_id) %>%
    left_join(updated_full_extractions,
              by = 'extraction_id') %>%
    select(all_of(tissue_sheet_cols))

anti_join(new_tissue_update,
          pull_tbl(the_db, 'individuals_sheets'),
          by = 'individual_id')

#### Write files ####
write_tsv(new_extractions_update, 'staging/dna_extractions_sheets/jds_20260629_Sde-lcwgs_extractions_7.7.26.tsv')
write_tsv(joined_files, 'staging/sequence_filename_sheets/jds_20260629_Sde-lcwgs_sequences_7.7.26.tsv')
write_tsv(new_tissue_update, 'staging/tissues_sheets/jds_20260629_Sde-lcwgs_tissues_7.7.26.tsv')


#### Update ####
update_database(integrate_files = FALSE)
update_database(integrate_files = TRUE)

the_db <- pire_database()
pull_tbl(the_db, 'sequence_filename_sheets') %>%
    filter(str_detect(extraction_id, 'Sde-CPla_003'))
