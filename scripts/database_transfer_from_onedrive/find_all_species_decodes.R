#### Setup & Get database ####
#use github to clone the database repo into the top level of this repo
source("../../.Rprofile")

##

library(ssh)
library(tidyverse)

tamucc_onedrive <- "C:/Users/jdsel/Texas A&M University-Corpus Christi/Bird, Chris - GCL_2.0/Customers/Bird, Chris/prj_philippines_pire_lab"
tamucc_hpc_dir <- "/work/birdlab/GCL"
wahab_pire_dir <- ""

#### Functions ####
get_tamucc_pire_directories <- function(ssh_connection, pire_strings = c('PIRE')){
  
  the_command <- str_c("*", 
        pire_strings,
        "*") %>%
    shQuote() %>%
    sprintf("-iname %s", 
            .) %>%
    str_c(collapse = ' -o ') %>%
    sprintf('find %s -maxdepth 1 -type d \\( %s \\) -printf "%%p\\n" 2>/dev/null',
            shQuote(tamucc_hpc_dir),
            .)
  
  res <- ssh_exec_internal(ssh_connection, 
                           the_command)
  
  dirs <- strsplit(rawToChar(res$stdout), "\n", fixed = TRUE)[[1]]
  dirs <- dirs[nzchar(dirs)]
  dirs
}

get_tamucc_fq_list <- function(ssh_connection, directory){
  # directory: remote directory (character scalar)
  # ssh_connection: an active ssh::ssh_connect() object
  
  # Command: list files ending in .fq.gz or .fastq.gz (non-recursive)
  the_command <- sprintf(
    'find %s -maxdepth 1 -type f \\( -iname "*.fq.gz" -o -iname "*.fastq.gz" \\) -printf "%%f\\n" 2>/dev/null',
    shQuote(directory)
  )
  
  res <- ssh::ssh_exec_internal(ssh_connection, the_command)
  files <- strsplit(rawToChar(res$stdout), "\n", fixed = TRUE)[[1]]
  files <- files[nzchar(files)]
  
  # If no files, keep directory with NA in file column
  if (length(files) == 0) {
    tibble::tibble(directory = directory, file = NA_character_)
  } else {
    tibble::tibble(directory = directory, file = files)
  }
}

get_tamucc_hpc_data <- function(){
  ssh_connection <- ssh_connect('jselwyn@crest-files.tamucc.edu')
  
  out <- get_tamucc_pire_directories(ssh_connection) %>%
    map_dfr(get_tamucc_fq_list, 
            ssh_connection = ssh_connection)
  
  ssh_disconnect(ssh_connection)
  out
}

# decode_file <- file.path(tamucc_onedrive, "Plotosus lineatus/Pli-LCWGS-FullSeq_SequenceNameDecode.tsv")
read_decode_file <- function(decode_file){
  read_delim(decode_file,
             delim = '\t', 
             show_col_types = FALSE,
             col_names = FALSE) %>% #View
        
        
    
    #Deal with naming inconsistencies
    mutate(.row_id = row_number()) %>%     
    pivot_longer(-c(.row_id), 
                 names_to = "source_col", 
                 values_to = "val") %>%
    filter(!is.na(val),
           !val %in% c('Sequence_Name', 'Extraction_ID', 
                       'Individual_ID', 'Sequence Name')) %>%                      
    mutate(kind = case_when(str_detect(decode_file, "Adu_LCWGS-TestLane_SequenceNameDecode.tsv") & 
                                str_detect(val, "AdA16_") ~ "original_file",
                            str_detect(decode_file, "Och_LCWGS-FullSeq2_SequenceNameDecode.tsv") & 
                                str_detect(val, "OchACat039_") ~ "original_file",
                            str_detect(decode_file, "Pli-LCWGS-FullSeq_SequenceNameDecode.tsv") & 
                                str_detect(val, "_1$|_2$") ~ "original_file",
                            str_detect(decode_file, "Pli-LCWGS-Reseq_SequenceNameDecode.tsv") & 
                                str_detect(val, "_1$|_2$") ~ "original_file",
                            str_detect(val, "[-_]") ~ "renamed_file",
                            TRUE ~ "original_file")) %>%
    group_by(.row_id, kind) %>% 
    summarise(val = dplyr::first(val), .groups = "drop") %>%
    pivot_wider(names_from = kind, values_from = val) %>%
    select(original_sequence_id = original_file, 
           renamed_sequence_id = renamed_file) 
}

