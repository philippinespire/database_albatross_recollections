# Readme for sequence_info_sheets_*.tsv

Each line a DNA sequencing run.

## Sequencing Info Sheet Column Descriptions
| Column Name                             | Description                                                                                              |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **sequencing\_batch\_id**               | Unique identifier for the sequencing batch (species, site, year, sequencing type, replicate) (**Primary Key**)             |
| **Species\_Code**                       | Three letter code for this species (or group of species)                                                                                 |
| **Era**                                 | Collection era (e.g., A = Albatross/historic, C = Contemporary)                                          |
| **Site\_ID**                            | Identifier for the collection site                                                                       |
| **Match\_ID**                           | Cross-reference matching site ID                                                                         |
| **collection\_year\_start**             | Year when specimens were collected                                                                       |
| **Sequencing\_Type**                    | Sequencing method used. Either SSL (shotgun sequencing library, often one individual for genome assembly), CSSL (capture ssl, targeting a portion of the genome), or LCWGS (low coverage whole genome sequencing) |
| **#\_of\_individuals**                  | Number of individuals included in the sequencing batch                                                   |
| **Seq\_run\_number**                    | Number to differentiatie multiple sequencing runs from the same set of individuals                                                                                    |
| **Seq\_Complete?**                      | Indicates whether sequencing is complete (Yes/No)                                                        |
| **HPC\_name**                           | High-performance computing system used for storage/analysis                                              |
| **HPC\_path**                           | File path to sequencing data on HPC                                                                      |
| **Read\_Length**                        | Sequencing read length (bp)                                                                              |
| **Project\_Owner**                      | Principal investigator or project lead                                                                   |
| **Data\_Uploaded\_By**                  | Person responsible for uploading data                                                                    |
| **GEOME\_Expedition\_Name**             | GEOME project expedition name                                                                            |
| **GEOME\_Expedition\_GUID**             | GEOME globally unique expedition identifier                                                              |
| **NCBI\_Bioproject\_Accession\_Number** | NCBI BioProject accession number                                                                         |
| **NCBI\_BioSample\_Accession\_Number**  | NCBI BioSample accession number (not used unless the sequencing run was only for a single individual)                                                                         |
| **NCBI\_Project\_Title**                | Title of the project in NCBI records                                                                     |
| **NCBI\_Data\_Public?**                 | Indicates if sequencing data is publicly available in NCBI (Yes/No)                                      |
| **Sequencing\_Notes**                   | Notes specific to sequencing runs                                                                        |
| **Bioinformatics\_Notes**               | Notes on bioinformatic challenges and discoveries. See the species-specific git repo for more details.                                                           |

## Initial Sheet Conversion 
Conversion from onedrive excel file database to github based database on XX-XX-XXXX. Using [`scripts/database_transfer_from_onedrive/transfer_sheets_to_repo.R`](scripts/database_transfer_from_onedrive/transfer_sheets_to_repo.R). OneDrive database no longer maintained or added to after this date.