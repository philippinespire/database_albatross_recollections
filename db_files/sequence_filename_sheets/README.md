# Readme for sequence_filename_sheet_*.tsv


## Species Sheet Column Descriptions
| Column Name                                               | Description                                                                      |
| --------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **extraction\_id**                                  | Extraction ID to link with extractions (**Foreign Key** & **Primary Key**) - used as both foreign and primary key to handle files containing multiple extractions                                |
| **file\_prefix**                                                | Prefix for file (**Primary Key**)                                                     |
| **hpc\_path**                                       | path to file on HPC (**Primary Key**)     |
| **hpc\_name**                                       | HPC file stored on (**Primary Key**)     |
| **sequencing\_batch\_id**                                       | **Foreign Key** to link with sequence_info_sheets **TO MAKE**     |
| **sequencing\_type**                                       | What sequencing/library preperation was used (SSL/CSSL/LCWGS/HIFI/HIC     |
| **duplicated\_sequence\_pair**                                       | File pairs which share this value have identical contents (NA if file is unique)     |
| **file\_forward**                                       | Forward file (for single end reads eg. HiFi the only file)     |
| **file\_reverse**                                       | Reverse file (for single end reads eg. HiFi this is NA)     |


## Initial Sheet Creation 
Sheet was initially compiled from files found on WAHAB 5.14.2026 Using `scripts/database_transfer_from_onedrive/find_sequence_files.R` which will no longer function due to the deprecation of the original sheet format

##todo - remake sequencing bactch ID as foreign key to sequence_info_sheet