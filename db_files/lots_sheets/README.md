# Readme for lot_sheet_*.tsv

This table has a row for each lot. A "lot" is a jar of fish all taken from the same location and thought to be the same species. These either came from the Smithsonian museum collection from the USS Albatross expedition, or from our own collections in the Philippines.

---
## Lot Sheet Column Descriptions

| Column Name                          | Description                                                                       |
| ------------------------------------ | --------------------------------------------------------------------------------- |
| **Lot\_ID**                          | A number (for Albatross lots) or SITE-YEAR-COLLECTIONSITENUMBER_SPECIESNUMBER (contemporary lots) to identify the lot. COLLECTIONSITENUMBER differentiates multiple specific locations visited within the SITE. This records which location within a site as a two-digit number (01, 02, 03, etc.). SPECIESNUMBER differentiates multiple species collected from the site and is a two- or three-digit number (e.g., 01, 02, 03, or 001, 002, 003) (**Primary Key**)                                |
| **collection\_year\_start**          | Four Digit year when collection started                                                      |
| **collection\_month\_start**         | Month when collection started                                                     |
| **collection\_day\_start**           | Day when collection started                                                       |
| **collection\_year\_end**            | Four Digit year when collection ended                                                        |
| **collection\_month\_end**           | Month when collection ended                                                       |
| **collection\_day\_end**             | Day when collection ended                                                         |
| **Date\_Collected**                  | Encoded or raw date field for collection event                                    |
| **Collection\_era**                  | General period of collection (e.g., Albatross, Contemporary)                      |
| **Collector**                        | Name of the collector or collecting team                                          |
| **Species\_verified**                | Indicator whether species ID has been verified                                    |
| **Physical\_location\_of\_lot**      | Storage location of the lot (e.g., museum, lab, freezer)                          |
| **check\_location?**                 | Flag to check or confirm storage location                                         |
| **Freezer\_Location**                | Specific freezer location for the lot                                             |
| **Box\_ID**                          | Identifier for the storage box                                                    |
| **Bottles**                          | Number of bottles in which specimens are stored                                   |
| **Storage\_solution**                | Solution used for preserving specimens (e.g., EtOH, RNAlater)                     |
| **Type\_of\_Study**                  | Intended use of specimens (e.g., genetics, morphology)                            |
| **ODU\_collection\_catalog\_number** | Old Dominion University catalog number for the lot                                |
| **Individuals**                      | Number of individuals in the lot                                                  |
| **Size-USNM\_(mm)**                  | Size of specimens in millimeters (from USNM records)                              |
| **size\_direct\_observation\_(mm)**  | Size of specimens in millimeters (measured directly)                              |
| **Species\_valid\_name\_majority**   | Notes on the species name of the majority of individuals in the lot. This isn't definitive and is sometimes a note. Not useful as a database key. Use Individuals sheet instead.                           |
| **Collection\_site**                 | Name of the collection site. This field is not standardized. See Site_ID.                                |
| **Site\_ID**                         | A three letter site abbreviation. This same abbreviation may have been used for different locations in a different species, and it is applied to multiple nearby locations in the same species (<80 km apart or so)                                                |
| **Match\_ID**                        | A four letter code to link Albatross sites to Contemporary sites across time.                                        |
| **latitude**                         | Latitude of collection site                                                       |
| **longitude**                        | Longitude of collection site                                                      |
| **Lot\_status**                      | Current status of the lot (e.g., collected, pending, to\_collect)                 |
| **Priority**                         | Priority level for processing or study                                            |
| **project\_owner**                   | Name of the project owner or PI                                                   |
| **Notes**                            | Free-text notes about the lot                                                     |
| **Collection\_status**               | Status of the collection effort (e.g., collected\_full, duplicate, collect\_more) |
| **Duplicate\_count**                 | Number of duplicate individuals/specimens recorded                                |

## Initial Sheet Conversion 
Conversion from onedrive excel file database to github based database on XX-XX-XXXX. Using [`scripts/database_transfer_from_onedrive/transfer_sheets_to_repo.R`](scripts/database_transfer_from_onedrive/transfer_sheets_to_repo.R). OneDrive database no longer maintained or added to after this date.