get_decodes <- function(){
  list.files(path = tamucc_onedrive, 
             recursive = TRUE, 
             pattern = 'tsv$') %>%
    str_subset('[Dd]ecode') %>%
    tibble(decode_file = .) %>%
    rowwise(decode_file) %>%
    reframe(read_decode_file(file.path(tamucc_onedrive, 
                                       decode_file)))
}

find_extraction_ids <- function(decode_data,
                                mislabelled_ids_path = '../../db_files/extractions_mislabelling_sheet.csv'){
    correction_data <- read_csv(mislabelled_ids_path, show_col_types = FALSE) %>%
        select('renamed_sequence_id' = 'Original_Sequence_ID', 
               'extraction_id' = "Original_Extraction_ID", 
               'fixed_extraction_id' = "Corrected_Extraction_ID")
    
    decode_data %>%
        mutate(extraction_id = str_extract(renamed_sequence_id, 
                                       "^.*[0-9]{3}([- _]E(x*)?[\\d\\?])?") %>%
               str_replace_all(c('Exx1' = 'Ex1',
                                 " E1" = '-Ex1',
                                 "Ex\\?" = "Ex1",
                                 "Aen-Cbat_" = "Aen-CBat_",
                                 "_Ex1" = '-Ex1',
                                 "CNas-" = "CNas_",
                                 "CPas-" = "CPas_",
                                 "ARag-" = "ARag_",
                                 "Och_CTum" = "Och-CTum",
                                 "_Ex2" = "-Ex2",
                                 "_E1" = "-Ex1")),
           extraction_id = case_when(str_detect(extraction_id, 'Aen-AHam_') & !str_detect(extraction_id, 'Ex*$') ~ str_c(extraction_id, '-Ex1'),
                                     str_detect(extraction_id, 'Aen-CBat_') & !str_detect(extraction_id, 'Ex*$') ~ str_c(extraction_id, '-Ex1'),
                                     str_detect(extraction_id, 'Lle-AHam_') & !str_detect(extraction_id, 'Ex*$') ~ str_c(extraction_id, '-Ex1'),
                                     str_detect(extraction_id, 'Lle-CNas_') & !str_detect(extraction_id, 'Ex*$') ~ str_c(extraction_id, '-Ex1'),
                                     str_detect(extraction_id, 'Sgr-(AJol|AMvi)') ~ str_remove(extraction_id, "(?<=Ex1).*"),
                                     TRUE ~ extraction_id)) %>%
        distinct() %>%
        
        left_join(correction_data,
                  by = c('renamed_sequence_id',
                         'extraction_id')) %>% #filter(!is.na(fixed_extraction_id)) %>%
        mutate(extraction_id = coalesce(fixed_extraction_id, extraction_id),
               .keep = 'unused')
}

#### Find all Species Decodes ####
blat <- get_decodes()

blat2 <- blat %>%
    find_extraction_ids()


filter(blat2,
       str_detect(extraction_id, 'Pba-AGal'))


pire_database() %>%
    dm_filter(dna_extractions_sheets = (str_detect(extraction_id, "Adu-CMat_001"))) %>%
    pull_tbl('dna_extractions_sheets') %>%
    select(extraction_id)

blamo <- pull_tbl(pire_database(),
         'dna_extractions_sheets') %>%
    select(individual_id, extraction_id)

problem_ids <- tibble(extraction_id = c("Adu-AMat_001-Ex1",
                                        'Adu-AMat_003-Ex1',
                                        "Adu-AMat_089-Ex1",
                                        "Adu-CMat_097-Ex1",
                                        "Adu-CMat_099-Ex1",
                                        "Sde-C01_061-Ex1"))
anti_join(blat, 
          problem_ids,
          by = join_by(extraction_id)) 

blat2 %>%
    left_join(blamo,
          by = join_by(extraction_id)) %>%
    filter(is.na(individual_id))

filter(blamo, str_detect(extraction_id, "Pba-AGal")) 


write_csv(blat, '')
#### associate with database extractions ####

#### Get all PIRE fq files ####
tst <- get_tamucc_hpc_data()

tst %>%
  mutate(sample_id = str_extract(file, '^.*(?=_[IR][12])'),
         read_class = str_extract(file, "(?<=_)[RI][12](?=_)"),
         file_extension = str_extract(file, "f(ast)?q\\.gz$"))

count(tst, directory) %>% View
filter(tst, is.na(file))
filter(tst, directory == '/work/birdlab/GCL/20230123_PIRE-Sor-lcwgs-testlane')


