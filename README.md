# database2.0: Albatross Recollections

---

![](database_erd.png)

---

## Basic Structure
* every data file is [tidy](https://cran.r-project.org/web/packages/tidyr/vignettes/tidy-data.html)
* each entity (table) in the databased is represented by a directory
  * The directory should be populated by one or more tsv files (no excel)
  * These files should be concatenatable using `bind_rows()`, i.e. they should have the same columns
* each entity (table) should follow a relational database structure
  * entities (tables) should be assembled in R as tibbles (dataframes)
  * `dm` should be used to create the database object

## Database Contents Structure
- [Extraction Sheets](db_files/dna_extractions_sheets/README.md)
- [Individual Sheets](db_files/individuals_sheets/README.md)
- [Lot Sheets](db_files/lots_sheets/README.md)
- [Sampling Sites Sheets](db_files/sampling_sites_sheets/README.md)
- [Sequence Sheets](db_files/sequence_info_sheets/README.md) **Unlinked to main DB**
- [Shipment Sheets](db_files/shipments_sheets/README.md) **Unlinked to main DB**
- [Species Sheets](db_files/shipments_sheets/README.md)
- [DNA Extraction Gels](db_files/dna_extractions_gels/README.md)
- [Sequence Filenames Sheets](db_files/sequence_filename_sheets/README.md)

## Quick Start 
Double click on `database_albatross_recollections.Rproj`
Run `pire_database()` in R to access the database

## How to use this repo
This repository uses [renv](https://rstudio.github.io/renv/) to create a reproductible R environment. 


1. Clone this repository to your local machine by typing the following on the command line:
```bash
git clone git@github.com:philippinespire/database_albatross_recollections.git
```
2. Navigate to the database folder and open `database_albatross_recollections.Rproj` in `RStudio`. Something like the following should be shown in your console:
```r
============================================================
 PROJECT: database_albatross_recollections
============================================================

📁 Working directory confirmed
    C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections 

🪟 Windows system detected
   ✔ Rtools detected

📦 Checking R environment...
   ✔ renv active
   ✅ All 154 R packages installed

------------------------------------------------------------
 ✅ PROJECT READY
 ┌─────────────────────────────────────────────────────┐
 💡 QUICK START:
    • Using the database?       Run: pire_database()
    • Updating the database?    Run: update_database()
 └─────────────────────────────────────────────────────┘
```
If this message does not appear on your console, try sourcing the .Rprofile manually in the R console:
```r
# Ensure you are in the correct directory
>getwd()
# This should display the path to the albatross_recollections directory. If not, set the directory manually:
>setwd("/path/to/database_albatross_recollections")
# Source the .Rprofile
>source(".Rprofile")
```
Once the R profile is correctly running, you have access to new project specific R functions (see below) that can be used to locally build the database. Generally you should be able to follow the instructions in the terminal to set-up your computer if needed and use/update the database.

4. If this is the first time cloning the repo the R function `setup_project()` will be available. Use `setup_project()` in the R console to install needed packages and restart R (Session → Restart R or Ctrl+Shift+F10).
	- If you are using a Windows computer: If [RTools](https://cran.r-project.org/bin/windows/Rtools/) is not detected installed on your computer you will be prompted to use `install_windows_tools()` which will provide guidance on how to install Rtools prior to using `setup_project()`
	- If you are using a Linux computer: First use `setup_project()` to install packages. However if there are errors you can use `install_linux_dependencies()` to get a prompt for how to download linux system dependencies that may not come with your distro by default.
	- If you are using a Mac computer: 

5. To locally build the database, use the R function `pire_database()` to create the database as a `dm` object. 

## Using the database
**Example 1: Counting the number of samples from a collection site**
```r
#Obtain distinct collection sites
pire_db <- pire_database()
pull_tbl(pire_db, "individuals_sheets") %>%
  distinct(collection_site)
```
<details>
  <summary>Output</summary>

```r
# A tibble: 105 × 1
   collection_site   
   <chr>             
 1 Port_Dupon        
 2 Cebu_Market       
 3 Ragay_River       
 4 Pasacao           
 5 Pandanan_Id       
 6 Puerto_Galera     
 7 Port_Caltom       
 8 Guijulugan_Beach  
 9 Bais_Bay_Anchorage
10 Hamilo_Cove       
# ℹ 95 more rows
```
</details>
<br>

```r
#Find species collected at Hamilo Cove
pire_db <- pire_database()
pull_tbl(pire_db, "individuals_sheets") %>%
  filter(collection_site == "Hamilo_Cove") %>%
  distinct(species_valid_name)
```

<details>
  <summary>Output</summary>

```r
# A tibble: 7 × 1
  species_valid_name         
  <chr>                      
1 Atherinomorus_duodecimalis 
2 Atherinomorus_endrachtensis
3 Ambassis_urotaenia         
4 Gazza_minuta               
5 Hypoatherina_temminckii    
6 Equulites_leuciscus        
7 Spratelloides_delicatulus  
```
</details>

<br>

```r
#Count individuals by species at Hamilo Cove
pire_db <- pire_database()
pull_tbl(pire_db, "individuals_sheets") %>%
    filter(collection_site == "Hamilo_Cove") %>%
    count(species_valid_name, name = "n_individuals")
```
<details>
  <summary>Output</summary>

```r
# A tibble: 7 × 2
  species_valid_name          n_individuals
  <chr>                               <int>
1 Ambassis_urotaenia                     96
2 Atherinomorus_duodecimalis            192
3 Atherinomorus_endrachtensis            60
4 Equulites_leuciscus                    32
5 Gazza_minuta                           96
6 Hypoatherina_temminckii                96
7 Spratelloides_delicatulus              96
```
</details>
<br>

```r
#Count individuals by species and collection period at Hamilo Cove
pire_db <- pire_database()
pull_tbl(pire_db, "individuals_sheets") %>%
  filter(collection_site == "Hamilo_Cove") %>%
  count(species_valid_name, collection_period, name = "n_individuals")
```

<details>
  <summary>Output</summary>

```r
# A tibble: 8 × 3
  species_valid_name          collection_period n_individuals
  <chr>                       <chr>                     <int>
1 Ambassis_urotaenia          Contemporary                 96
2 Atherinomorus_duodecimalis  Albatross                    96
3 Atherinomorus_duodecimalis  Contemporary                 96
4 Atherinomorus_endrachtensis Albatross                    60
5 Equulites_leuciscus         Albatross                    32
6 Gazza_minuta                Albatross                    96
7 Hypoatherina_temminckii     Contemporary                 96
8 Spratelloides_delicatulus   Contemporary                 96
```
</details>

<br>

```r
#Filter the database to only include certain individuals and identify the lots associated with those samples:
pire_db <- pire_database()
dm_filter(pire_db,
          species_sheets = (species_code == 'Sgr'),
          individuals_sheets = (str_detect(individual_id, '[AC](Jol|Mvi)|(APal)|(CBir)'))) %>%
    pull_tbl('lots_sheets') %>%
	    select(lot_id, collection_year_start, collection_year_end, 
           collection_era, site_id)

#OR

dm_filter(pire_db,
          species_sheets = (species_code == 'Sgr'),
          lots_sheets = (site_id %in% c('Jol', 'Mvi', 'Pal', 'Bir'))) %>%
    pull_tbl('lots_sheets') %>%
    select(lot_id, collection_year_start, collection_year_end, 
           collection_era, site_id)
```

```r
#Get Site/Lot info for a set of extractions
extraction_ids <- c("Sgr-CBir_004-Ex1", "Sgr-AMvi_035-Ex1", "Sgr-AMvi_046-Ex1", "Sgr-CMvi_052-Ex1", "Sgr-AJol_091-Ex1")
pire_db <- pire_database()
pire_db %>%
    dm_filter(species_sheets = (species_code == 'Sgr'),
              dna_extractions_sheets = (extraction_id %in% extraction_ids)) %>%
    # optional: keep only the columns you care about from each table
    dm_select(lots_sheets, lot_id, 
              collection_year_start, collection_year_end,
              collection_era) %>%
    dm_select(sampling_sites_sheets, lot_id, 
              collection_site, local_government_unit:island_group) %>%
    dm_flatten_to_tbl(start = lots_sheets,
                      sampling_sites_sheets,
                      .join = dplyr::full_join)
```

<details>
  <summary>Output</summary>

```r
# A tibble: 6 × 9
  lot_id           collection_site            local_government_unit province       region          island_group collection_year_start collection_year_end collection_era
  <chr>            <chr>                      <chr>                 <chr>          <chr>           <chr>                        <dbl>               <dbl> <chr>         
1 120926           Port_Matalvi_reef_Masinloc Masinloc              Zambales       Central Luzon   Luzon                         1908                1908 Albatross     
2 138933           Tutu_Bay                   Hadji Panglima Tahil  Sulu           BARMM           Mindanao                      1909                1909 Albatross     
3 138936           Port_Palapag               Salvacion             Northern Samar Eastern Visayas Visayas                       1909                1909 Albatross     
4 Jol-2021-01_01   Panglima_Tahil,_Jolo       Hadji Panglima Tahil  Sulu           BARMM           Mindanao                      2021                2021 Contemporary  
5 SAM-2022_02_14   NA                         Biri                  Northern Samar Eastern Visayas Visayas                       2022                2022 Contemporary  
6 Zam-2019-004_012 Masinloc_Public_Market     Palaulg               Zambales       Central Luzon   Luzon                         2019                2019 Contemporary  
```
</details>

```r
#Get Sequence filenames for all Sgr species
pire_db <- pire_database()
pire_db %>%
	dm_filter(species_sheets = (species_code == 'Sgr')) %>%
    pull_tbl(sequence_filename_sheets)
```

<details>
  <summary>Output</summary>

```r
# A tibble: 799 × 8
   sequence_filename_sheetsfile_path                                                                      gcl_sequence_id pire_sequence_id extraction_id correction_applied correction_id correction_details correction_date
   <chr>                                                                                                  <chr>           <chr>            <chr>         <lgl>              <chr>         <chr>              <chr>          
 1 C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections/db_files/sequ… SgA0103511C     Sgr-AMvi_035_Ex… Sgr-AMvi_035… FALSE              NA            NA                 NA             
 2 C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections/db_files/sequ… SgA0104307D     Sgr-AMvi_043_Ex… Sgr-AMvi_043… FALSE              NA            NA                 NA             
 3 C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections/db_files/sequ… SgA0104610D     Sgr-AMvi_046_Ex… Sgr-AMvi_046… FALSE              NA            NA                 NA             
 4 C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections/db_files/sequ… SgA0105406E     Sgr-AMvi_054_Ex… Sgr-AMvi_054… FALSE              NA            NA                 NA             
 5 C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections/db_files/sequ… SgA0104711D     Sgr-AMvi_047_Ex… Sgr-AMvi_047… FALSE              NA            NA                 NA             
 6 C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections/db_files/sequ… SgA0104408D     Sgr-AMvi_044_Ex… Sgr-AMvi_044… FALSE              NA            NA                 NA             
 7 C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections/db_files/sequ… SgA0104812D     Sgr-AMvi_048_Ex… Sgr-AMvi_048… FALSE              NA            NA                 NA             
 8 C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections/db_files/sequ… SgA0104206D     Sgr-AMvi_042_Ex… Sgr-AMvi_042… FALSE              NA            NA                 NA             
 9 C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections/db_files/sequ… SgA0103903D     Sgr-AMvi_039_Ex… Sgr-AMvi_039… FALSE              NA            NA                 NA             
10 C:/Users/jdsel/Documents/Google Drive/TAMUCC-CORE/PIRE/database_albatross_recollections/db_files/sequ… SgA0106909F     Sgr-AMvi_069_Ex… Sgr-AMvi_069… FALSE              NA            NA                 NA             
```
</details>


Make metadata sheets for GEOME upload. This will output csv files of the sites/sampling times for the specified list of extraction IDs into the specified path for upload to GEOME. The user need to update some columns (indicated in the messages output to the console) to match GEOME requirements.
```
output_geome_metadata(extraction_ids, path/for/output, sequence_ids = original_sequence_id)
```

## Adding Data to the Database
After cloning the repo locally:
* Add a new table to the relevant subdirectory in [`staging`](staging). Each folder contains an "EXAMPLE" file with the proper file header to use and a readme describing what the columns should contain. Be sure to use the exact same column names and cell formatting as the existing table in that directory. 
* Use an informative name of the format INITIALS-YEAR-MONTH-DAY-DESC.tsv, where you're using your initials, the 4-digit year, the 2-digit month, and a short description without any punctuation or spaces.
* Use the `update_database()` function (available after opening `database_albatross_recollections.Rproj`) which will validate the data being input and copy the files into the database. The terminal output should look similar to below.
	- If there are problems with the data fix them as instructed by the error messages
	```
	> update_database()
                              
	── PIRE Database Staging Validation ─────────────────────────────────────────────────────────────────────────────────
	ℹ Found 4 file(s) to validate                                                                                        
																														 
	── Validating: dna_extractions_sheets/jds-2025-09-10-summer2025Sde_extractions.tsv ──
								  
	✔ Checking column structure... [11ms]
	✔ Checking for missing primary keys... [32ms]
	✔ Checking for duplicate primary keys... [51ms]
	✔ Checking foreign key constraints... [38ms]
	✔ Checking data quality... [47ms]
	✔ Running table-specific validations... [32ms]
	✔ jds-2025-09-10-summer2025Sde_extractions.tsv - PASSED all validations
	! Extra columns found (will be removed):
	  - elution1_gel_score_odu
	  - elution2_gel_score_odu
	  - elution3_gel_score_odu
	  - elution4_gel_score_odu
	ℹ Loading current database...
								  
	── Validating: individuals_sheets/jds-2025-09-10-summer2025Sde_individuals.tsv ──
								  
	✔ Checking column structure... [12ms]
	✔ Checking for missing primary keys... [32ms]
	✔ Checking for duplicate primary keys... [52ms]
	✔ Checking foreign key constraints... [50ms]
	✔ Checking data quality... [43ms]
	✔ Running table-specific validations... [28ms]
	✔ jds-2025-09-10-summer2025Sde_individuals.tsv - PASSED all validations
	ℹ Loading current database...
								  
	── Validating: lots_sheets/jds-2025-09-10-summer2025Sde_lots.tsv ──
								  
	✔ Checking column structure... [12ms]
	✔ Checking for missing primary keys... [34ms]
	✔ Checking for duplicate primary keys... [49ms]
	✔ Checking data quality... [44ms]
	✔ Running table-specific validations... [29ms]
	✔ jds-2025-09-10-summer2025Sde_lots.tsv - PASSED all validations
	ℹ Loading current database...
								  
	── Validating: sampling_sites_sheets/jds-2025-09-10-summer2025Sde_sites.tsv ──
								  
	✔ Checking column structure... [12ms]
	✔ Checking for missing primary keys... [34ms]
	✔ Checking for duplicate primary keys... [51ms]
	✔ Checking data quality... [34ms]
	✔ Running table-specific validations... [29ms]
	✔ jds-2025-09-10-summer2025Sde_sites.tsv - PASSED all validations
	ℹ Loading current database...
	✔ Report saved to: validation_report_20250910_142034.txt
								  
	── Validation Summary ──      
								  
	ℹ Total files processed: 4    
	✔ Passed validation: 4        
								  
	── Integrating validated files 
	✔ Processing: jds-2025-09-10-summer2025Sde_extractions.tsv [51ms]                                                    
	✔ Integrated: dna_extractions_sheets - jds-2025-09-10-summer2025Sde_extractions_20250910_142035.tsv                   
	ℹ Applied 1 warning correction(s) to database version                                                                 
	✔ Removing extra columns: elution1_gel_score_odu, elution2_gel_score_odu, elution3_gel_score_odu, elution4_gel_score…
	✔ Integrated: individuals_sheets - jds-2025-09-10-summer2025Sde_individuals_20250910_142038.tsv                      
	✔ Processing: jds-2025-09-10-summer2025Sde_individuals.tsv [1.8s]
	✔ Integrated: lots_sheets - jds-2025-09-10-summer2025Sde_lots_20250910_142040.tsv                                    
	✔ Processing: jds-2025-09-10-summer2025Sde_lots.tsv [1.7s]
	✔ Integrated: sampling_sites_sheets - jds-2025-09-10-summer2025Sde_sites_20250910_142041.tsv                         
	✔ All files integrated successfully                  
	✔ Processing: jds-2025-09-10-summer2025Sde_sites.tsv [1.6s]
	✔ Loading current database... [10s]
	ℹ Loading current database...
	```
	
* Push back to GitHub

### Troubleshooting

<details>
  <summary> MacOS gfortran installation issues </summary>
  If you are having issues installing packages due to gfortran related issues on Mac, try installing the latest version from https://mac.r-project.org/tools/.
</details>