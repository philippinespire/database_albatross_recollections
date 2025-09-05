#### Packages ####
source("assemble_db.R")

#### Identify Primary and Foreign Keys ####
dir.create('../troubleshooting_files')
# Samples with either duplicated of missing Extraction IDs
pire_db$dna_extractions_sheets %>%
    mutate(extraction_id2 = str_replace_all(extraction_id, '-', '_')) %>%
    filter(n() > 1,
           .by = extraction_id2) %>%
    filter(!is.na(extraction_id)) %>% View
    distinct(individual_id, extraction_id, extraction_id2) 
    
  write_csv('../troubleshooting_files/Extractions_sheet_xlsx_issues.csv')


initial_database$dna_extractions_gels %>%
  filter(n() > 1 | is.na(gel_id),
         .by = gel_id)


initial_database$species_sheets %>%
  filter(n() > 1 | is.na(species_code),
         .by = species_code)


initial_database$individuals_sheets %>%
  filter(is.na(individual_id))

initial_database$individuals_sheets %>%
  filter(n() > 1 | is.na(individual_id),
         .by = individual_id) %>%
  distinct(individual_id) %>%
  filter(!is.na(individual_id)) %>%
  write_csv('../troubleshooting_files/Individual_sheet_xlsx_issues.csv')
  
  
initial_database$lots_sheets %>%
  filter(n() > 1 | is.na(lot_id),
         .by = lot_id) %>%
  distinct(lot_id)

initial_database$shipments_sheets %>%
  filter(n() > 1 | is.na(shipment_id),
         .by = shipment_id) %>%
  distinct(shipment_id) %>%
  write_csv('../troubleshooting_files/Shipment_sheet_xlsx_issues.csv')



initial_database$shipments_sheets %>%
  filter(item_type == 'elution') %>%
  filter(n() > 1,
         .by = plate_box_id) %>%
  count(plate_box_id) %>%
  write_csv('../troubleshooting_files/duplicated_shipment_plateBoxID.csv')

initial_database$shipments_sheets %>%
  filter(plate_box_id == 'Adu-C_001') %>% View

