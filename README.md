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

## How to use this repo
This repository uses [renv](https://rstudio.github.io/renv/) to create a reproductible R environment. 


1. Clone this repository to your local machine by typing the following on the command line:
```bash
git clone git@github.com:philippinespire/database_albatross_recollections.git
```
2. Navigate to the database folder and open `database_albatross_recollections.Rproj` in `RStudio`. Something like the following should be shown in your console:
```r
# Bootstrapping renv 1.1.2 ---------------------------------------------------
- Downloading renv ... OK
- Installing renv  ... OK

- Project 'C:/Users/jdsel/Downloads/database_albatross_recollections' loaded. [renv 1.1.2]
- One or more packages recorded in the lockfile are not installed.
- Use `renv::status()` for more details.

============================================================
 PROJECT: database_albatross_recollections
============================================================

⚠️  PACKAGES NEED TO BE INSTALLED
   Missing 144 packages

============================================================
 ACTION REQUIRED:
============================================================

 Run this command to install all required packages:

   renv::restore()

 This will take a few minutes on first setup.
 After installation, restart R (Session → Restart R)
============================================================

📌 Commands available:
   • setup_project()    - Install all packages (run this first!)
   • check_setup()      - Check project status
   • open_main_script() - Open main script (after setup)
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
Once the R profile is correctly running, you have access to new project specific R functions (see below) that can be used to locally build the database.

4. If this is the first time cloning the repo use the R function `setup_project()` in the R console to install needed packages and restart R (Session → Restart R or Ctrl+Shift+F10).

```r
# In the R console
>setup_project()
```

5. To locally build the database, use the R function `open_main_script()` to open [`scripts/assemble_db.R`](scripts/assemble_db.R) to interactively create the database as a `dm` object. Alternatively, open and run the lines in`scripts/assemble_db.R`.

```r
# In the R console
>open_main_script()
```


### Troubleshooting

<details>
  <summary> MacOS gfortran installation issues </summary>
  If you are having issues installing packages due to gfortran related issues on Mac, try installing the latest version from https://mac.r-project.org/tools/.
</details>

## How to use the database
Once the database is cloned and built locally, you can actively start using it. Below a few example usages are given. 

Before using the database, make sure the helper scripts and libraries are loaded and join the database together by sourcing `scripts/assemble_db.R` .

```r
# See also scripts/assemble_db.R
source('scripts/assemble_db.R')
```

**Example 1: Counting the number of samples from a collection site**


```r
#Obtain distinct collection sites
pull_tbl(full_db, "individuals_sheets") %>%
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
pull_tbl(full_db, "individuals_sheets") %>%
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
pull_tbl(full_db, "individuals_sheets") %>%
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
pull_tbl(full_db, "individuals_sheets") %>%
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

## How to edit the database
After cloning the repo locally:
* Add a new table to the relevant subdirectory in `db_files`. Be sure to use the exact same column names and cell formatting as the existing table in that directory. 
* Use an informative name of the format INITIALS-YEAR-MONTH-DAY-DESC.tsv, where you're using your initials, the 4-digit year, the 2-digit month, and a short description without any punctuation or spaces.
* The database creation script reads in and row-binds all files in a given directory to create the relevant database tables.
* Check the [`scripts/assemble_db.R`](scripts/assemble_db.R) runs correctly with your new file
* Push back to GitHub
