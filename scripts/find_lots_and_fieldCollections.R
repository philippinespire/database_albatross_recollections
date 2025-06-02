## Code to identify samples that are found in the "Field Collection" data but is missing in the Lot sheet
## Set the working directory to be inside the main "Philippines_PIRE_project" folder

library(tidyverse)
library(readxl)

check_correct_file <- function(filepath){
  exists <- read_excel(filepath) %>%
    colnames() %>%
    str_detect('Lot_ID|lot_id|LOT_ID') %>%
    any()
  
  if_else(exists,
          filepath,
          NA_character_)
}

all_files <- list.files('Field Collections/', 
           recursive = TRUE,
           pattern = 'xlsx$',
           full.names = TRUE) %>%
  str_subset('20[0-9]{2}')

correct_files <- all_files %>%
  map_chr(check_correct_file) %>%
  na.omit() %>%
  as.character()

all_files[!all_files %in% correct_files]

lot_data <- read_excel('Database/Lot_sheet.xlsx') %>%
  janitor::clean_names()
sum(is.na(lot_data$lot_id))

field_data <- correct_files %>%
  map_dfr(~read_excel(.x) %>%
            janitor::clean_names() %>%
            select(-any_of(c('individuals',
                           'size_direct_observation_mm'))), 
          .id = 'file') %>%
  mutate(file = correct_files[as.integer(file)])

summarise(field_data,
          n_missing = sum(is.na(lot_id)),
          .by = file)


inner_join(distinct(lot_data, lot_id),
           distinct(field_data, file, lot_id) %>%
             filter(!is.na(lot_id)),
          by = 'lot_id') %>% filter(n() > 1, .by = lot_id) %>% count(file)

anti_join(distinct(lot_data, lot_id),
          distinct(field_data, file, lot_id) %>%
            filter(!is.na(lot_id)),
          by = 'lot_id') %>%
  filter(!str_detect(lot_id, '^[0-9]+$')) 

anti_join(distinct(field_data, file, lot_id) %>%
            filter(!is.na(lot_id)),
          distinct(lot_data, lot_id),
          by = 'lot_id') %>%
  filter(!str_detect(file, 'preliminary')) %>%
  left_join(field_data,
            by = c('file', 'lot_id')) 


inner_join(distinct(lot_data, lot_id),
           distinct(field_data, file, lot_id) %>%
             filter(!is.na(lot_id)),
           by = 'lot_id') %>%
  distinct(lot_id)

# 49 samples with no lot ID in the "Field Collections/Palawan-Mainland 2022/Palawan Collections preliminary.xlsx"
# 16 lot_id duplicated between "Field Collections/Palawan-Mainland 2022/Palawan 2022 Collections - Mainland.xlsx" and "Field Collections/Palawan-Mainland 2022/Palawan Collections preliminary.xlsx" and "Field Collections/Palawan-Mainland 2022/Palawan Collections preliminary.xlsx"

#323 lot_id's in "Database/Lot_sheet.xlsx" which don't exist in any of "Field Collections/Bolinao 2022/2022_Collections_Bolinao_2022_07.xlsx; Field Collections/Dapitan 2022/Dapitan_collections.xlsx; Field Collections/Masbate-Port Busin_2022/Apr 2022 KEC AB Port BusinCollections.xlsx; Field Collections/Palawan-Mainland 2022/Palawan 2022 Collections - Mainland.xlsx; Field Collections/Palawan-Mainland 2022/Palawan Collections preliminary.xlsx; Field Collections/Samar North - Luzon south 2022/Samar_Albay_October_2022_Collections.xlsx; Field Collections/Verde Island 2022/Ver-2022_VerdeIslandCollection.xlsx"

#27 lot_ids in one of the Field collection data files which do not exist in 'Database/Lot_sheet.xlsx'

#84 lot_id's which are in at least one of the Field collection data files (see above for duplcates) and the 'Database/Lot_sheet.xlsx'
