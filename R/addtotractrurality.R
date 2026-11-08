
library(tidyverse)
library(tidycensus)
library(here)

# 1. Load the rurality dataset (keep GEOIDs as text)
tract_rurality <- read_csv(here("Data", "tract_rurality.csv"),
                           col_types = cols(.default = col_character()),
                           na = c("", "NA"))

# 2. Download HUD's 2026 Qualified Census Tracts (skips if already downloaded)
raw_dir  <- here("Data", "raw")
qct_file <- file.path(raw_dir, "qct_2026.csv")
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

qct_url <- "https://hudgis-hud.opendata.arcgis.com/api/download/v1/items/f55f80843c9a436ba8e578a54cdd8cea/csv?layers=0"
if (!file.exists(qct_file)) download.file(qct_url, qct_file, mode = "wb")

qct_raw <- read_csv(qct_file, col_types = cols(.default = col_character()))

# Look at the file before using it
names(qct_raw)
nrow(qct_raw)
head(qct_raw)

# Find the 11-digit tract ID column
geoid_column <- names(qct_raw)[str_detect(str_to_upper(names(qct_raw)), "GEOID")][1]
geoid_column                                  # should print one column name

qct_tracts <- qct_raw %>%
  transmute(qct_geoid = str_pad(.data[[geoid_column]], 11, pad = "0")) %>%
  distinct()

# 3. Pull housing units, vacant units, and population for every tract (ACS 2020-2024)
acs_states <- c(state.abb, "DC", "PR")

vacancy <- map_dfr(acs_states, function(st) {
  message("Pulling ", st)
  get_acs(geography = "tract",
          state     = st,
          variables = c(total_units  = "B25002_001",
                        vacant_units = "B25002_003",
                        population   = "B01003_001"),   # NEW
          year      = 2024,
          survey    = "acs5",
          output    = "wide")
}) %>%
  mutate(vacancy_rate_2020_2024 = if_else(total_unitsE > 0,
                                          vacant_unitsE / total_unitsE,
                                          NA_real_)) %>%
  select(GEOID,
         total_housing_units_2020_2024 = total_unitsE,
         vacant_housing_units_2020_2024 = vacant_unitsE,
         vacancy_rate_2020_2024,
         population_2020_2024 = populationE)           # NEW

# 4. Add QCT first, then the vacancy columns
tractruralitywithaddedvariables <- tract_rurality %>%
  mutate(qualified_census_tract_2026 = tract_geoid %in% qct_tracts$qct_geoid |
           tract_geoid_2020 %in% qct_tracts$qct_geoid) %>%
  left_join(vacancy, by = c("tract_geoid" = "GEOID"))

# 5. Check it
View(tractruralitywithaddedvariables)
nrow(tractruralitywithaddedvariables) == nrow(tract_rurality)        # should be TRUE
count(tractruralitywithaddedvariables, qualified_census_tract_2026)  # TRUE should be a minority of tracts
sum(!qct_tracts$qct_geoid %in% c(tract_rurality$tract_geoid,
                                 tract_rurality$tract_geoid_2020))   # QCT tracts with no match (should be near 0)
sum(is.na(tractruralitywithaddedvariables$vacancy_rate_2020_2024))   # tracts with no rate
tractruralitywithaddedvariables %>%
  filter(is.na(vacancy_rate_2020_2024)) %>%
  count(state_name, sort = TRUE)                # where those tracts are
summary(tractruralitywithaddedvariables$vacancy_rate_2020_2024)
summary(tractruralitywithaddedvariables$population_2020_2024)       # NEW: typical tract is a few thousand people

# 6. Update the README's "Added variables" table
#    When you add a variable above, add one row here: column name, source, description.
variable_info <- tribble(
  ~column,                          ~source,                              ~description,
  "qualified_census_tract_2026",    "HUD, 2026 Qualified Census Tracts",  "TRUE if HUD designated the tract as low income for 2026",
  "total_housing_units_2020_2024",  "Census, ACS 2020-2024, B25002_001",  "Total housing units",
  "vacant_housing_units_2020_2024", "Census, ACS 2020-2024, B25002_003",  "Vacant housing units",
  "vacancy_rate_2020_2024",         "Calculated",                         "Vacant units divided by total units",
  "population_2020_2024",           "Census, ACS 2020-2024, B01003_001",  "Total population (estimate)"   # NEW
)

# Every column the script added (anything not in the original tract_rurality)
added_columns <- setdiff(names(tractruralitywithaddedvariables), names(tract_rurality))

# Warn about any added column with no description yet
undocumented <- setdiff(added_columns, variable_info$column)
if (length(undocumented) > 0) {
  warning("Add these to variable_info so they appear in the README: ",
          paste(undocumented, collapse = ", "))
}

# Build the table rows in the order the columns appear in the data
table_rows <- tibble(column = added_columns) %>%
  left_join(variable_info, by = "column") %>%
  mutate(source      = coalesce(source, "TBD"),
         description = coalesce(description, "TBD"),
         rows        = map_int(column, ~ sum(!is.na(tractruralitywithaddedvariables[[.x]]))),
         line        = paste0("| `", column, "` | ", source, " | ", description, " | ",
                              format(rows, big.mark = ","), " |")) %>%
  pull(line)

new_table <- c("| Column | Source | Description | Rows with data |",
               "|---|---|---|---|",
               table_rows)

# Replace only the lines between the two markers; the rest of the README stays as written
readme_path <- here("README.md")
readme      <- readLines(readme_path, encoding = "UTF-8")
start <- which(readme == "<!-- ADDED-VARIABLES-START -->")
end   <- which(readme == "<!-- ADDED-VARIABLES-END -->")
stopifnot(length(start) == 1, length(end) == 1, start < end)

readme <- c(readme[1:start], new_table, readme[end:length(readme)])
writeLines(readme, readme_path, useBytes = TRUE)
message("README updated: ", length(added_columns), " added variables listed")