#### Params ####
search_depth <- 10
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
library(tidytable)
library(forcats)
library(ssh)
library(fuzzyjoin)
library(mirai)

#### Functions ####
get_wahab_fq_list <- function(ssh_connection, directory, depth){
  #-maxdepth 2 #add after %s to set max depth to search
  if(is.null(ssh_connection)){
    res <- system2(
      "find",
      c(directory,
        "-maxdepth", as.character(depth),
        "-type", "f",
        "\\(", "-iname", "*.fq.gz", "-o", "-iname", "*.fastq.gz", "\\)",
        "-print"),
      stdout = TRUE
    )
    
    files <- sub(paste0("^", normalizePath(directory), "/"), "", res)
    files <- files[nzchar(files)]
    
  } else {
    the_command <- sprintf(
      str_c('find %s -maxdepth ', depth,' -type f \\( -iname "*.fq.gz" -o -iname "*.fastq.gz" \\) -printf "%%P\\n"'),
      shQuote(directory)
    )
    
    res <- ssh::ssh_exec_internal(ssh_connection, the_command, error = FALSE)
    
    files <- strsplit(rawToChar(res$stdout), "\n", fixed = TRUE)[[1]]
    files <- files[nzchar(files)]
  }
  
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

get_wahab_data <- function(df, depth = 2, func = get_wahab_fq_list, password){
  #func either can be get_wahab_decode_files or get_wahab_fq_list
  
  if(str_detect(Sys.info()['nodename'], '[a-z][0-9]-[a-z0-9]{6}-[0-9]{2}')){
    ssh_connection <- NULL
  } else {
    ssh_connection <- ssh_connect('jselwyn@wahab.hpc.odu.edu', passwd = password)
  }
  
  out <- map_dfr(df$hpc_path,
                 func, 
                 ssh_connection = ssh_connection,
                 depth = depth) %>%
    nest(wahab_seqs = -c(directory))
  
  if(!is.null(ssh_connection)){
    ssh_disconnect(ssh_connection)
  }
  
  full_join(df, out,
            by = c('hpc_path' = 'directory'))
}

adjust_ids <- function(string){
    stringr::str_to_lower(string) |>
        stringr::str_replace_all(c('_and_' = '&')) |>
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
            stringr::str_detect(adjust_ids(file_prefix), adjust_ids(extraction_id)) |
                stringr::str_detect(adjust_ids(file_prefix), adjust_ids(pire_sequence_id)) |
                stringr::str_detect(adjust_ids(file_prefix), adjust_ids(gcl_sequence_id)) |
                stringr::str_detect(adjust_ids(file_prefix), adjust_ids(individual_id))
        )
    },
    adjust_ids = adjust_ids
)

hash_md5 <- function(hpc_path, file) {
  full_path <- file.path(hpc_path, file)
  # tools::md5sum() returns a named vector; take the single value
  tools::md5sum(full_path)[[1]]
}

