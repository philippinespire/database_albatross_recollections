# Readme for individuals_sheets

These files are compiled into the individuals sheet of the database. All .tsv files in this directory need to have exactly the same headers and cell formats.

Column definitions and notes:
* Species_valid_name: Our best attempt at identifying this individual taxonomically. This may or may not be a Latin binomial. It may be a genus or a couple species. This field links to the species sheet.
* Lot_ID: The lot identification code for this individual. Links to the Lot sheet.
* Collection_site
* Equivalent_Albatross_Site
* Collection_Period: Albatross or Contemporary
* Individual_ID: unique code for this individual
* New_USNM
* USNM_Biorepository
* Species_ID_method: How Species_valid_name was determined
* Species_ID_person: Who determined the Species_valid_name
* Species_ID_notes: Notes on what's in Species_valid_name
* Notes: Other notes, not about species identification
* Species_ID_year: Year when Species_valid_name was determined
* Species_ID_month: Month when Species_valid_name was determined
* Species_ID_day: Day when Species_valid_name was determined
* Species_ID_date_originallyEntered: Not sure. This is not in a consistent date format (Malin's note 08/2025).
