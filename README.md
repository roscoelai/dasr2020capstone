# Analysing Dengue Cases in Singapore

[Preview Current Version of Document](https://roscoelai.github.io/dasr2020capstone/src/capstone_project_html.html)

[Preview Current Version of Leaflet Map](https://roscoelai.github.io/dasr2020capstone/src/capstone_leaflet_html.html)

## Meeting (08 Jul 2020)
### S
- Q1: Case numbers for different diseases across 2012-2020
  - Plot weekly by months for each year - line/bar graph and heat map
  - Compare significant differences between years
- Q2: Weather variables across 2012 - 2020
  - Variables: daily temperature, wind speed, daily total rainfall
  - Aggregate to weekly data - median, mean, min, max, range
  - Plot weekly by months for each year - bar graph and heat map

### A
- Q3: Correlate case numbers and weather variables in general
  - For each disease to each weather variables
  - Which disease is most related to weather
- Q4: Regression model
  - Y (number of cases) = temperature range + e
  - Y (number of cases) = temperature range + total rainfall + e
  - Y (number of cases) = temperature range + total rainfall + humidity + e
- Q5: Identify highest rainfall months and plot the number of cases over the years

### R
- Q7: Compare cases across Singapore regions
  - [x] Geographical plots using Leaflet
  - [x] Leaflet with clusterOptions
- R scripts for data import and tidy (and maybe collect... and maybe transform)
  - [x] Tidy MOH weekly bulletin data
  - [x] Import MSS daily weather data
- Spatial Analysis
  - [x] Population
  - [x] Area
  - [x] Number of clinics
  - [x] Type of housing
  - [ ] Weather
    - [ ] Reintroduce **more** climate stations

### Others
- Q6: Find intervention data (optional)

---

## Data
- [Weekly Infectious Disease Bulletin, Ministry of Health (MOH)](https://www.moh.gov.sg/resources-statistics/infectious-disease-statistics/2020/weekly-infectious-diseases-bulletin)
  - [Manual download (2012-W01 to 2020-W28)](https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-2020f3b1838244614d8a812f10e1febd31b1.xlsx)
  - [Tidied subset (2012-W01 to 2020-W28)](https://raw.githubusercontent.com/roscoelai/dasr2020capstone/master/data/moh_weekly_bulletin_s_2012_2020_tidy_20200717.csv)
- [Historical Daily Records, Meteorological Service Singapore (MSS)](http://www.weather.gov.sg/climate-historical-daily/)
  - Daily rainfall
  - Daily temperature and wind speed measurements for some climate stations
  - [Script](https://github.com/roscoelai/dasr2020capstone/blob/master/src/import_mss_daily.R) to consolidate selected time periods for selected stations
  - [Tidied subset](https://raw.githubusercontent.com/roscoelai/dasr2020capstone/master/data/mss_daily_2012_2020_4stations_20200714.csv)
- Approximate geocoordinates of dengue cases, [Data.gov.sg](https://data.gov.sg/search?q=denguecases)

<div style="margin: auto; width: 80%">
| Date       | Central        | North East      | South East      | South West      |
|------------|----------------|-----------------|-----------------|-----------------|
| 2020-06-26 | [.kml file](https://geo.data.gov.sg/denguecase-central-area/2020/06/26/kml/denguecase-central-area.kml) | [.kml file](https://geo.data.gov.sg/denguecase-northeast-area/2020/06/26/kml/denguecase-northeast-area.kml)  | [.kml file](https://geo.data.gov.sg/denguecase-southeast-area/2020/06/26/kml/denguecase-southeast-area.kml)  | [.kml file](https://geo.data.gov.sg/denguecase-southwest-area/2020/06/26/kml/denguecase-southwest-area.kml)  |
| 2020-07-07 | [.kml file](https://geo.data.gov.sg/denguecase-central-area/2020/07/07/kml/denguecase-central-area.kml) | [.kml file](https://geo.data.gov.sg/denguecase-northeast-area/2020/07/07/kml/denguecase-northeast-area.kml)  | [.kml file](https://geo.data.gov.sg/denguecase-southeast-area/2020/07/07/kml/denguecase-southeast-area.kml)  | [.kml file](https://geo.data.gov.sg/denguecase-southwest-area/2020/07/07/kml/denguecase-southwest-area.kml)  |
| 2020-07-09 | [.kml file](https://geo.data.gov.sg/denguecase-central-area/2020/07/09/kml/denguecase-central-area.kml) | [.kml file](https://geo.data.gov.sg/denguecase-northeast-area/2020/07/09/kml/denguecase-northeast-area.kml) | [.kml file](https://geo.data.gov.sg/denguecase-southeast-area/2020/07/09/kml/denguecase-southeast-area.kml) | [.kml file](https://geo.data.gov.sg/denguecase-southwest-area/2020/07/09/kml/denguecase-southwest-area.kml) |
</div>

- [Singapore Residents by Planning Area and Type of Dwelling, Jun 2017](https://data.gov.sg/dataset/singapore-residents-by-planning-area-and-type-of-dwelling-jun-2017), Data.gov.sg
  - Planning areas (URA MP14)
  - Populations of planning areas
  - Breakdown by type of dwelling
  - [.kml file](https://geo.data.gov.sg/plan-bdy-dwelling-type-2017/2017/09/27/kml/plan-bdy-dwelling-type-2017.kml)
- [CHAS Clinics](https://data.gov.sg/dataset/chas-clinics), Data.gov.sg
  - Geocoordinates of CHAS clinics
  - [.kml file](https://geo.data.gov.sg/moh-chas-clinics/2020/07/05/kml/moh-chas-clinics.kml)

### Unsourceable
- Yearly population distribution across named regions in Singapore
- COVID-19 cases (Apr - Jul 2020)

### Deprecated
- [Monthly Air Temperature And Sunshine, Relative Humidity And Rainfall, Singapore Department of Statistics (DOS)](https://www.tablebuilder.singstat.gov.sg/publicfacing/initApiList.action)
  - Higher resolution (daily) data available from MSS
  - Might reconsider if humidity data is needed
  - [.csv file](https://www.tablebuilder.singstat.gov.sg/publicfacing/api/csv/title/15306.csv)
- [Resident Population by Planning Area/Subzone and Type of Dwelling, 2015](https://data.gov.sg/dataset/resident-population-by-planning-area-subzone-and-type-of-dwelling-2015), Data.gov.sg
  - Populations of planning areas
  - Breakdown by type of dwelling
  - [.csv file](https://storage.data.gov.sg/resident-population-by-planning-area-subzone-and-type-of-dwelling-2015/resources/resident-population-by-planning-area-and-type-of-dwelling-2020-07-15T06-05-58Z.csv)
- [Resident Population by Planning Area/Subzone, Age Group and Sex, 2015](https://data.gov.sg/dataset/resident-population-by-planning-area-subzone-age-group-and-sex-2015), Data.gov.sg
  - Populations of planning areas
  - Breakdown by age groups
  - [.csv file](https://storage.data.gov.sg/resident-population-by-planning-area-subzone-age-group-and-sex-2015/resources/resident-population-by-planning-area-age-group-and-sex-2019-07-30T03-02-18Z.csv)
- [Master Plan 2014 Planning Area Boundary (No Sea)](https://data.gov.sg/dataset/master-plan-2014-planning-area-boundary-no-sea), Data.gov.sg
  - Names and sizes of planning areas
  - [.zip file](https://geo.data.gov.sg/mp14-plng-area-no-sea-pl/2016/05/11/kml/mp14-plng-area-no-sea-pl.zip)

---

# Capstone Project Proposal

![](./imgs/ncases_4diseases_sep_2012_2020.png)

![](./imgs/ncases_2012_2020.png)

## Overview
Dengue fever is a vector-borne infectious disease that are endemic in the tropical world. Singapore is one of several countries with high disease burden of dengue. In 2020, Singapore saw 1,158 dengue cases in a week of June - the highest number of weekly dengue cases ever recorded since 2014. Why is there a sudden spike in dengue cases this year?

### Questions
  - Does atmospheric variables influence the incidence of dengue cases?
    - Specifically, is higher humidity, precipitation, or temperature associated with increased numbers of dengue cases?
  - Can atmospheric variables predict the number of dengue cases?
  - Does the number of dengue cases increase with the number of COVID-19 cases?
  - Explain the different number of cases in different regions of Singapore



## <s>Data</s>
(Moved)



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

### Address
- Time lag: Dengue cases manifest 1-2 weeks after infection
  - Timing adjustments have to be made for ostensibly associated variables
- Seasonal effects
  - "Vector" months (June, July, August, September, October)
- COVID-19 cases vs. dengue cases
  - 90% foreign workers, expect a correlation
  - Compare against number of cases from Apr - Jul 2020

---