hash_parallel <- purrr::in_parallel(
  \(path, file) {
    hash_md5(path, file)
  },
  hash_md5 = hash_md5
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

select(all_metadata, seqs) %>%
  unnest(seqs) %>%
  distinct()

#### Get wahab sequences from specified directories ####
wahab_file <- here::here('scripts/database_transfer_from_onedrive/intermediate_files', 
                         str_c("wahab_files_d", search_depth,".rds.xz"))
if(file.exists(wahab_file) & !overwrite_files){
    wahab_seq_joined <- read_rds(wahab_file)
} else {
    the_pw <- askpass::askpass("Wahab password:")
    job::job({
        wahab_seq_joined <- filter(all_metadata, 
                                   !is.na(hpc_path)) %>%
            nest(data = -hpc_path) %>%
            get_wahab_data(depth = search_depth, password = the_pw) %>%
          mutate(match = str_c('wahab_row', row_number()))
        write_rds(wahab_seq_joined, wahab_file, compress = 'xz')
    })
    the_pw <- NULL
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
    the_pw <- askpass::askpass("Wahab password:")
    open_tracker_prep <- read_sheet(tracker_url, 
                                    sheet = 'Tracking Data') %>%
        janitor::clean_names() %>%
        mutate(project_type = str_replace(project_type, ', ', '/') %>%
                   fct_relevel('genome/ssl', after = 0)) %>%
        distinct(species_code,
                 raw_sequence_directory) %>%
        filter(!if_any(everything(), is.na)) %>%
        rowwise(species_code) %>%
        reframe(hpc_path = str_split(raw_sequence_directory, '\n') %>%
                    unlist)
    
    job::job({
        open_tracker_seqs <- open_tracker_prep %>%
            get_wahab_data(depth = search_depth, password = the_pw) %>%
          mutate(match = str_c('osci_row', row_number()))
        write_rds(open_tracker_seqs, openScience_file, compress = 'xz')
    })
    the_pw <- NULL
}

open_tracker_seqs %>%
    mutate(hpc_path = dirname(hpc_path)) %>%
    left_join(wahab_seq_joined,
              by = c('hpc_path'))

#### Get all raw files ####
all_raw_files <- bind_rows(select(wahab_seq_joined, -data),
                           select(open_tracker_seqs, -species_code)) %>%
  unnest(wahab_seqs) %>%
  filter(!is.na(file)) %>%
  mutate(file = file.path(hpc_path, file),
         hpc_path = dirname(file),
         file = basename(file)) %>%
  summarise(.by = c(hpc_path, file),
            match = unique(match) %>% sort %>% str_c(collapse = ';')) %>%
  
  #remove files & directories definitely not raw
  filter(!is.na(file),
         !str_detect(file, '(tagged_filter)|(fail.fq.gz$)|(unprd.fq.gz$)|(unpaired)|(cor.fastq.gz$)|(trimmed_merged.fastq.gz$)')) %>%
  filter(!str_detect(hpc_path, '(_fp1)|(mkBAM)|(GenErode)|(mkVCF)|(mitoZ)|(oldfqgz)|(dDocentHPC/test)')) %>%
  
  #Split forward/reverse reads
  mutate(read_suffix = str_extract(file, '([._-])?([rR])?[12](.tagged)?(_filter)?(ed)?(_trimmed)?(_unmerged)?.f(ast)?q.gz$'),
         file_prefix = str_remove(file, read_suffix),
         read_direction = str_extract(read_suffix, '[12]'),
         read_direction = if_else(read_direction == '1', 'forward', 'reverse')) %>%
  select(-read_suffix) %>%
  distinct() %>%
  pivot_wider(names_from = read_direction,
              values_from = file)

#### Get Hashes for all files ####
# use to check not missing things later after the matching step
hash_file <- here::here('scripts/database_transfer_from_onedrive/intermediate_files', 
                        str_c("hash_file_d", search_depth,".csv.xz"))
if(file.exists(hash_file) & !overwrite_files){
  all_raw_files_hash <- read_csv(hash_file, show_col_types = FALSE)
} else {
  mirai::daemons(n = parallelly::availableCores())
  
  all_raw_files_hash <- all_raw_files %>%
    
    # sample_n(10) %>%
    
    pivot_longer(cols = c(forward, reverse),
                 names_to = 'read_direction',
                 values_to = 'file') %>%
    mutate(hash = purrr::map2_chr(hpc_path, file,
                                  hash_parallel,
                                  .progress = TRUE)) %>%
    pivot_wider(names_from = read_direction,
                values_from = c('file', 'hash'))
  mirai::daemons(n = 0)
  
  write_csv(all_raw_files_hash, hash_file)
}

deduped_files <- all_raw_files_hash %>%
  # filter(n() > 1, 
  #        .by = c(hash_forward, hash_reverse)) %>%
  summarise(.by = c(hash_forward, hash_reverse),
            match = str_split(match, ';') %>%
              unlist %>%
              unique %>%
              sort %>%
              str_c(collapse = ';'),
            file_info = tibble(file_prefix, hpc_path, file_forward, file_reverse) %>%
              distinct %>% list) %>%
  mutate(file_pair = str_c('file_pair.', row_number()),
         .before = match) %>%
  select(-starts_with('hash'))

deduped_files

#### Relink the raw files and the metadata ####
metadata_flat <- wahab_seq_joined %>%
  select(-wahab_seqs, 
         -hpc_path) %>%
  unnest(data) %>%
  nest(data = -c(species_code)) %>%
  full_join(select(open_tracker_seqs, 
                   -hpc_path, -wahab_seqs) %>%
              rename(os_match = match),
            by = c('species_code')) %>%
  unnest(data) %>%
  rename(db_match = match) %>%
  pivot_longer(cols = c(starts_with('db'),
                        starts_with('os')),
               names_to = c("seqs_type", ".value"),
               names_pattern = "(db|os)_(.*)") %>%
  mutate(seqs_type = case_when(str_detect(seqs_type, 'db') ~ 'database',
                               str_detect(seqs_type, 'os') ~ 'open_science')) %>%
  unnest(seqs) %>%
  
  #Remove rows that the species/era/site from the sequence batch sheet doesn't match the individual ID from the individuals_sheet
  filter(str_detect(individual_id, 
                    str_c(species_code, '-', str_sub(era, 1, 1), site_id))) %>%
  select(-seqs_type) %>%
  distinct()

metadata_flat

#### Match Metadata with Files ####
matchID_file <- here::here('scripts/database_transfer_from_onedrive/intermediate_files', 
                           str_c("matchID_files_d", search_depth,".csv.xz"))
if(file.exists(matchID_file) & !overwrite_files){
  matched_ids <- read_csv(matchID_file, show_col_types = FALSE)
} else {
  mirai::daemons(n = parallelly::availableCores())
  
  matched_ids <- deduped_files %>%
    unnest(file_info) %>%
    mutate(file_prefix_simp = adjust_ids(file_prefix),
           match = str_split(match, ';')) %>%
    unnest(match) %>%
    nest(file_data = -c(match)) %>%
    inner_join(nest(metadata_flat,
                    metadata = -c(match)),
               by = 'match') %>%
    tidyr::unnest(metadata) 
  
  
  # matched_ids$file_data[[1]] %>%
  #   filter(str_detect(file_prefix, 'Mat'))
  #need to match files with individuals and choose which of duplicated files to keep
  
  matched_ids <- matched_ids %>%
    # slice(1) %>%
    # sample_n(1000) %>%
    mutate(file_data = purrr::pmap(list(file_data,
                                         extraction_id,
                                         pire_sequence_id,
                                         gcl_sequence_id,
                                         individual_id),
                                    match_wahab_parallel,
                                    .progress = TRUE)) %>%
    tidyr::unnest(file_data, keep_empty = FALSE) %>%
    distinct
  mirai::daemons(n = 0)
  
  write_csv(matched_ids, matchID_file)
}

n_distinct(matched_ids$match) 
n_distinct(matched_ids$file_pair) 
distinct(matched_ids, ends_with('_id'), -sequencing_batch_id, -site_id)

matched_ids %>%
  summarise(.by = c(gcl_sequence_id, pire_sequence_id, extraction_id, individual_id),
            across(everything(), n_distinct)) %>%
  summarise(across(where(is.numeric), mean))

matched_ids %>%
  summarise(.by = c(file_pair),
            n = n(),
            across(everything(), n_distinct)) %>%
  summarise(across(where(is.numeric), mean))


matched_ids %>%
  filter(file_pair == 'file_pair.100') %>%
  select(-file_prefix_simp) %>%
  select(where(~ n_distinct(.) > 1)) %>%
  select(-file_forward, -file_reverse, -match) %>%
  select(-hpc_path)
  distinct(file_prefix, hpc_path)

#### OLD BELOW ####
  
#### Filter to match ids with wahab seqs ####
matchID_file <- here::here('scripts/database_transfer_from_onedrive/intermediate_files', 
                               str_c("matchID_files_d", search_depth,".csv.xz"))
if(file.exists(matchID_file) & !overwrite_files){
    matched_ids <- read_csv(matchID_file, show_col_types = FALSE)
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
                             .progress = TRUE)) %>%
      unnest(wahab_seqs, keep_empty = TRUE)
  
  mirai::daemons(n = 0)
  
  write_csv(matched_ids, matchID_file)
}

