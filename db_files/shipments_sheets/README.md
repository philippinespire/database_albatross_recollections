# Readme for shipment_sheet_*.tsv

Each line a shipment.

## Shipment Sheet Column Descriptions
| Column Name                                          | Description                                                                                   |
| ---------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **unique\_shipment\_id**                             | Unique identifier for each shipment record (includes date, item, and extraction/tissue info) (**Primary Key**)  |
| **Date\_Shipped\_by\_ODU**                           | Date the shipment was sent from Old Dominion University (ODU)                                 |
| **Shipment\_ID**                                     | Identifier for the shipment batch                                                             |
| **Species\_EraSite\_Individuals\_Extraction/tissue** | Encoded ID representing species, collection era/site, individuals, and extraction/tissue type |
| **Carrier**                                          | Shipping carrier used (e.g., FedEx)                                                           |
| **Tracking\_number**                                 | Tracking number provided by the carrier                                                       |
| **Date\_Received\_TAMUCC**                           | Date the shipment was received at Texas A\&M University–Corpus Christi (TAMUCC)               |
| **Item\_Type**                                       | Type of item shipped (e.g., elution, tissue)                                                  |
| **Plate\_Box\_ID**                                   | Identifier for the storage plate or box containing the shipped samples                        |
| **Plate\_ID\_1**                                     | Identifier for plate 1 in the shipment                                                        |
| **Plate\_ID\_2**                                     | Identifier for plate 2 in the shipment                                                        |
| **Plate\_ID\_3**                                     | Identifier for plate 3 in the shipment (if applicable)                                        |
| **Plate\_ID\_4**                                     | Identifier for plate 4 in the shipment (if applicable)                                        |
| **shipment\_num**                                    | Shipment sequence number within a batch (if tracked separately)                               |
| **filter\_out\_this\_row**                           | Flag indicating whether to exclude this row from analysis/processing                          |
| **Notes**                                            | Free-text notes about the shipment                                                            |

## Initial Sheet Creation 
Conversion from onedrive excel file database to github based database on XX-XX-XXXX. Using [`scripts/database_transfer_from_onedrive/transfer_sheets_to_repo.R`](scripts/database_transfer_from_onedrive/transfer_sheets_to_repo.R). OneDrive database no longer maintained or added to after this date.