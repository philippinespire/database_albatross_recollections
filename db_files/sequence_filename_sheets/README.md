# Readme for sequence_filename_sheet_*.tsv


## Species Sheet Column Descriptions
| Column Name                                               | Description                                                                      |
| --------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **gcl\_sequence\_id**                                                | Sequence ID assigned by sequencing facility                                                      |
| **pire\_sequence\_id**                                       | Sequence ID following PIRE naming convention (**Primary Key**)     |
| **extraction\_id**                                  | Extraction ID to link with extractions (**Foreign Key**)                                 |

## Initial Sheet Creation 
Sheet was initially compiled from TAMUCC-GCL sequencing records on XX-XX-XXXX. Using [`scripts/database_transfer_from_onedrive/decode_to_extraction_id.R`](scripts/database_transfer_from_onedrive/decode_to_extraction_id.R). 