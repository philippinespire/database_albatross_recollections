# DNA Extraction Logs

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

## Issues

* ODU/TAMUCC names in columns
	* originally, ODU was doing all subsampling and extractions, then that got sent to TAMUCC
	* but now TAMUCC is doing the subsampling and extractions
	* I propose we add a column, `extraction_lab` and attempt to remove lab names from column names
		* elution1_vol_for_odu and _tamucc is from splitting extracts across 2 labs, keeping half at odu and sending half to tamucc
			* it's my (cEB) understanding that all extracts were sent to TAMUCC at this point 
			* we should have one or more columns to document the location of the extracts:  instituion, building, room, freezer_id
		* date_gelled_odu would be best handled in a gel log

* Gel information
	* I (CEB) propose that gel information should be stored in a separate gel log and images can be stored in db2.0, see `dna_extraction_gels`
		* The primary key of gel log is `gel_id`
		* A foreign key would need to be added to the extractions sheet: elution1_gel_id, elution2_gel_id, ..., elution4_gel_id
	* The last 11 columns of the `extractions_sheet` has columns related to gels
		* none of the ODU gel score columns have info, so I (CEB) propose they be deleted
		* some ofthe TAMUCC gel score columns do have info, so keep them
		* the `Date_Gelled_ODU` column doesn't allow for different dates for different elutions
			* there should be a date gelled column for each elution if we keep this column in extractions, but gel date would be best stored in a separate gel log as a single column
			* there could then be elution1_gel_id, elution2_gel_id, ..., elution4_gel_id  added to the extractions sheet, as mentioned above
			
* Extraction Protocol info
	* Need to record the extraction kit used, propose to add extraction kit brand, extraction kit type/model, ...
		* Everything before 2024 was Qiagen DNEasy Blood & Tissue Spin columns, but the 2024-2025 collections are being processed with either Omega Biotek MagBind, a tba HMW kit, or a Hi-C protocol
	* `Elution_Buffer` currently does not indicate which kit was used
	
* Data consistency
	* `Elution_Buffer` sometimes contains extraction_id and other issues
	
* Column renaming
	* `Elutions` should be `num_elutions`
	
	