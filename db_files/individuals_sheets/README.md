# Readme for individual_sheet_*.tsv

These files are compiled into the individuals sheet of the database. All .tsv files in this directory need to have exactly the same headers and cell formats.

## Individual Sheet Column Description
| Column Name                              | Description                                                                  |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| **Species\_valid\_name**                 | Our best attempt at identifying this individual taxonomically. This may or may not be a Latin binomial. It may be a genus or a couple species. This field links to the [species sheet](../species_sheets/README.md).                    |
| **Lot\_ID**                              | Identifier for the lot (group of collected individuals). Links to the [Lot sheet](../lots_sheets/README.md).                      |
| **Collection\_site**                     | Geographic site where the specimen was collected                             |
| **Equivalent\_Albatross\_Site**          | Equivalent site name based on Albatross records                   |
| **Collection\_Period**                   | Collection campaign or period (e.g., Albatross or Contemporary)                   |
| **Individual\_ID**                       | Unique identifier for the individual specimen (**Primary Key**)                               |
| **New\_USNM**                            | New U.S. National Museum (Smithsonian) catalog number                        |
| **USNM\_Biorepository**                  | Biorepository code or accession at USNM                                      |
| **Species\_ID\_method**                  | Method used to determine species identification (e.g., morphology, genetics) |
| **Species\_ID\_person**                  | Person who determined the species identification                             |
| **Species\_ID\_notes**                   | Notes related to species identification                                      |
| **Notes**                                | General free-text notes                                                      |
| **Species\_ID\_year**                    | Year when the species identification was made                                |
| **Species\_ID\_month**                   | Month when the species identification was made                               |
| **Species\_ID\_day**                     | Day when the species identification was made                                 |
| **Species\_ID\_date\_originallyEntered** | Original date entry for species identification (raw format). This is not in a consistent date format (Malin's note 08/2025).                 |
