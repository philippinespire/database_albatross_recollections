# Readme for sequence_info_sheets

Each line a DNA sequencing run.

* sequencing_batch_id: primary key for this table
* Species_Code: three letter code for this species (or group of species)
* Era: Albatross or Contemporary time period
* Site_ID: three letter code for the site
* Match_ID: four letter code to match Albatross and Contemporary sites through time
* collection_year_start: year that these individuals were collected from the field (only the start if it crossed multiple years)
* Sequencing_Type: type of sequencing, either SSL (shotgun sequencing library, often one individual for genome assembly), CSSL (capture ssl, targeting a portion of the genome), or LCWGS (low coverage whole genome sequencing)
* #_of_individuals: number of individuals included in the sequencing run
* Seq_run_number: number to differentiatie multiple sequencing runs from the same set of individuals
* Seq_Complete?: Yes/No if the sequencing is finished
* HPC_name: name of the high performance computer where the data are stored
* HPC_path: location in the directory structure of the HPC
* Read_Length: length of the sequencing reads, in basepairs
* Project_Owner: name of the person working with these data
* Data_Uploaded_By: who uploaded the data to NCBI and GEOME
* GEOME_Expedition_Name: name of the collecting trip for the metadata on GEOME
* GEOME_Expedition_GUID: accession number for the metadata on GEOME
* NCBI_Bioproject_Accession_Number: NCBI accession number for the BioProject (where the data can be found online)
* NCBI_BioSample_Accession_Number: not used unless the sequencing run was only for a single individual
* NCBI_Project_Title
* NCBI_Data_Public?: Yes/No is the NCBI data public
* Sequencing_Notes: notes on how the sequencing went
* Bioinformatics_Notes: notes on bioinformatic challenges and discoveries. See the species-specific git repo for more details.
