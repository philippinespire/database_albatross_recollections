# Readme for site_sheet_*.tsv

Each line is a samping site. 

## Sampling Sites Column Descriptions

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

| Column Name                  | Description                                              |
| ---------------------------- | -------------------------------------------------------- |
| **lot\_id**                  | Identifier for the specimen lot collected at this site (**Primary Key**)  |
| **site\_id**                 | Abbreviated site identifier                              |
| **species\_code**            | Abbreviated species code                                 |
| **match\_id**                | Matching identifier linking site records across datasets |
| **collection\_site**         | Full name of the collection site                         |
| **latitude**                 | Latitude of the collection site                          |
| **longitude**                | Longitude of the collection site                         |
| **species\_albatross\_name** | Species name as recorded in Albatross expedition records |


## Initial Sheet Creation 
Intial Sheet was created on XX-XX-XXXX. Using [`db_files/sampling_sites_sheets/initialize_sampling_sites_sheets.R`](db_files/sampling_sites_sheets/initialize_sampling_sites_sheets.R). Extra information added by manually looking up sites with coordinates using https://wikimapia.org/#lang=en and https://www.philatlas.com/search.html