tmp <- matched_ids %>%
    filter(!is.na(file),
           !is.na(extraction_id),
           !str_detect(file, '(tagged_filter)|(fail.fq.gz$)|(unprd.fq.gz$)|(unpaired)|(cor.fastq.gz$)|(trimmed_merged.fastq.gz$)')) %>%
  
  #Remove rows that the species/era/site from the sequence batch sheet doesn't match the individual ID from the individuals_sheet
  filter(str_detect(individual_id, 
                    str_c(species_code, '-', str_sub(era, 1, 1), site_id))) %>%
  
  #Split forward and reverse reads up
  mutate(file = file.path(wahab_path, file),
         wahab_path = dirname(file),
         file = basename(file)) %>%
  mutate(read_suffix = str_extract(file, '([._-])?([rR])?[12](.tagged)?(_filter)?(ed)?(_trimmed)?(_unmerged)?.f(ast)?q.gz$'),
         file_prefix = str_remove(file, read_suffix),
         read_direction = str_extract(read_suffix, '[12]'),
         read_direction = if_else(read_direction == '1', 'forward', 'reverse')) %>%
  select(-read_suffix) %>%
  distinct() %>%
  pivot_wider(names_from = 'read_direction',
              values_from = file) %>%
  
  #Remove paths that don't contain raw reads
  filter(!str_detect(wahab_path, '(_fp1)|(mkBAM)|(GenErode)|(mkVCF)|(mitoZ)|(oldfqgz)')) %>%
  
  #remove mismatches btwn seq types
  filter(((str_detect(str_to_lower(sequencing_batch_id), 'lcwgs') & 
             str_detect(str_to_lower(wahab_path), 'lcwgs')) |
            (str_detect(str_to_lower(sequencing_batch_id), '(?<!c)ssl') & 
               str_detect(str_to_lower(wahab_path), '(?<!c)ssl|shotgun')) |
            (str_detect(str_to_lower(sequencing_batch_id), 'cssl') & 
               str_detect(str_to_lower(wahab_path), 'cssl')) |
            (!str_detect(str_to_lower(wahab_path), 'ssl|shotgun|lcwgs|cssl')))) %>%
  
  #Remove duplicates from simply different original sourcing pointing to the same files/paths
  select(-seqs_type) %>%
  distinct %>%
  
  #If no sequencing run match with batch_id that says 1. If there is a sequencing run then match the numbers
  filter(case_when(!str_detect(wahab_path, '(1st|2nd|3rd|4th|5th)_sequencing_run') & str_detect(sequencing_batch_id, '1$') ~ TRUE,
                   str_detect(wahab_path, '(1st|2nd|3rd|4th|5th)_sequencing_run') & 
                     str_detect(str_extract(wahab_path, '(1st|2nd|3rd|4th|5th)_sequencing_run'), str_sub(sequencing_batch_id, -1)) ~ TRUE,
                   TRUE ~ FALSE))

