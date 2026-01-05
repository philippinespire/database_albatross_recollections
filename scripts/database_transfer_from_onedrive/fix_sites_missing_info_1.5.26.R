library(tidyverse)
library(readxl)

missing_site_info <- read_csv('../../problem_notes/sites_missing_info_with_extractions.csv')
odu_lot_sheet <- read_excel("C:/Users/jdsel/Old Dominion University/Carpenter Molecular Lab - Philippines_PIRE_project/Database/Lot_sheet.xlsx") %>%
  janitor::clean_names() %>% 
  select(any_of(colnames(missing_site_info)))



fixes <- select(missing_site_info,
       lot_id) %>%
  left_join(odu_lot_sheet,
            by = 'lot_id') %>%
  left_join(select(missing_site_info, any_of(colnames(odu_lot_sheet))),
            by = 'lot_id') %>% 
  pivot_longer(cols = -lot_id,
               names_pattern = '(.*).([xy])',
               names_to = c('name', '.value'),
               values_transform = ~as.character(.)) %>%
  mutate(value = coalesce(x, y) %>% str_replace('\xa0', ' '),
         .keep = 'unused') %>%
  pivot_wider() %>%
  mutate(across(c(latitude, longitude), as.numeric)) 

write_csv(fixes, '../../problem_notes/fix_site_info.csv')
