# Capstone Project Proposal: Analysing Dengue Cases in Singapore

[Preview Current Version of Slides](https://roscoelai.github.io/dasr2020capstone/src/project_proposal.html)

## Overview
- Questions
  - Does atmospheric variables influence the incidence of dengue cases?
    - Specifically, does higher humidity, precipitation, or temperature increase the number of dengue cases?
  - Can atmospheric variables predict the number of dengue cases?
  - Does the number of dengue cases increase with the number of COVID-19 cases?
  - Explain the different number of cases in different regions of Singapore.

## Data
- Climate
  - [x] Daily records from [Meteorological Service Singapore (MSS)](http://www.weather.gov.sg/climate-historical-daily/)
    - Range
      - 2012 to 2020
    - Resolution
      - Daily
    - Variables
      - Rainfall
      - Temperature
      - <s>Wind speed</s>
    - Stations
      - [x] Changi
      - [x] Marine Parade
      - [x] Queenstown
      - [x] Sembawang
  - [x] <s>Air Temperature And Sunshine, Relative Humidity And Rainfall, Monthly from [Singapore Department of Statistics (DOS)](https://www.tablebuilder.singstat.gov.sg/publicfacing/api/csv/title/15306.csv)</s>
    - Resolution
      - Monthly
    - Additional variables
      - 24 hours mean relative humidity (%)
      - Bright sunshine daily mean (hours)
      - Minimum relative humidity (%)
      - Number of rainy days
- Number of cases
  - [x] <s>[Data.gov.sg](https://data.gov.sg/dataset?q=Dengue)</s>
    - Range
      - 2012-W01 to 2020-W20
    - Resolution
      - (Epidemiological) Week
  - [x] [Ministry of Health](https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-2020ea2c0b1cec1549009844537d52f2377f.xlsx)
    - Range
      - 2012-W01 to 2020-W25
    - Resolution
      - (Epidemiological) Week
- COVID-19 cases (Apr - Jul 2020)
  - [ ] ?
- Latest clusters by regions
  - [x] [National Environment Agency](https://www.nea.gov.sg/dengue-zika/dengue/dengue-clusters)
  - [x] <s>Coordinates of zones with numbers of cases for past 14 days from [Data.gov.sg](https://data.gov.sg/dataset?q=Dengue)</s>
- Population distribution across named regions (not coordinates) (2011 to 2019, yearly)
  - [x] respopagesextod2011to2019.csv
- Google Trends
  - [ ] Like what Prof. Roh did for COVID-19?
    - Search terms frequency for symptoms of dengue vs. number of cases?

## Analysis Plan
- Transform dengue cases data
  - Converting epidemiology weeks cases to monthly cases for 2012 - 2020
  - Combine the different Excel sheets into a table 
- Compare the monthly cases across the years
  - Using repeated-measures ANOVA
  - Plotting
- To understand if atmospheric variables have an influence in the incidence of dengue cases
  - Correlate the weather variables with number of dengue cases monthly across the years
- To test if atmospheric variables predict number of dengue cases
  - Create models for regression
  - Compare the predicted value with actual value
- Explain the current trend in differences between the number of cases in different regions
  - According to Strait's Times report, East region has the largest number of clusters than North (and West?) regions
  - Pick Marine Parade and Sembawang (or Queenstown?) to find out if there is a difference in their weather variables

### Considerations and limitations
- Time lag: Dengue cases manifest 1-2 weeks after infection
  - So, adjust timings for different datasets accordingly
- Seasonal effects
  - "Vector" months (June, July, August, September, October)
- COVID-19 cases vs. dengue cases
  - 90% foreign workers -> expect correlation
  - Number of cases from Apr - Jul 2020



## Ideas
- Predictions!
  - Create model using data from 2014 to 2018
    - Number of dengue cases ~ Humidity, Precipitation, Temperature, ...
  - Predict number of cases in 2020
  - Check against actual live data

- Grandiose (!!!)
  - Population distribution
  - Spatial analysis
    - Of what variables? Breeding habitat vs. number of cases?
