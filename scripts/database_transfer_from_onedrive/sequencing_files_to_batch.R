#### Prep Database ####
pire_db <- pire_database()

the_db <- pire_db %>%
    dm_select(sequence_filename_sheets, 
              gcl_sequence_id, pire_sequence_id,
              extraction_id) %>%
    dm_select(dna_extractions_sheets,
              individual_id, extraction_id) %>%
    dm_select(individuals_sheets,
              individual_id, lot_id,
              species_valid_name) %>%
    dm_select(lots_sheets,
              lot_id, era = collection_era) %>%
    dm_select(sampling_sites_sheets,
              lot_id, site_id) %>%
    dm_select(species_sheets,
              species_valid_name, species_code) %>%
    dm_select(sequence_info_sheets,
              sequencing_batch_id, species_code,
              era, site_id, hpc_path)

#### Extra Libraries ####
library(ssh)
library(fuzzyjoin)

#### Functions ####
get_wahab_fq_list <- function(ssh_connection, directory){
    the_command <- sprintf(
        'find %s -maxdepth 2 -type f \\( -iname "*.fq.gz" -o -iname "*.fastq.gz" \\) -printf "%%P\\n"',
        shQuote(directory)
    )
    
    res <- ssh::ssh_exec_internal(ssh_connection, the_command, error = FALSE)
    
    files <- strsplit(rawToChar(res$stdout), "\n", fixed = TRUE)[[1]]
    files <- files[nzchar(files)]
    
    if (length(files) == 0) {
        tibble::tibble(directory = directory, file = NA_character_)
    } else {
        tibble::tibble(directory = directory, file = files)
    }
}


# get_wahab_fq_list(ssh_connection, directory = all_metadata$hpc_path[10])

get_wahab_data <- function(df){
    ssh_connection <- ssh_connect('jselwyn@wahab.hpc.odu.edu')
    out <- map_dfr(df$hpc_path,
               get_wahab_fq_list, 
               ssh_connection = ssh_connection) %>%
        nest(wahab_seqs = -c(directory))
    
    ssh_disconnect(ssh_connection)
    full_join(df, out,
              by = c('hpc_path' = 'directory'))
}

#### Get all logged sequences ####
all_metadata <- full_join(pull_tbl(the_db, "sequence_filename_sheets"),
          pull_tbl(the_db, "dna_extractions_sheets"),
          by = 'extraction_id') %>%
    full_join(pull_tbl(the_db, "individuals_sheets"),
              by = 'individual_id') %>% 
    full_join(pull_tbl(the_db, "lots_sheets"),
              by = 'lot_id') %>%
    # full_join(pull_tbl(the_db, "sampling_sites_sheets"),
    #           by = 'lot_id') %>%
    full_join(pull_tbl(the_db, "species_sheets"),
              by = 'species_valid_name') %>%
    select(-lot_id, -species_valid_name) %>%
    
    # filter(str_detect(extraction_id, 'Sde-AMar_061')) %>%
    
    nest(seqs = c(gcl_sequence_id, pire_sequence_id,
                  extraction_id, individual_id)) %>%
    left_join(pull_tbl(the_db, "sequence_info_sheets"),
              by = c('species_code', 'era')) %>%
    filter(!is.na(sequencing_batch_id))

# !map_lgl(seqs, is.null)
# filter(all_metadata, is.na(hpc_path)) %>%
#     select(sequencing_batch_id) %>%
#     write_csv('problem_notes/missing_hpc_path.csv')


#### Get wahab sequences from specified directories ####
wahab_seq_joined <- filter(all_metadata, 
                           !is.na(hpc_path)) %>%
    nest(data = -hpc_path) %>%
    get_wahab_data()

select(wahab_seq_joined, hpc_path, wahab_seqs) %>%
    unnest(wahab_seqs) %>%
    filter(str_detect(file, 'fq_raw'))

#### Filter to match ids with wahab seqs ####
library(multidplyr)
cluster <- new_cluster(parallelly::availableCores() - 1)
cluster_library(cluster, c('dplyr', 'stringr'))

matched_ids <- wahab_seq_joined %>%
    unnest(data) %>%
    unnest(seqs) %>%
    # sample_n(100) %>%
    rowwise %>%
    partition(cluster) %>%
    mutate(wahab_seqs = filter(wahab_seqs, 
                               str_detect(str_to_lower(file), 
                                          str_to_lower(extraction_id)) |
                                   str_detect(str_to_lower(file), 
                                              str_to_lower(pire_sequence_id)) |
                                   str_detect(str_to_lower(file), 
                                              str_to_lower(gcl_sequence_id)) |
                                   str_detect(str_to_lower(file), 
                                              str_to_lower(individual_id))) %>%
               list()) %>%
    collect()

