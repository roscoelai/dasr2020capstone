# Capstone Project Proposal

## Analysing Dengue Cases in Singapore

[Preview Current Version](https://roscoelai.github.io/dasr2020capstone/results/project_proposal.html)

### Overview
- Questions
  - Does atmospheric variables influence the incidence of dengue cases?
    - Specifically, does higher humidity, precipitation, or temperature increase the number of dengue cases?
  - Can atmospheric variables predict the number of dengue cases?
  - Does the number of dengue cases increase with the number of COVID-19 cases?
  - Explain the different number of cases in different regions of Singapore

### Data
- Weather data
  - [x] Daily records from [Meteorological Service Singapore (MSS)](http://www.weather.gov.sg/climate-historical-daily/)
    - [x] Changi station (reference) (1980 - 2020, daily)
    - [ ] May also need data from other stations
  - [x] Air Temperature And Sunshine, Relative Humidity And Rainfall, Monthly from [Singapore Department of Statistics (DOS)](https://www.tablebuilder.singstat.gov.sg/publicfacing/api/csv/title/15306.csv)
- Number of cases by epidemiological weeks
  - [x] [Data.gov.sg](https://data.gov.sg/dataset?q=Dengue) (2012-W01 to 2020-W20)
  - [x] [Ministry of Health](https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-2020ea2c0b1cec1549009844537d52f2377f.xlsx) (2012-W01 to 2020-W25)
- Coordinates of zones with numbers of cases (past 14 days)
  - [x] [Data.gov.sg](https://data.gov.sg/dataset?q=Dengue)
- COVID-19 cases (Apr - Jul 2020)
  - [ ] ?
- Population distribution across named regions (not coordinates) (2011 to 2019, yearly)
  - [x] respopagesextod2011to2019.csv
- Latest clusters by regions
  - [ ] [National Environment Agency](https://www.nea.gov.sg/dengue-zika/dengue/dengue-clusters)
- Google Trends
  - [ ] Like what Prof. Roh did for COVID-19?
    - Search terms frequency for symptoms of dengue vs. number of cases?

### Analysis Plan (not very organized...)
- Considerations
  1. Combining datasets (standardize timeframe and resolution)
    - Converting dates to epidemiological weeks
      - lubridate::epiweeks()
    - Converting epidemiological weeks to months
      - EpiWeek::epiweekToDate()
  2. Time lag: Dengue cases manifest 1-2 weeks after infection
    - So, adjust timings for different dataset accordingly
  3. Seasonal effects
    - "Vector" months (June, July, August, September, October)
  4. COVID-19 cases vs. dengue cases
    - 90% foreign workers -> expect correlation
    - Number of cases from Apr - Jul 2020

- Predictions!
  - Create model using data from 2014 to 2018
    - Number of dengue cases ~ Humidity, Precipitation, Temperature, ...
  - Predict number of cases in 2020
  - Check against actual live data

- Grandiose (!!!)
  - Population distribution
  - Spatial analysis
    - Of what variables? Breeding habitat vs. number of cases?
