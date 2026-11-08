# firsttimeACSpractice.R
# First practice pulling American Community Survey (ACS) data with tidycensus.
# Goal: get housing vacancy by census tract and calculate vacancy rates.

# ---- 1. Packages (run install line once, then comment it out) ----
# install.packages(c("tidycensus", "tidyverse"))
library(tidycensus)
library(tidyverse)

# ---- 2. Census API key (one-time setup) ----
# Get a free key at https://api.census.gov/data/key_signup.html
# Then run this ONCE (install = TRUE saves it so you never need it again):
# census_api_key("YOUR_KEY_HERE", install = TRUE)# readRenviron("~/.Renviron")

# ---- 3. Look up variable names ----
# Loads every ACS 5-year variable so you can search them
acs_vars <- load_variables(2023, "acs5", cache = TRUE)

# Find the occupancy status table (B25002)
acs_vars %>% filter(str_detect(name, "B25002"))

# ---- 4. Pull vacancy data by tract ----
# B25002_001 = total housing units
# B25002_002 = occupied
# B25002_003 = vacant
vt_vacancy <- get_acs(
  geography = "tract",
  state     = "VT",
  county    = "Chittenden",
  variables = c(total    = "B25002_001",
                occupied = "B25002_002",
                vacant   = "B25002_003"),
  year      = 2023,          # 2019-2023 5-year estimates
  survey    = "acs5",
  output    = "wide"         # one row per tract
)

# Look at what came back
glimpse(vt_vacancy)
# Columns ending in E = estimate, M = margin of error

# ---- 5. Calculate vacancy rate ----
vt_vacancy <- vt_vacancy %>%
  mutate(vacancy_rate = vacantE / totalE * 100) %>%
  arrange(desc(vacancy_rate))

head(vt_vacancy %>% select(NAME, totalE, vacantE, vacancy_rate), 10)

# County-wide summary
vt_vacancy %>%
  summarise(
    tracts          = n(),
    total_units     = sum(totalE),
    vacant_units    = sum(vacantE),
    county_vac_rate = vacant_units / total_units * 100
  )

# ---- 6. Quick chart: vacancy rate by tract ----
ggplot(vt_vacancy, aes(x = reorder(NAME, vacancy_rate), y = vacancy_rate)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Housing vacancy rate by census tract, Chittenden County, VT",
    subtitle = "ACS 2019-2023 5-year estimates",
    x = NULL,
    y = "Vacancy rate (%)"
  ) +
  theme_minimal(base_size = 8)