matched_ids

# file <- tmp$file[[1]]; matched_data <- tmp$data[[1]]
find_likely_match <- function(file, matched_data){
    mutate(matched_data,
           across(everything(),
                  str_to_lower),
           across(everything(),
                  str_replace_na)) %>%
        mutate(across(everything(),
                      ~str_detect(str_to_lower(file), .)),
               row_id = row_number()) %>%
        rowwise %>%
        mutate(n_hits = sum(c_across(where(is.logical)))) %>%
        ungroup %>%
        filter(n_hits == max(n_hits)) %>%
        select(row_id) %>%
        left_join(mutate(matched_data, 
                         row_id = row_number()),
                  by = 'row_id') %>%
        select(-row_id)
}
cluster_copy(cluster, c('find_likely_match'))

tmp <- matched_ids %>%
    unnest(wahab_seqs, keep_empty = FALSE) %>%
    select(-hpc_path:-species_code) %>%
    # filter(str_detect(file, 'fq_raw')) %>%
    # filter(file == 'fq_raw/Sde-AMar_061-Ex1b-cssl2.2.fq.gz')
    # sample_n(10) %>%
    nest_by(file) %>%
    partition(cluster) %>%
    mutate(data = find_likely_match(file, data) %>%
               list()) %>%
    collect() %>%
    ungroup %>%
    unnest(data)


tmp

unnest(matched_ids, wahab_seqs)

select(wahab_seq_joined, hpc_path, wahab_seqs) %>%
    unnest(wahab_seqs) %>%
    filter(str_detect(file, 'fq_raw')) %>%
    anti_join(tmp,
              by = 'file')

pull_tbl(pire_db,
         'individuals_sheets') %>%
    filter(str_detect(individual_id, 'Sde-AMar_061'))

pull_tbl(pire_db,
         'dna_extractions_sheets') %>%
    filter(str_detect(extraction_id, 'Sde-AMar_061'))

names(pire_db)
pull_tbl(pire_db,
         'sequence_filename_sheets') %>%
    filter(str_detect(extraction_id, 'Sde-AMar_061'))

pull_tbl(pire_db, 
         'sequence_filename_sheets') %>%
    anti_join(tmp,
              by = c('gcl_sequence_id', 
                     'pire_sequence_id', 
                     'extraction_id'))


%>%
    mutate(direction = str_extract(file, '(Rr)?[12].fq.gz') %>%
               str_remove('.fq.gz') %>%
               str_remove('^[rR]') %>%
               str_c('R', .)) 
    pivot_wider(names_from = direction, 
                values_from = file)

filter(blat, gcl_sequence_id == 'SnC0204202F') %>%
    select(gcl_sequence_id, pire_sequence_id, extraction_id, individual_id, file)

# filter(!str_detect(file, 'clmp')) %>%

blat %>%
    filter(str_detect(file, extraction_id))

tmp %>%
    rowwise %>%
    filter(!is.null(seqs)) %>%
    slice(c(1,2,3)) %>%
    rowwise %>%
    mutate(join_seqs = regex_inner_join(wahab_seqs,
                                        seqs, 
                                        by = c('file' = 'individual_id')) %>%
               list())

filter(tmp$wahab_seqs[[1]],
       str_detect(file, 'Abu-CPnd_020'))




wahab_location <- pull_tbl(the_db, 'sequence_info_sheets') %>%
    nest(metadata = -c(hpc_path)) %>%
    filter(!is.na(hpc_path)) %>%
    get_wahab_data() %>%
    unnest(metadata)

wahab_location %>%
    nest(metadata = -c(species_code, era, site_id))


pull_tbl(the_db, "sequence_filename_sheets")








map_int(wahab_location$seqs, nrow) %>% sum()

renamed_seqs <- wahab_location  %>%
    unnest(seqs) %>%
    filter(str_detect(str_to_lower(file), str_c(species_code, '_', era, site_id) %>% str_to_lower()) |
               str_detect(str_to_lower(file), str_c(species_code, '-', era, site_id) %>% str_to_lower()))

not_renamed_seqs <- wahab_location %>%
    unnest(seqs) %>%
    anti_join(renamed_seqs,
              by = 'file') %>%
    filter(!str_detect(file, 'Undetermined')) %>%
    unnest(metadata)




joined_wahab_seqs <- wahab_seqs %>%
    regex_left_join(pull_tbl(the_db, 'sequence_filename_sheets') %>%
                        select(-starts_with('correction'), 
                               -sequence_filename_sheetsfile_path), 
                    by = c('file' = 'pire_sequence_id'))


    