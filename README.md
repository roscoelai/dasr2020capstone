# Capstone Project Proposal

## Analysing Dengue Cases in Singapore

[Preview Current Version](https://roscoelai.github.io/dasr2020capstone/results/project_proposal.html)

### Overview
- Does the amount of rainfall affect numbers of dengue cases?
- Geographical location
- Property prices
- ...

### Data
- [Data.gov.sg](https://data.gov.sg/dataset?q=Dengue)
  - [x] Weekly case numbers from 2014 to 2018
  - [ ] Spatial data (Number of cases and location for past 14 days)
    - [ ] GeoJSON
    - [ ] Leaflet
  - [x] Manual download
  - [ ] Web scrape from R script
- Weather data
  - <s> Monthly records from [SingStat Table Builder](https://www.tablebuilder.singstat.gov.sg/publicfacing/initApiList.action)</s>
  - [x] Daily records from [Meteorological Service Singapore (MSS)](http://www.weather.gov.sg/climate-historical-daily/)
  - [x] Web scrape from R script
- Google Trends
  - [ ] Like what Prof. Roh did for COVID-19?
    - Search terms frequency for symptoms of dengue vs. number of cases?
- Others
  - ?

### Analysis Plan
- Simple
  - Weather (temperature, rainfall) vs. number of cases
    - Matching time between datasets
    - lubridate::epiweeks()
    - EpiWeek::epiweekToDate()
- More advanced
  - ?
- Grandiose (!!!)
  - Spatial analysis
    - Of what variables? Breeding habitat vs. number of cases?
