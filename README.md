[Preview Current Version of Slides](https://roscoelai.github.io/dasr2020capstone/src/project_proposal2.html)

# Capstone Project Proposal: Analysing Dengue Cases in Singapore

## Overview
Dengue fever is a vector-borne infectious disease that are endemic in the tropical world. Singapore is one of several countries with high disease burden of dengue. In 2020, Singapore saw 1,158 dengue cases in a week of June - the highest number of weekly dengue cases ever recorded since 2014. Why is there a sudden spike in dengue cases this year?

### Questions
  - Does atmospheric variables influence the incidence of dengue cases?
    - Specifically, is higher humidity, precipitation, or temperature associated with increased numbers of dengue cases?
  - Can atmospheric variables predict the number of dengue cases?
  - Does the number of dengue cases increase with the number of COVID-19 cases?
  - Explain the different number of cases in different regions of Singapore



## Data
- Daily climate records from [Meteorological Service Singapore (MSS)](http://www.weather.gov.sg/climate-historical-daily/)
  - Relevant variables: Rainfall, Temperature
  - Data for 2012 to 2020 will be gathered from selected climate stations
- Weekly case numbers (2012-W01 to 2020-W25) from [Ministry of Health (MOH)](https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-2020ea2c0b1cec1549009844537d52f2377f.xlsx)
- Latest number of cases by named regions in Singapore from [National Environment Agency (NEA)](https://www.nea.gov.sg/dengue-zika/dengue/dengue-clusters)
- Yearly population distribution across named regions in Singapore
- COVID-19 cases (Apr - Jul 2020)

## Deprecated Data
- Monthly Air Temperature And Sunshine, Relative Humidity And Rainfall from [Singapore Department of Statistics (DOS)](https://www.tablebuilder.singstat.gov.sg/publicfacing/api/csv/title/15306.csv)
  - <u>Reason</u>: Higher resolution (daily) data available from MSS
  - Might reconsider if humidity data is needed
- Latest number of cases by regions with geocoordinates from [Data.gov.sg](https://data.gov.sg/dataset?q=Dengue)
  - <u>Reason</u>: Potentially **grandiose** (we've not learned leaflet yet!)
- Weekly case numbers (2012-W01 to 2020-W20) from [Data.gov.sg](https://data.gov.sg/dataset?q=Dengue)
  - <u>Reason</u>: More up-to-date data available from MOH



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
- For the current trend, explain the differences between the number of cases in different regions
  - According to the news report, East region has the largest number of clusters than other parts of Singapore
  - In particular, does Marine Parade and Sembawang (or Queenstown?) have any differences in their weather variable?

### Considerations and limitations
- Time lag: Dengue cases manifest 1-2 weeks after infection
  - Timing adjustments have to be made for ostensibly associated variables
- Seasonal effects
  - "Vector" months (June, July, August, September, October)
- COVID-19 cases vs. dengue cases
  - 90% foreign workers, expect a correlation
  - Compare against number of cases from Apr - Jul 2020



## Ideas
- Predictions!
  - Create model using data from 2014 to 2018
    - (Number of Cases) ~ Precipitation + Temperature [+ Humidity + ...]
  - Predict number of cases in 2020
  - Check against actual live data

- Grandiose (!!!)
  - Population distribution
  - Spatial analysis (of what variables)?
    - Breeding habitat vs. number of cases?
    - Property prices vs. number of cases?

## Todo
- [ ] [This might be useful](http://www.weather.gov.sg/wp-content/uploads/2016/12/Station_Records.pdf)
- [ ] Google Trends analysis (like what Prof. Roh did for COVID-19)?
    - Search term frequency for symptoms of dengue vs. number of cases
