#### Params ####
search_depth <- 2
overwrite_files <- FALSE

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
library(googlesheets4)
library(forcats)
library(ssh)
library(fuzzyjoin)
library(mirai)

#### Functions ####
get_wahab_fq_list <- function(ssh_connection, directory, depth){
    #-maxdepth 2 #add after %s to set max depth to search
    the_command <- sprintf(
        str_c('find %s -maxdepth ', depth,' -type f \\( -iname "*.fq.gz" -o -iname "*.fastq.gz" \\) -printf "%%P\\n"'),
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

get_wahab_decode_files <- function(ssh_connection, directory){
    the_command <- sprintf(
        'find %s -type f -iname "*decode*" -printf "%%P\\n"',
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

get_wahab_data <- function(df, depth = 2, func = get_wahab_fq_list){
    #func either can be get_wahab_decode_files or get_wahab_fq_list
    ssh_connection <- ssh_connect('jselwyn@wahab.hpc.odu.edu')
    out <- map_dfr(df$hpc_path,
                   func, 
               ssh_connection = ssh_connection,
               depth = depth) %>%
        nest(wahab_seqs = -c(directory))
    
    ssh_disconnect(ssh_connection)
    full_join(df, out,
              by = c('hpc_path' = 'directory'))
}

adjust_ids <- function(string){
    stringr::str_to_lower(string) |>
        stringr::str_remove_all(' |-|_|:|\\.')
}

# adjust_ids('this.is-a_test:hereAAA')

match_wahab_parallel <- purrr::in_parallel(
    \(wahab_seqs,
      extraction_id,
      pire_sequence_id,
      gcl_sequence_id,
      individual_id) {
        
        # handle empty / NULL cases defensively
        if (is.null(wahab_seqs) || nrow(wahab_seqs) == 0) {
            return(wahab_seqs)
        }
        
        ids <- c(extraction_id, pire_sequence_id, gcl_sequence_id, individual_id)
        ids <- ids[!is.na(ids) & nzchar(ids)]
        
        if (!length(ids)) {
            return(wahab_seqs[0, , drop = FALSE])
        }
        
        # your matching logic, slightly tidied
        dplyr::filter(
            wahab_seqs,
            stringr::str_detect(adjust_ids(file), adjust_ids(extraction_id)) |
                stringr::str_detect(adjust_ids(file), adjust_ids(pire_sequence_id)) |
                stringr::str_detect(adjust_ids(file), adjust_ids(gcl_sequence_id)) |
                stringr::str_detect(adjust_ids(file), adjust_ids(individual_id))
        )
    },
    adjust_ids = adjust_ids
)

#### Get all Wahab Decodes ####
# wahab_decodes <- tibble(hpc_path = c('/home/e1garcia',
#                                      '/archive/carpenterlab/pire',
#                                      '/RC/group/rc_carpenterlab_ngs')) %>%
#     get_wahab_data(get_wahab_decode_files)

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
wahab_file <- here::here('scripts/database_transfer_from_onedrive/intermediate_files', 
                         str_c("wahab_files_d", search_depth,".rds.xz"))
if(file.exists(wahab_file) & !overwrite_files){
    wahab_seq_joined <- read_rds(wahab_file)
} else {
    wahab_seq_joined <- filter(all_metadata, 
                               !is.na(hpc_path)) %>%
        nest(data = -hpc_path) %>%
        get_wahab_data(depth = search_depth)
    write_rds(wahab_seq_joined, wahab_file, compress = 'xz')
}

select(wahab_seq_joined, hpc_path, wahab_seqs) %>%
    unnest(wahab_seqs) %>%
    filter(str_detect(file, 'fq_raw'))

#### Get WAHAB Seqs from open science tracker ####
openScience_file <- here::here('scripts/database_transfer_from_onedrive/intermediate_files', 
                         str_c("openScience_files_d", search_depth,".rds.xz"))
if(file.exists(openScience_file) & !overwrite_files){
    open_tracker_seqs <- read_rds(openScience_file)
} else {
    tracker_url <- 'https://docs.google.com/spreadsheets/d/1x_LQ6XiB8N-3QPxSw4Zj-3VF-TaRycAPE-06iRBAUAI/edit?gid=0#gid=0'
    open_tracker_seqs <- read_sheet(tracker_url, 
                                    sheet = 'Tracking Data') %>%
        janitor::clean_names() %>%
        mutate(project_type = str_replace(project_type, ', ', '/') %>%
                   fct_relevel('genome/ssl', after = 0)) %>%
        distinct(species_code,
                 raw_sequence_directory) %>%
        filter(!if_any(everything(), is.na)) %>%
        rowwise(species_code) %>%
        reframe(hpc_path = str_split(raw_sequence_directory, '\n') %>%
                    unlist) %>%
        get_wahab_data(depth = search_depth)
    write_rds(open_tracker_seqs, openScience_file, compress = 'xz')
}


open_tracker_seqs %>%
    mutate(hpc_path = dirname(hpc_path)) %>%
    left_join(wahab_seq_joined,
              by = c('hpc_path'))


#### Filter to match ids with wahab seqs ####
matchID_file <- here::here('scripts/database_transfer_from_onedrive/intermediate_files', 
                               str_c("matchID_files_d", search_depth,".rds.xz"))
if(file.exists(matchID_file) & !overwrite_files){
    matchID_file <- read_rds(matchID_file)
} else {
  mirai::daemons(n = parallelly::availableCores())
  
  matched_ids <- wahab_seq_joined %>%
    unnest(data) %>%
    nest(data = -c(species_code)) %>%
    full_join(rename(open_tracker_seqs,
                     os_path = hpc_path,
                     os_seqs = wahab_seqs),
              by = c('species_code')) %>%
    unnest(data) %>%
    rename(db_path = hpc_path,
           db_seqs = wahab_seqs) %>%
    pivot_longer(cols = c(starts_with('db'),
                          starts_with('os')),
                 names_to = c("seqs_type", ".value"),
                 names_pattern = "(db|os)_(.*)",
                 names_transform = ~str_c('wahab_', .)) %>%
    mutate(seqs_type = case_when(str_detect(seqs_type, 'db') ~ 'database',
                                 str_detect(seqs_type, 'os') ~ 'open_science')) %>%
    unnest(seqs) %>%
    filter(!map_lgl(wahab_seqs, is.null)) %>%
    # sample_n(1000) %>%
    mutate(wahab_seqs = pmap(list(wahab_seqs,
                                  extraction_id,
                                  pire_sequence_id,
                                  gcl_sequence_id,
                                  individual_id),
                             match_wahab_parallel,
                             .progress = TRUE))
  
  mirai::daemons(n = 0)
  
  write_rds(matched_ids, matchID_file, compress = 'xz')
}

matched_ids

# file <- tmp$file[[1]]; matched_data <- tmp$data[[1]]
find_likely_match <- function(file, matched_data){
  dplyr::mutate(matched_data,
                dplyr::across(dplyr::everything(),
                              adjust_ids),
                dplyr::across(dplyr::everything(),
                              stringr::str_replace_na)) |>
    dplyr::mutate(dplyr::across(dplyr::everything(),
                                ~stringr::str_detect(stringr::str_to_lower(file), .)),
                  row_id = dplyr::row_number()) |>
    dplyr::rowwise() |>
    dplyr::mutate(n_hits = sum(dplyr::c_across(dplyr::where(is.logical)))) |>
    dplyr::ungroup() |>
    dplyr::filter(n_hits == max(n_hits)) |>
    dplyr::select(row_id) |>
    dplyr::left_join(dplyr::mutate(matched_data, 
                         row_id = dplyr::row_number()),
                  by = 'row_id') |>
    dplyr::select(-row_id)
}

find_likely_match_parallel <- purrr::in_parallel(
  \(file, matched_data) {
    find_likely_match(file, matched_data)
  },
  # captured for the workers:
  adjust_ids = adjust_ids,
  find_likely_match = find_likely_match
)

filter_matched_file <- here::here('scripts/database_transfer_from_onedrive/intermediate_files', 
                                  str_c("filterMatchID_files_d", search_depth,".csv.xz"))
if(file.exists(filter_matched_file) & !overwrite_files){
  filter_matched_file <- read_csv(filter_matched_file, show_col_types = FALSE)
} else {
  mirai::daemons(n = parallelly::availableCores())
  filter_matched <- matched_ids %>%
    unnest(wahab_seqs, keep_empty = FALSE) %>% 
    nest(data = -c(file)) %>%
    # sample_n(1000) %>%
    mutate(data = pmap(list(file, data),
                       find_likely_match_parallel,
                       .progress = TRUE)) %>%
    unnest(data)
  mirai::daemons(n = 0)
  write_csv(filter_matched, filter_matched_file)
}




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


    