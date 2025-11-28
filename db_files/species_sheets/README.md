# Readme for species_sheet_*.tsv

Each line is a species.

## Species Sheet Column Descriptions
| Column Name                                               | Description                                                                      |
| --------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Family**                                                | Taxonomic family name                                                            |
| **Family\_Ecology**                                       | General ecological characteristics of the family (e.g., Tropical, Temperate)     |
| **Genera\_in\_Fam**                                       | Number of genera in the family                                                   |
| **Spp\_in\_Fam**                                          | Number of species in the family                                                  |
| **Spp\_in\_genus**                                        | Number of species in the genus                                                   |
| **Species\_Albatross\_name**                              | Species name as recorded in Albatross expedition records                         |
| **Species\_valid\_name**                                  | Currently accepted valid scientific species name (genus capitalized, underscore between genus and species). Because some individuals cannot be identified to a single species, this column also contains composite names (e.g., spp1/spp2) or genera (e.g., Genus_sp). (**Primary Key**)                                |
| **Species\_Code**                                         | Abbreviated species code used in project                                         |
| **Common\_name**                                          | Common name of the species                                                       |
| **General\_Fishing\_Pressure**                            | General fishing pressure on the species (e.g., unfished, minor commercial, bait) |
| **Different\_fishing\_pressure\_depending\_on\_locality** | Notes on how fishing pressure varies by region/locality                          |
| **Habitat\_1**                                            | Primary habitat type                                                             |
| **Authority**                                             | Taxonomic authority for the species name                                         |
| **No\_of\_Alb\_sites**                                    | Number of Albatross expedition sites where species was recorded                  |
| **Alb\_sites**                                            | List of Albatross sites where species was recorded                               |
| **USNM\_lot\_No\_(number\_of\_indiv)**                    | U.S. National Museum lot number and number of individuals                        |
| **No\_of\_C\_sites**                                      | Number of contemporary sites where species was recorded                          |
| **C\_sites**                                              | List of contemporary sites where species was recorded                            |
| **Fising\_pressure?**                                     | Indicator if species is under fishing pressure (Yes/No/Unknown)                  |
| **Trophic\_group**                                        | Trophic group (e.g., herbivore, carnivore, omnivore)                             |
| **Diet**                                                  | Notes on species diet                                                            |
| **Habitat\_2**                                            | Secondary habitat type (if applicable)                                           |
| **Depth\_(m)**                                            | Depth range in meters                                                            |
| **Behavior**                                              | Behavioral notes (e.g., schooling, solitary)                                     |
| **Global\_Distribution**                                  | Broad global distribution of the species                                         |
| **Regional\_Distribution**                                | Regional distribution of the species                                             |
| **Max\_Length\_(cm)**                                     | Maximum known length in centimeters                                              |
| **Notes**                                                 | Free-text notes                                                                  |
| **Red\_list\_status**                                     | IUCN Red List conservation status                                                |
| **References**                                            | References for taxonomy, ecology, or conservation status                         |

## Initial Sheet Conversion 
Conversion from onedrive excel file database to github based database on 7 November 2025. Using [`scripts/database_transfer_from_onedrive/transfer_sheets_to_repo.R`](scripts/database_transfer_from_onedrive/transfer_sheets_to_repo.R). OneDrive database no longer maintained or added to after this date.
