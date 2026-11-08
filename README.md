# Downtown Health Across Rural and Urban America

Exploring how downtowns are doing across different types of places, from large metros to small towns, using public data (US Census, USDA, etc) in R. Work in progress.

## Scripts

| Script | What it does |
|---|---|
| `R/build_tract_rurality.R` | Builds a national table with one row per 2020 census tract and three USDA rural/urban measures |
| `R/addtotractrurality.R` | Adds new variables to that table, creating `tractruralitywithaddedvariables`, without changing the original. Also updates the Added variables table below |
| `R/firsttimeACSpractice.R` | First practice pulling Census data: housing vacancy in Chittenden County, VT |
| `R/mapbymetrostatus.R` | Map of U.S. counties by metro and nonmetro status |

## Variables

The main dataset has one row per 2020 census tract (about 85,500 rows).

### Tract IDs and names (USDA)

| Column | Description |
|---|---|
| `tract_geoid` | 11-digit tract ID; matches ACS 2022 and later, including Connecticut's planning region codes |
| `tract_geoid_2020` | Original 2020 Census tract ID; differs from `tract_geoid` only in Connecticut |
| `county_geoid` | 5-digit county ID |
| `state_fips`, `state_name`, `county_name`, `tract_name` | Names and codes |

### Rurality (USDA Economic Research Service)

| Column | Level | Description |
|---|---|---|
| `metro_nonmetro` | County | Metro if RUCC is 1 to 3, otherwise Nonmetro |
| `rucc_2023`, `rucc_description` | County | Rural-Urban Continuum Code, 2023 (1 = largest metro, 9 = most rural) |
| `ruca_primary`, `ruca_primary_desc` | Tract | Rural-Urban Commuting Area code, 2020 (1 to 10; 99 = little to no people) |
| `ruca_secondary`, `ruca_secondary_desc` | Tract | Secondary RUCA code with more detail on commuting |

### Added variables (`R/addtotractrurality.R`)

This table updates automatically when `R/addtotractrurality.R` is run.

<!-- ADDED-VARIABLES-START -->
| Column | Source | Description | Rows with data |
|---|---|---|---|
| `qualified_census_tract_2026` | HUD, 2026 Qualified Census Tracts | TRUE if HUD designated the tract as low income for 2026 | 85,528 |
| `total_housing_units_2020_2024` | Census, ACS 2020-2024, B25002_001 | Total housing units | 85,377 |
| `vacant_housing_units_2020_2024` | Census, ACS 2020-2024, B25002_003 | Vacant housing units | 85,377 |
| `vacancy_rate_2020_2024` | Calculated | Vacant units divided by total units | 84,305 |
| `population_2020_2024` | Census, ACS 2020-2024, B01003_001 | Total population (estimate) | 85,377 |
<!-- ADDED-VARIABLES-END -->

## Data sources

- **USDA Economic Research Service:** Rural-Urban Commuting Area codes (2020) and Rural-Urban Continuum Codes (2023)
- **U.S. Census Bureau:** American Community Survey 2020-2024 5-year estimates
- **HUD:** 2026 Qualified Census Tracts

Data files aren't included in this repository. The scripts download or rebuild them.

## Notes

- Vacancy includes seasonal homes and units for rent or sale, so it isn't the same as abandonment.
- ACS figures are estimates; small tracts can have wide margins of error.
- Some tracts have no ACS data, such as the U.S. island territories other than Puerto Rico, and tracts with no housing units.