nest(tmp,
     data = -c(wahab_path, file_prefix, forward, reverse)) %>%
  full_join(all_raw_files,
            by = c('wahab_path' = 'hpc_path', 'file_prefix', 
                   'forward', 'reverse')) %>%
  filter(map_lgl(data, is.null)) %>%
  distinct(wahab_path)


#### Testing Below ####

# file <- tmp$file[[1]]; matched_data <- tmp$data[[1]]
find_likely_match <- function(file, matched_data){
  dplyr::mutate(matched_data,
                dplyr::across(dplyr::everything(),
                              adjust_ids),
                dplyr::across(dplyr::everything(),
                              stringr::str_replace_na)) |>
    dplyr::mutate(dplyr::across(dplyr::everything(),
                                ~stringr::str_detect(adjust_ids(file), .)),
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
    filter_matched <- read_csv(filter_matched_file, show_col_types = FALSE)
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


filter_matched %>%
    slice(1) %>%
    select(file) %>%
    mutate(read_suffix = str_extract(file, '([._-])?([rR])?[12](.tagged)?(_filter)?(ed)?.f(ast)?q.gz$'),
           file_prefix = str_remove(file, read_suffix),
           read_direction = str_extract(read_suffix, '[12]'),
           read_direction = if_else(read_direction == '1', 'forward', 'reverse'))
    



tmp <- filter_matched %>%
    #Remove mismatches btwn site/era/species that got through
    filter(!str_detect(file, 'tagged_filter'),
           str_detect(individual_id, 
                      str_c(species_code, '-', str_sub(era, 1, 1), site_id))) %>%
    mutate(file = file.path(wahab_path, file),
           wahab_path = dirname(file),
           file = basename(file)) %>%
    mutate(read_suffix = str_extract(file, '([._-])?([rR])?[12](.tagged)?(_filter)?(ed)?.f(ast)?q.gz$'),
           file_prefix = str_remove(file, read_suffix),
           read_direction = str_extract(read_suffix, '[12]'),
           read_direction = if_else(read_direction == '1', 'forward', 'reverse')) %>%
    select(-read_suffix) %>%
    distinct() %>%
    pivot_wider(names_from = 'read_direction',
                values_from = file) %>%
    
    # Remove fqgz pipeline reads
    filter(!str_detect(wahab_path, '_fp1')) %>%
    
    #remove mismatches btwn seq types
    filter(((str_detect(str_to_lower(sequencing_batch_id), 'lcwgs') & 
                 str_detect(str_to_lower(wahab_path), 'lcwgs')) |
                (str_detect(str_to_lower(sequencing_batch_id), 'ssl') & 
                     str_detect(str_to_lower(wahab_path), 'ssl|shotgun')) |
                (str_detect(str_to_lower(sequencing_batch_id), 'cssl') & 
                     str_detect(str_to_lower(wahab_path), 'cssl')) |
                (!str_detect(str_to_lower(wahab_path), 'ssl|shotgun|lcwgs|cssl')))) %>%
    
    #If any of the pire_sequence_ids matches the file_prefix then keep only that one. Otherwise keep them all
    mutate(has_match = any(adjust_ids(pire_sequence_id) == adjust_ids(file_prefix)),
           .by = file_prefix) %>%
    filter((!has_match | adjust_ids(pire_sequence_id) == adjust_ids(file_prefix)),
           .by = file_prefix) %>%
    select(-has_match) 





wong <- tmp %>%
    
    #If any of the extraction_id matches the file_prefix then keep only that one. Otherwise keep them all
    mutate(has_match = any(adjust_ids(pire_sequence_id) == adjust_ids(file_prefix)),
           .by = extraction_id) %>%
    filter(!(!has_match | adjust_ids(pire_sequence_id) == adjust_ids(file_prefix)),
           .by = extraction_id) %>%
    select(-has_match) 
    
wong %>%
    select(pire_sequence_id:individual_id, file_prefix)

filter(tmp,
       individual_id == 'Sde-AMar_055') %>%
    select(gcl_sequence_id, pire_sequence_id:individual_id, file_prefix)




blat <- tmp %>%
    nest(file_info = c(gcl_sequence_id, pire_sequence_id,
                       seqs_type, file_prefix,
                       wahab_path, forward, reverse))

blat %>%
    slice(1) %>%
    select(file_info) %>%
    unnest(file_info) %>%
    select(pire_sequence_id, file_prefix) %>%
    mutate(across(everything(), adjust_ids)) %>%
    filter(file_prefix == pire_sequence_id)


blat$file_info[[2]]


distinct(tmp, wahab_path) %>%
    mutate(pire_dir = str_extract(wahab_path, 'pire_.*/') %>%
               str_remove('/.*$')) %>%
    distinct(pire_dir) %>% View

distinct(tmp, wahab_path) %>%
    filter(str_detect(wahab_path, 'pire_assembler_comparison'))
'pire_assembler_comparison'


tmp %>%
    filter(!str_detect(wahab_path, '_fp1')) %>%
    count(wahab_path) %>%
    slice(-1:-10)

# filter(tmp,
#        str_detect(wahab_path, '/RC/group/rc_carpenterlab_ngs/shotgun_PIRE/pire_ssl_data_processing/ostorhinchus_chrysopomus')) %>%
#     # filter(individual_id == 'Och-CTum_001') 
#     
tmp

%>%
    
    filter(wahab_path %in% c('/archive/carpenterlab/pire/pire_spratelloides_delicatulus_cssl/2nd_sequencing_run/fq_raw'))

blat <- 

wham <- mutate(blat, 
       n_processed = map_int(file_info,
                             ~filter(.x, str_detect(wahab_path, '_fp1')) %>%
                                 nrow()),
       n_total = map_int(file_info, nrow))

filter(wham,
       individual_id == 'Cvi-CPal_011') %>%
    select(file_info) %>%
    unnest(file_info)



filter(wham,
       n_processed == n_total) %>% View
    filter(n_total > 1) %>%
    slice(1) %>%
    select(file_info) %>%
    unnest(file_info) %>%
    # select(wahab_path, forward) %>%
    distinct()

str_count(blat$file_info[[2]]$wahab_path, '_fp1')

blat$file_info[[2]] %>%
    filter(wahab_path == '/archive/carpenterlab/pire/pire_spratelloides_delicatulus_cssl/2nd_sequencing_run/fq_fp1')
    count(wahab_path)


    
count(tmp, 
      wahab_path) %>%
    filter(!str_detect(wahab_path, 'raw')) %>%
    filter(str_detect(wahab_path, '_fp1')) %>% View

filter(tmp,
       extraction_id == 'Sde-AMat_002-Ex1') %>%
    select(-gcl_sequence_id, -pire_sequence_id) %>%
    distinct

tmp %>%
    select(-gcl_sequence_id, -pire_sequence_id) %>%
    distinct %>%
    nest(files = c(wahab_path, forward, reverse)) %>% 
    filter(file_prefix == 'Sde-AMat_002-Ex1-cssl2') %>%
    select(-gcl_sequence_id, -pire_sequence_id) %>%
    distinct() %>%
    unnest(files) %>%
    select(sequencing_batch_id, wahab_path)
    slice(1) %>%
    select(file_prefix)
    filter(n() > 1,
           .by = file_prefix)



blat <- nest(filter_matched, 
             data = -c(wahab_path, file)) %>%
    mutate(full_path = file.path(wahab_path, file),
           .keep = 'unused',
           .before = everything()) %>%
    mutate(path = dirname(full_path),
           file = basename(full_path),
           .keep = 'unused',
           .before = everything()) %>%
    unnest(data) %>%
    summarise(.by = c(everything(), -seqs_type),
              seqs_type = unique(seqs_type) %>% 
                  str_c(collapse = '; '))

select(blat, path, file)

tmp <- blat %>%
    filter(!str_detect(file, 'tagged_filter')) %>%
    mutate(read_suffix = str_extract(file, '([rR])?[12](.tagged)?(_filter)?(ed)?.f(ast)?q.gz$'),
           file_prefix = str_remove(file, read_suffix),
           read_direction = str_extract(read_suffix, '[12]'),
           read_direction = if_else(read_direction == '1', 'forward', 'reverse')) %>%
    select(-read_suffix) %>%
    pivot_wider(names_from = 'read_direction',
                values_from = 'file') 

tmp %>%
    nest(hpc_info = c(path, forward, reverse)) %>%
    sample_n(10)
    slice(1:4)

select(tmp,
       path) %>%
    mutate(end_path = basename(path)) %>%
    count(end_path) %>%
    arrange(-n)

tmp |>
    dplyr::summarise(n = dplyr::n(), .by = c(species_code, era, gcl_sequence_id, pire_sequence_id, extraction_id, individual_id, sequencing_batch_id, site_id,
                                             seqs_type, file_prefix, read_direction)) |>
    dplyr::filter(n > 1L) 

tmp %>%
    filter(gcl_sequence_id == 'SdA02055') %>%
    pivot_wider(names_from = 'read_direction',
                values_from = 'file',
                values_fn = ~str_c(., collapse = ';;')) %>%
    select(forward) %>%
    filter(str_detect(forward, ';;')) %>%
    slice(1) %>%
    pull(forward)
    
"/archive/carpenterlab/pire/pire_spratelloides_delicatulus_cssl/2nd_sequencing_run/fq_raw/Sde-AMar_055-Ex1b-cssl2.1.fq.gz"
"/archive/carpenterlab/pire/pire_spratelloides_delicatulus_cssl/2nd_sequencing_run/fq_fp1/Sde-AMar_055-Ex1b-cssl2.r1.fq.gz"


blat$metadata[[1]] %>%
    select(-seqs_type) %>%
    distinct()

blat %>%
    summarise(.by = c(everything(), -seqs_type),
          seqs_type = unique(seqs_type) %>% 
              str_c(collapse = '; ')) %>%
    select(seqs_type)

blat %>%
    slice(1:100) %>%
    summarise(.by = c(everything(), -seqs_type),
              seqs_type = unique(seqs_type) %>% 
                  str_c(collapse = '; '))

sample_n(filter_matched,
         1000)

tmp <- filter_matched %>%
    nest(data = -c(seqs_type, wahab_path))


tmp %>%
    full_join(select(wahab_seq_joined, -data),
              by = c('wahab_path' = 'hpc_path')) %>%
    full_join(select(open_tracker_seqs, -species_code),
              by = c('wahab_path' = 'hpc_path')) %>%
    # mutate(wahab_seqs = coalesce(wahab_seqs.x, wahab_seqs.y),
    #        .keep = 'unused') %>%
    filter(is.na(seqs_type)) %>%
    filter(!map_lgl(wahab_seqs.y, is.null))

filter(wahab_seq_joined,
       hpc_path == '/archive/carpenterlab/pire/pire_pomacentrus_brachialis_lcwgs/1st_sequencing_run')

select(filter_matched,
       file) %>%
    slice(-1:-500)


all_metadata %>%
  unnest(seqs) %>%
  anti_join(filter_matched)
#### Research what files that were found but not associated with sample go with ####
filter_matched %>% 
  # filter(file == 'Sde-AMat_002-Ex1-cssl2.2.fq.gz') %>%
  # select(-species_code:-pire_sequence_id) %>%
  # distinct()
  filter(n() > 1,
         .by = file) %>%
  nest(data = -c(file)) 

tmp <- filter_matched %>%
  nest(data = -c(file))

in_wahab <- select(wahab_seq_joined, wahab_seqs) %>%
  unnest(wahab_seqs) %>%
  left_join(tmp, by = 'file') %>%
  # slice(10422)
  mutate(has_hits = !map_lgl(data, is.null)) 

in_wahab %>%
  # filter(has_hits)
  count(has_hits) 

filter(in_wahab, !has_hits) %>%
  filter(!is.na(file),
         !str_detect(file, '[uU]ndetermined'),
         !str_detect(file, 'depracated'),
         !str_detect(file, 'repr'),
         !str_detect(file, 'clmp')) %>%
  select(file)

  
in_opensci <- select(open_tracker_seqs, wahab_seqs) %>%
  unnest(wahab_seqs) %>%
  left_join(tmp, by = 'file') %>%
  mutate(has_hits = !map_lgl(data, is.null)) 

in_opensci %>%
  # filter(has_hits)
  count(has_hits)

filter(in_opensci, !has_hits) %>%
  filter(!is.na(file),
         !str_detect(file, '[uU]ndetermined')) %>%
  select(file) %>%
  filter(!str_detect(file, 'Shotgun'),
         !str_detect(file, 'GEOME'))

anti_join(tmp,
          select(open_tracker_seqs, wahab_seqs) %>%
            unnest(wahab_seqs) %>%
            left_join(tmp, by = 'file'),
          by = 'file') %>%
  anti_join(select(wahab_seq_joined, wahab_seqs) %>%
              unnest(wahab_seqs),
            by = 'file')





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


    