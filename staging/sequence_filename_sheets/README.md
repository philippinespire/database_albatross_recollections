# Readme for sequence_filename_sheet_*.tsv


## Species Sheet Column Descriptions
| Column Name                                               | Description                                                                      |
| --------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **gcl\_sequence\_id**                                                | Sequence ID assigned by sequencing facility                                                      |
| **pire\_sequence\_id**                                       | Sequence ID following PIRE naming convention (**Primary Key**)     |
| **extraction\_id**                                  | Extraction ID to link with extractions (**Foreign Key**)                                 |

## Example Files
There are two example files either can be used for uploading sequencing file sheets. The [decode file](EXAMPLE_decode_file.tsv) represents the file created by the TAMUCC GCL to relate sequencing facility IDs to PIRE formatted IDs. If new data is added in this form it is internally converted to the [sequence filename format](EXAMPLE_sequence_filename_sheet.tsv) prior to inclusion into the database. Data may be uploaded in either format.