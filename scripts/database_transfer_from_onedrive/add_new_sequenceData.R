the_db <- pire_database()

pull_tbl(the_db, 'sequence_filename_sheets') %>%
    count(sequencing_type)

pull_tbl(the_db, 'sequence_filename_sheets') %>%
    filter(sequencing_type == 'hic') %>%
    select(extraction_id)

pull_tbl(the_db, 'dna_extractions_sheets') %>%
    filter(individual_id == 'Sde-CTlk_104') %>% View
    select(extraction_id)

#1. make filelist.txt `ls /archive/carpenterlab/pire/raw_sequence_archive/spratelloides_delicatulus/20260629_Sde-lcwgs/*fq.gz > /archive/carpenterlab/pire/raw_sequence_archive/spratelloides_delicatulus/20260629_Sde-lcwgs/filelist.txt`
#2. Get SequenceDecode from sequencing facility/Sharon

#### LCWGS ####
file_info <- read_tsv('~/../../Downloads/filelist.txt',
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

decode_names <- read_tsv('~/../../Downloads/Sde_WGS-Sept2026_SequenceNameDecode.tsv',
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

joined_files <- inner_join(decode_names,
                          file_info,
                          by = 'join_term') %>%
    select(-join_term, -extraction_treatment) %>%
    mutate(hpc_name = 'wahab',
           sequencing_type = 'lcwgs',
           duplicated_sequence_pair = NA_character_) %>%
    select(extraction_id, file_prefix, hpc_path, hpc_name, sequencing_type,
           duplicated_sequence_pair, file_forward, file_reverse)

# Extraction sheet for lcWGS
updated_full_extractions <- read_tsv("C:/Users/jselwyn/Texas A&M University-Corpus Christi/Bird, Chris - GCL_2.0/Customers/Bird, Chris/prj_bird_spratelloides-delicatulus_albatross-recollection/dna_extraction/Extractions_sheet_2024-2025.txt",
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


#### HiC ####
joined_files <- read_tsv('~/../../Downloads/filelist.txt',
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
    mutate(extraction_id = 'Sde-CTlk_104-Ex3',
           hpc_name = 'wahab',
           sequencing_type = 'hic',
           duplicated_sequence_pair = NA_character_) %>%
    select(extraction_id, file_prefix, hpc_path, hpc_name, sequencing_type,
           duplicated_sequence_pair, file_forward, file_reverse)

#Extraction sheet for hic
updated_full_extractions <- readxl::read_excel("C:/Users/jselwyn/Texas A&M University-Corpus Christi/Bird, Chris - GCL_2.0/Customers/Bird, Chris/prj_bird_spratelloides-delicatulus_genomes/Sde_HiCLibraries_metadata.xlsx") %>%
    janitor::clean_names() %>% filter(individual_id == 'Sde-CTlk_104') %>%
    select(extraction_id, tissue_id, individual_id, date_extracting = date_of_library_construction) %>%
    mutate(extraction_id = str_replace(extraction_id, 'EX1', 'Ex1'),
           extraction_id = str_replace(extraction_id, '_Ex', '-Ex'),
           storage_solution = 'Liquid Nitrogen',
           tissue_type = 'muscle',
           date_extracting = lubridate::as_date(date_extracting)) %>%
    full_join(read_tsv('staging/dna_extractions_sheets/EXAMPLE_extractions_sheet.tsv',
                       show_col_types = FALSE) %>%
                  select(-date_extracting),
              by = c('extraction_id', 'tissue_id', 'individual_id', 'storage_solution')) %>%
    select(all_of(extraction_sheet_cols),
           all_of(tissue_sheet_cols))
    
#### Make necessary extraction/tissue sheets ####
extraction_sheet_cols <- read_tsv('staging/dna_extractions_sheets/EXAMPLE_extractions_sheet.tsv',
         show_col_types = FALSE) %>%
    colnames()

tissue_sheet_cols <- read_tsv('staging/tissues_sheets/EXAMPLE_tissues_sheet.tsv',
                              show_col_types = FALSE) %>%
    colnames()

new_extractions_update <- anti_join(joined_files,
                                    pull_tbl(the_db, 'dna_extractions_sheets') %>%
                                        select(individual_id, tissue_id, extraction_id),
                                    by = 'extraction_id') %>%
    distinct(extraction_id) %>%
    left_join(updated_full_extractions,
              by = 'extraction_id') %>%
    select(all_of(extraction_sheet_cols))

count(new_extractions_update, mg_tissue_extracted)

# Works with lcWGS
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

# Works with HiC
new_tissue_update <- updated_full_extractions %>%
    distinct(individual_id, tissue_id, extraction_id) %>%
    anti_join(pull_tbl(the_db, 'tissues_sheets') %>%
                  distinct(individual_id, tissue_id),
              by = c('individual_id', 'tissue_id')) %>%
    distinct(extraction_id) %>%
    left_join(updated_full_extractions,
              by = 'extraction_id') %>%
    select(all_of(tissue_sheet_cols))

anti_join(new_tissue_update,
          pull_tbl(the_db, 'individuals_sheets'),
          by = 'individual_id')

#### Write files ####
if(nrow(new_extractions_update) > 0){
    write_tsv(new_extractions_update, 'staging/dna_extractions_sheets/jds_20260922_Sde-hic_extractions_9.22.26.tsv') 
}
if(nrow(joined_files) > 0){
    write_tsv(joined_files, 'staging/sequence_filename_sheets/jds_20260922_Sde-hic_sequences_9.22.26.tsv') 
}
if(nrow(new_tissue_update) > 0){
    write_tsv(new_tissue_update, 'staging/tissues_sheets/jds_20260922_Sde-hic_tissues_9.22.26.tsv') 
}


#### Update ####
update_database(integrate_files = FALSE)
update_database(integrate_files = TRUE)

the_db <- pire_database()
pull_tbl(the_db, 'sequence_filename_sheets') %>%
    filter(str_detect(extraction_id, 'Sde-AMat_005'))


pull_tbl(the_db, 'sequence_filename_sheets') %>%
    filter(sequencing_type == 'hic') %>% View
