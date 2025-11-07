# Readme for extractions_sheet_*.tsv

Details of the DNA extraction lab work

---

## Extraction Sheet Column Description
| Column Name                      | Description                                                                     |
| -------------------------------- | ------------------------------------------------------------------------------- |
| **Individual\_ID**               | Unique identifier for the biological individual sampled. Links to [Individual Sheet](../individuals_sheets/README.md)                         |
| **Extraction\_ID**               | Unique identifier for the extraction event (**Primary Key**)           |
| **Storage\_solution**            | Solution used to preserve the sample prior to extraction (e.g., EtOH, RNAlater) |
| **Date\_Subsampling**            | Date when a subsample was taken for extraction                                  |
| **Subsampler**                   | Person who subsampled the tissue                                                |
| **Date\_Extracting**             | Date when extraction occurred                                                   |
| **Tube\_Stuffer**                | Person who transferred tissue into extraction tubes                             |
| **mg\_Tissue\_Extracted**        | Mass (mg) of tissue used in the extraction                                      |
| **Digestion\_min**               | Time (minutes) for tissue digestion                                             |
| **Extractor**                    | Person who performed the extraction                                             |
| **Extraction\_TubeID**           | Identifier of the extraction tube                                               |
| **PlateID**                      | Identifier of the extraction plate (if used)                                    |
| **Elution\_Buffer**              | Type of buffer used for DNA elution                                             |
| **num\_elutions**                | Number of elutions performed on the extraction                                  |
| **ElutionX\_PlateID**            | Plate ID for elution X (1–4)                                                    |
| **ElutionX\_Plate\_Column**      | Plate column position for elution X                                             |
| **ElutionX\_Plate\_Row**         | Plate row position for elution X                                                |
| **ElutionX\_Total\_volume\_ul**  | Total elution volume (µl)                                                       |
| **ElutionX\_Vol\_for\_TAMUCC**   | Volume (µl) allocated to TAMU–Corpus Christi                                    |
| **ElutionX\_Vol\_for\_ODU**      | Volume (µl) allocated to Old Dominion University                                |
| **ElutionX\_nanodrop\_ng\_ul**   | DNA concentration (ng/µl) measured by Nanodrop                                  |
| **Date\_Gelled\_ODU**            | Date of gel check at ODU                                                        |
| **ODU\_Volume\_Gelled\_ul**      | Volume (µl) used for gel electrophoresis                                        |
| **ODU\_Gel\_Jockey**             | Person who performed the gel electrophoresis                                    |
| **ElutionX\_Gel\_Score\_TAMUCC** | Gel electrophoresis quality score for elution X at TAMU–CC                      |
| **Elution\_Used**                | Indicates which elution was ultimately used                                     |
| **Notes**                        | Free-text field for additional comments                                         |

