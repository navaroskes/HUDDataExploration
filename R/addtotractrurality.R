# library(tidyverse)
# library(tidycensus)
# library(here)
# 
# # 1. Load the rurality dataset (keep GEOIDs as text)
# tract_rurality <- read_csv(here("HUD", "Data", "tract_rurality.csv"),
#                            col_types = cols(.default = col_character()),
#                            na = c("", "NA"))
# 
# # 2. Pull total and vacant housing units for every tract (ACS 2020-2024)
# acs_states <- c(state.abb, "DC", "PR")
# 
# vacancy <- map_dfr(acs_states, function(st) {
#   message("Pulling ", st)
#   get_acs(geography = "tract",
#           state     = st,
#           variables = c(total_units  = "B25002_001",
#                         vacant_units = "B25002_003"),
#           year      = 2024,
#           survey    = "acs5",
#           output    = "wide")
# }) %>%
#   mutate(vacancy_rate_2020_2024 = if_else(total_unitsE > 0,
#                                           vacant_unitsE / total_unitsE,
#                                           NA_real_)) %>%
#   select(GEOID, vacancy_rate_2020_2024)
# 
# # 3. Add it as the last column
# tractruralitywithaddedvariables <- tract_rurality %>%
#   left_join(vacancy, by = c("tract_geoid" = "GEOID"))
# 
# # 4. Check it
# View(tractruralitywithaddedvariables)
# nrow(tractruralitywithaddedvariables) == nrow(tract_rurality)        # should be TRUE
# sum(is.na(tractruralitywithaddedvariables$vacancy_rate_2020_2024))   # tracts with no rate
# tractruralitywithaddedvariables %>%
#   filter(is.na(vacancy_rate_2020_2024)) %>%
#   count(state_name, sort = TRUE)                # where those tracts are
# summary(tractruralitywithaddedvariables$vacancy_rate_2020_2024)

# library(tidyverse)
# library(tidycensus)
# library(here)
# 
# # 1. Load the rurality dataset (keep GEOIDs as text)
# tract_rurality <- read_csv(here("HUD", "Data", "tract_rurality.csv"),
#                            col_types = cols(.default = col_character()),
#                            na = c("", "NA"))
# 
# # 2. Pull total and vacant housing units for every tract (ACS 2020-2024)
# acs_states <- c(state.abb, "DC", "PR")
# 
# vacancy <- map_dfr(acs_states, function(st) {
#   message("Pulling ", st)
#   get_acs(geography = "tract",
#           state     = st,
#           variables = c(total_units  = "B25002_001",
#                         vacant_units = "B25002_003"),
#           year      = 2024,
#           survey    = "acs5",
#           output    = "wide")
# }) %>%
#   mutate(vacancy_rate_2020_2024 = if_else(total_unitsE > 0,
#                                           vacant_unitsE / total_unitsE,
#                                           NA_real_)) %>%
#   select(GEOID,
#          total_housing_units_2020_2024 = total_unitsE,
#          vacant_housing_units_2020_2024 = vacant_unitsE,
#          vacancy_rate_2020_2024)
# 
# # 3. Add them as the last columns
# tractruralitywithaddedvariables <- tract_rurality %>%
#   left_join(vacancy, by = c("tract_geoid" = "GEOID"))
# 
# # 4. Check it
# View(tractruralitywithaddedvariables)
# nrow(tractruralitywithaddedvariables) == nrow(tract_rurality)        # should be TRUE
# sum(is.na(tractruralitywithaddedvariables$vacancy_rate_2020_2024))   # tracts with no rate
# tractruralitywithaddedvariables %>%
#   filter(is.na(vacancy_rate_2020_2024)) %>%
#   count(state_name, sort = TRUE)                # where those tracts are
# summary(tractruralitywithaddedvariables$vacancy_rate_2020_2024)
library(tidyverse)
library(tidycensus)
library(here)

# 1. Load the rurality dataset (keep GEOIDs as text)
tract_rurality <- read_csv(here("HUD", "Data", "tract_rurality.csv"),
                           col_types = cols(.default = col_character()),
                           na = c("", "NA"))

# 2. Download HUD's 2026 Qualified Census Tracts (skips if already downloaded)
raw_dir  <- here("HUD", "Data", "raw")
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

# 3. Pull total and vacant housing units for every tract (ACS 2020-2024)
acs_states <- c(state.abb, "DC", "PR")

vacancy <- map_dfr(acs_states, function(st) {
  message("Pulling ", st)
  get_acs(geography = "tract",
          state     = st,
          variables = c(total_units  = "B25002_001",
                        vacant_units = "B25002_003"),
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
         vacancy_rate_2020_2024)

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

