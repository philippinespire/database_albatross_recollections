# Sampling site sheets

Has data on the sites from which fish samples were taken.

* site_sp_primary_key	site_id: a primary key to join to other tables. consists of site_ID-species_ID (see columns below)
* site_id: a three letter site ID
* species_id: a three letter species ID
* site_name: long species name
* barangay: name of the barangay (if available)
* local_government_unit: name of the Local Government Unit
* province: name of the province
* region: there are 13 options
* island_group: Luzon, Visayas, or Mindanao
* lat: latitude, in decimal degrees north
* lon: longitude, in decimal degrees east
* match_id: a four letter match between Albatross and Contemporary sites that can be compared to each other (generally within 80 km of each other)
* notes: any notes that don't fit in the columns

Site sheet was generated as follows:

```r
#Select and flatten relevant sheets and columns, generate key
site_sheet_prep <- pire_db %>% dm_flatten_to_tbl(individuals_sheets,species_sheets,lots_sheets) %>%
    select(site_id,species_code,match_id,collection_site.individuals_sheets,latitude,longitude, species_albatross_name, lot_id,species_valid_name.individuals_sheets) %>%
    distinct() %>%
    mutate(site_species = paste(site_id, species_code, sep = "-")) %>%
    relocate(site_species, .before = site_id) %>%
    collect()
    
#Write to tsv
write_tsv(site_sheet_prep, "/Users/marianne/PIRES/local/site_sheet_prep.tsv")
```

Manually look up sites with coordinates using https://wikimapia.org/#lang=en and https://www.philatlas.com/search.html