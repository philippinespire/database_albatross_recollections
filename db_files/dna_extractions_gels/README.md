# Readme for dna_extraction_gels_*.tsv

Each line is a species.

## DNA Extraction Gel Column Descriptions
| Column Name                                  | Description                                                                 |
| -------------------------------------------- | --------------------------------------------------------------------------- |
| **gel\_id**                                  | Unique identifier for the gel run (includes sample, elution, and date info) (**Primary Key**) |
| **gel\_file\_name**                          | File name of the gel image/PDF record (in [gel_images](~/gel_images))                                      |
| **gel\_laboratory**                          | Laboratory where the gel was run (e.g., TAMUCC)                             |
| **gel\_person**                              | Person who prepared and ran the gel                                         |
| **gel\_loading\_volume\_ul**                 | Volume of DNA loaded into each gel well (µl)                                |
| **gel\_date**                                | Date when the gel was run                                                   |
| **gel\_ladder\_brand**                       | Brand of DNA ladder used for size reference                                 |
| **gel\_ladder\_model**                       | Model of DNA ladder used (e.g., HyperLadder 1kb)                            |
| **gel\_agarose\_pct**                        | Agarose percentage used in the gel                                          |
| **gel\_buffer**                              | Type of buffer used for gel electrophoresis (e.g., TAE, TBE)                |
| **gel\_buffer\_concentration\_x**            | Concentration of the electrophoresis buffer (in X)                          |
| **gel\_nucleotide\_stain\_brand**            | Brand of nucleotide stain used (e.g., Lonza)                                |
| **gel\_nuceotide\_stain\_model**             | Model/type of nucleotide stain (e.g., GelStar)                              |
| **gel\_nucleotide\_stain\_concentration\_x** | Concentration of nucleotide stain (in X)                                    |
| **gel\_electrophoresis\_volts**              | Voltage applied during electrophoresis                                      |
| **gel\_electrophoresis\_duration\_minutes**  | Duration (minutes) of electrophoresis run                                   |

## Initial Sheet Conversion 
Conversion from onedrive excel file database to github based database on XX-XX-XXXX. Using [`scripts/database_transfer_from_onedrive/transfer_sheets_to_repo.R`](scripts/database_transfer_from_onedrive/transfer_sheets_to_repo.R). OneDrive database no longer maintained or added to after this date.