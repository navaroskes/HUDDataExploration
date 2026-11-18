# Downtown Health Across Rural and Urban America

Exploring how downtowns are doing across different types of places, from large metros to small towns, using public data (US Census, USDA, etc) and HUD USPS vacancy data in R. Work in progress.

## Scripts

Run in this order:

| Script | What it does |
|---|---|
| `R/build_tract_rurality.R` | Builds a national table with one row per 2020 census tract and three USDA rural/urban measures |
| `R/addtotractrurality.R` | Adds new variables to that table, creating `tractruralitywithaddedvariables`, without changing the original. Also updates the Added variables table below |
| `R/HUDtractrurality.R` | **Builds the main dataset:** joins HUD USPS vacancy data to `tractruralitywithaddedvariables`, one row per census tract per quarter (2023-Q1 to 2025-Q4), and adds vacancy rates |
| `R/firsttimeACSpractice.R` | First practice pulling Census data: housing vacancy in Chittenden County, VT |
| `R/mapbymetrostatus.R` | Map of U.S. counties by metro and nonmetro status |

## Variables

The main dataset (`tract_hud_vacancy`, built by `R/HUDtractrurality.R`) has **one row per 2020 census tract per quarter**, 2023-Q1 to 2025-Q4 (about 85,000 tracts x 12 quarters, roughly 1 million rows). Columns come in this order: tract IDs and USDA rurality, the added tract variables, then time, vacancy rates, and the HUD vacancy counts.

Tract-level columns (IDs, rurality, and added variables) don't change by quarter, so each tract has the same values on all of its rows.

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
| `land_area_sqmi` | Census TIGER/Line cartographic boundaries, 2023 | Land area in square miles | 85,060 |
| `jobs_2022` | Census LEHD LODES 8, 2022 (workplace, all jobs) | Total jobs located in the tract | 80,813 |
| `downtown_jobs_2022` | Census LEHD LODES 8, 2022 (CNS07 + CNS17 + CNS18) | Retail, arts/entertainment, and accommodation/food jobs | 80,813 |
| `job_density_2022` | Calculated | All jobs per square mile | 80,810 |
| `downtown_job_density_2022` | Calculated | Downtown-type jobs per square mile | 80,810 |
| `jobs_per_resident_2022` | Calculated | Jobs in tract divided by tract population | 80,472 |
<!-- ADDED-VARIABLES-END -->

### Time (`R/HUDtractrurality.R`)

| Column | Description |
|---|---|
| `year`, `quarter`, `period` | When the HUD data was reported (e.g. 2025, Q4, "2025-Q4") |
| `epoch` | HUD's file layout period; `2020_plus` for every row in this dataset |

### HUD USPS vacancy (`R/HUDtractrurality.R`)

Each row is one quarter's snapshot for one tract. Most columns come in three versions: `res_` (residential), `bus_` (business), and `oth_` (other addresses).

**Vacancy rates (calculated)**

| Column | Description |
|---|---|
| `res_vacancy_rate`, `bus_vacancy_rate`, `oth_vacancy_rate` | Vacant addresses divided by total addresses |
| `res_nostat_rate`, `bus_nostat_rate` | No-stat addresses divided by total addresses |
| `res_long_vacant_share`, `bus_long_vacant_share` | Share of vacant addresses vacant 12 months or more |

**HUD counts (as published)**

| Columns | Description |
|---|---|
| `*_addresses` | Total addresses |
| `*_vacant`, `avg_days_vacant_res`, `avg_days_vacant_bus` | Addresses vacant (mail not collected for 90+ days) and average days vacant |
| `*_vac_lt_3mo` to `*_vac_gte_36mo` | Vacant addresses by how long they've been vacant (under 3 months to 36+ months) |
| `*_nostat`, `avg_days_nostat_res`, `avg_days_nostat_bus`, `*_ns_lt_3mo` to `*_ns_gte_36mo` | No-stat addresses (not receiving mail, e.g. under construction or demolished), average days, and by length of time |
| `*_pqv_now_inservice`, `*_pqv_now_nostat`, `*_pqns_now_inservice` | Changes since last quarter (e.g. vacant last quarter, in use now) |
| `*_new_addresses`, `*_drop_sites` | Addresses added this quarter; USPS drop sites |
| `hud_geoid` | Tract ID as HUD reported it (differs from `tract_geoid` only for some Connecticut tracts in 2023-Q1) |

## Data sources

- **USDA Economic Research Service:** Rural-Urban Commuting Area codes (2020) and Rural-Urban Continuum Codes (2023)
- **U.S. Census Bureau:** American Community Survey 2020-2024 5-year estimates; TIGER/Line cartographic boundaries (2023); LEHD Origin-Destination Employment Statistics (LODES 8, 2022)
- **HUD:** 2026 Qualified Census Tracts; Aggregated USPS Administrative Data on Address Vacancies (quarterly, census tract level)

Data files aren't included in this repository. The scripts download or rebuild them, except the HUD USPS vacancy data, which is restricted to registered government and nonprofit users and has to be requested from HUD User.

## Notes
# 
- Vacancy includes seasonal homes and units for rent or sale, so it isn't the same as abandonment.
- ACS figures are estimates; small tracts can have wide margins of error.
- Some tracts have no ACS data, such as the U.S. island territories other than Puerto Rico, and tracts with no housing units.
- HUD USPS vacancy uses 2020 census tracts starting in 2023-Q1, which is why the main dataset starts there. Earlier quarters use 2000 or 2010 tracts and would need a crosswalk.
- LODES only lists tracts with at least one job, so tracts with no jobs (and Puerto Rico, which isn't in LODES) have blank job columns.
- `downtown_jobs_2022` (retail, arts/entertainment, and accommodation/food jobs) is this project's own proxy for downtown activity, not a LODES variable.
