# Readme for extractions_mislabelling_sheet.xlsx

Details of the Mislabelled data sheet. This sheet is used to correct complex systemic errors made in the database which require corrections across multiple sheets. Columns marked "Original" give enough details to identify the specific row which needs to be corrected with the columns marked "Corrected". Values which are used for identification of the row and are originally correct should be the same in the equivilant corrected column with only the error being altered.

---

## Mislabelling Sheet Column Description

| Column Name                                     | Description                                                           |
| ----------------------------------------------- | --------------------------------------------------------------------- |
| **Misidentification\_ID**                       | Unique identifier for the misidentification/mislabelling record       |
| **Mislabelling\_Category**                      | Category of mislabelling (e.g., mislabelled extraction, duplicate ID) |
| **Original\_Lot\_ID**                           | Lot ID as originally recorded                                         |
| **Original\_Individual\_ID**                    | Individual ID as originally recorded                                  |
| **Original\_Extraction\_ID**                    | Extraction ID as originally recorded                                  |
| **Original\_Extraction\_Plate\_ID**             | Plate ID where the original extraction was recorded                   |
| **Original\_Extraction\_Plate\_Well\_Address**  | Well address of the original extraction plate                         |
| **Original\_Sequence\_ID**                      | Sequence ID linked to the original extraction                         |
| **Corrected\_Lot\_ID**                          | Corrected lot ID after resolving mislabelling                         |
| **Corrected\_Individual\_ID**                   | Corrected individual ID after resolving mislabelling                  |
| **Corrected\_Extraction\_ID**                   | Corrected extraction ID after resolving mislabelling                  |
| **Corrected\_Extraction\_Plate\_ID**            | Plate ID where corrected extraction is located                        |
| **Corrected\_Extraction\_Plate\_Well\_Address** | Well address of the corrected extraction plate                        |
| **Corrected\_Sequence\_ID**                     | Corrected sequence ID after resolving mislabelling                    |
| **Date\_Issue\_Identified**                     | Date when mislabelling/misidentification issue was identified         |
| **Issue\_Identifies**                           | Person(s) who identified the issue                                    |
| **Notes**                                       | Free-text notes describing the issue and resolution                   |
