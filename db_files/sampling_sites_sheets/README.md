# Readme for site_sheet_*.tsv

Each line is a samping site. 

## Sampling Sites Column Descriptions

| Column Name                  | Description                                                         |
| ---------------------------- | ------------------------------------------------------------------- |
| **lot\_id**                  | Identifier for the specimen lot collected at this site (**Primary Key**)             |
| **site\_id**                 | Abbreviated site identifier                                         |
| **match\_id**                | a four letter match between Albatross and Contemporary sites that can be compared to each other (generally within 80 km of each other)           |
| **collection\_site**         | Full name of the collection site                                    |
| **latitude**                 | Latitude (decimal degrees east) of the collection site                                     |
| **longitude**                | Longitude (decimal degrees north) of the collection site                                    |
| **barangay**                 | Barangay (village-level administrative unit) of the collection site |
| **local\_government\_unit**  | Municipality or city of the collection site                         |
| **province**                 | Province of the collection site                                     |
| **region**                   | Administrative region of the collection site (there are 13 options)                       |
| **island\_group**            | Major island group (e.g., Luzon, Visayas, Mindanao)                 |
| **notes**                    | Free-text notes                                                     |



## Initial Sheet Creation 
Intial Sheet was created on XX-XX-XXXX. Using [`db_files/sampling_sites_sheets/initialize_sampling_sites_sheets.R`](db_files/sampling_sites_sheets/initialize_sampling_sites_sheets.R). Extra information added by manually looking up sites with coordinates using https://wikimapia.org/#lang=en and https://www.philatlas.com/search.html
