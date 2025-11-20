# Readme for tissue_sheet_*.tsv

These files are compiled into the individuals sheet of the database. All .tsv files in this directory need to have exactly the same headers and cell formats.

## Individual Sheet Column Description
| Column Name                              | Description                                                                  |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| **Individual\_ID**                       | Unique identifier for the biological individual sampled. Links to [Individual Sheet](../individuals_sheets/README.md)                               |
| **Tissue\_ID**                       | Unique identifier for the biological individual and tissue type sampled. Links to (**Primary Key**)                               |
| **Tissue\_type**                       | Type of tissue                               |
| **Notes**                                | General free-text notes                                                      |

## Initial Sheet Create 
Copied already existing `individuals_sheets/*` to folder. Created tissue_id from individual ID (adding '-mus'). Created on 20 November 2025
