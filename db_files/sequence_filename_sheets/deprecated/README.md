# Readme for sequence_filename_sheet_*.tsv


## Species Sheet Column Descriptions
| Column Name                                               | Description                                                                      |
| --------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **gcl\_sequence\_id**                                                | Sequence ID assigned by sequencing facility                                                      |
| **pire\_sequence\_id**                                       | Sequence ID following PIRE naming convention (**Primary Key**)     |
| **extraction\_id**                                  | Extraction ID to link with extractions (**Foreign Key**)                                 |

## Initial Sheet Creation 
- Sheet was initially compiled from TAMUCC-GCL sequencing records on 7 November 2025. Using [`scripts/database_transfer_from_onedrive/decode_to_extraction_id.R`](scripts/database_transfer_from_onedrive/decode_to_extraction_id.R). 
- This style of the sheet was used to build the current complete version and was deprecated 5.14.26 when it was complete. These inputs feed into `scripts/database_transfer_from_onedrive/find_sequence_files.R`. The change also breaks that script

##todo - remake sequencing bactch ID as foreign key to sequence_info_sheet