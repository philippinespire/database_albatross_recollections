# DNA Extraction Logs

Details of the DNA extraction lab work

---

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
	