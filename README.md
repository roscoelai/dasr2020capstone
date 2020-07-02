# Capstone Project Proposal

## Analysing Dengue Cases in Singapore

[Preview Current Version](https://roscoelai.github.io/dasr2020capstone/results/project_proposal.html)

### Overview
- Does the amount of rainfall or temperature affect numbers of dengue cases?
- Geographical location
- Property prices
- ...
- Predictions!
  - Create model using data from 2014 to 2018
  - Predict number of cases in 2020
  - Check against actual live data

### Data
- Weather data
  - [x] Daily records from [Meteorological Service Singapore (MSS)](http://www.weather.gov.sg/climate-historical-daily/)
    - [ ] May need data from other sites (get scraping)
- Number of cases
  - [x] [Data.gov.sg](https://data.gov.sg/dataset?q=Dengue)
- Coordinates of zones with numbers of cases
  - [x] [Data.gov.sg](https://data.gov.sg/dataset?q=Dengue)
- Population distribution across named regions (not coordinates)
  - [x] respopagesextod2011to2019.csv
- [ ] Data from NEA
- Google Trends
  - [ ] Like what Prof. Roh did for COVID-19?
    - Search terms frequency for symptoms of dengue vs. number of cases?
- [ ] Tourists
  - [ ] Visitors from South-East Asia
  - Tourists diagnosed in Singapore (0.3 / 100,000 travellers)
- Others
  - ?

### Analysis Plan (not very organized...)
- Time lag
  - Dengue cases would manifest 1-2 weeks after whatever ostensible causes
- Seasonal effects
  - "Vector" months (June, July, August, September, October)
- Population distribution
- COVID-19 cases vs. dengue cases
  - 90% foreign workers -> expect correlation
  - Number of cases from Apr 2020
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
