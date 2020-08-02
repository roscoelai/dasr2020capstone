# Analysing Dengue Cases in Singapore

[Current Version of HTML Document](https://roscoelai.github.io/dasr2020capstone/src/capstone_project_html.html)

[Current Version of Leaflet Map](https://roscoelai.github.io/dasr2020capstone/src/capstone_leaflet_html.html)

---

## Data
- [Weekly Infectious Disease Bulletin, Ministry of Health (MOH)](https://www.moh.gov.sg/resources-statistics/infectious-disease-statistics/2020/weekly-infectious-diseases-bulletin)
  - [Latest data as of 31 July 2020 (2012-W01 to 2020-W30)](https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-2020d1092fcb484447bc96ef1722b16b0c08.xlsx)
  - [Backup copy as of 31 July 2020 (2012-W01 to 2020-W30)](https://raw.githubusercontent.com/roscoelai/dasr2020capstone/master/data/moh/weekly-infectious-disease-bulletin-year-2020.xlsx)
  - [R script](https://github.com/roscoelai/dasr2020capstone/blob/master/src/import_moh_weekly.R)
- [Historical Daily Records, Meteorological Service Singapore (MSS)](http://www.weather.gov.sg/climate-historical-daily/)
  - [Backup copy as of 28 July 2020 (2012-01 to 2020-06, 19 stations) ](https://raw.githubusercontent.com/roscoelai/dasr2020capstone/master/data/mss/mss_daily_2012_2020_19stations_20200728.csv)
  - [R script](https://github.com/roscoelai/dasr2020capstone/blob/master/src/import_mss_daily.R)
  - [List of stations, weather parameters and periods of records](http://www.weather.gov.sg/wp-content/uploads/2016/12/Station_Records.pdf)
- [Listing of Licensed Healthcare Institutions, Ministry of Health (MOH)](http://hcidirectory.sg/hcidirectory/)
  - [Backup copy as of 25 July 2020](https://raw.githubusercontent.com/roscoelai/dasr2020capstone/master/data/hcid/hci_clinics_20200725.csv)
  - [R script (part 1)](https://github.com/roscoelai/dasr2020capstone/blob/master/src/import_hcidirectory.R)
  - [R script (part 2)](https://github.com/roscoelai/dasr2020capstone/blob/master/src/zipcodes_to_geocodes.R)
- [Locations of dengue cases](https://data.gov.sg/search?q=denguecases), Data.gov.sg

| Date       | Central     | North East  | South East  | South West  |
| :--------: | :---------: | :---------: | :---------: | :---------: |
| 2020-06-26 | [.kml][c1]  | [.kml][c2]  | [.kml][c3]  | [.kml][c4]  |
| 2020-07-07 | [.kml][c5]  | [.kml][c6]  | [.kml][c7]  | [.kml][c8]  |
| 2020-07-09 | [.kml][c9]  | [.kml][c10] | [.kml][c11] | [.kml][c12] |
| 2020-07-15 | [.kml][c13] | [.kml][c14] | [.kml][c15] | [.kml][c16] |
| 2020-07-17 | [.kml][c17] | [.kml][c18] | [.kml][c19] | [.kml][c20] |
| 2020-07-28 | [.kml][c21] | [.kml][c22] | [.kml][c23] | [.kml][c24] |

[c1]: https://geo.data.gov.sg/denguecase-central-area/2020/06/26/kml/denguecase-central-area.kml
[c2]: https://geo.data.gov.sg/denguecase-northeast-area/2020/06/26/kml/denguecase-northeast-area.kml
[c3]: https://geo.data.gov.sg/denguecase-southeast-area/2020/06/26/kml/denguecase-southeast-area.kml
[c4]: https://geo.data.gov.sg/denguecase-southwest-area/2020/06/26/kml/denguecase-southwest-area.kml
[c5]: https://geo.data.gov.sg/denguecase-central-area/2020/07/07/kml/denguecase-central-area.kml
[c6]: https://geo.data.gov.sg/denguecase-northeast-area/2020/07/07/kml/denguecase-northeast-area.kml
[c7]: https://geo.data.gov.sg/denguecase-southeast-area/2020/07/07/kml/denguecase-southeast-area.kml
[c8]: https://geo.data.gov.sg/denguecase-southwest-area/2020/07/07/kml/denguecase-southwest-area.kml
[c9]: https://geo.data.gov.sg/denguecase-central-area/2020/07/09/kml/denguecase-central-area.kml
[c10]: https://geo.data.gov.sg/denguecase-northeast-area/2020/07/09/kml/denguecase-northeast-area.kml
[c11]: https://geo.data.gov.sg/denguecase-southeast-area/2020/07/09/kml/denguecase-southeast-area.kml
[c12]: https://geo.data.gov.sg/denguecase-southwest-area/2020/07/09/kml/denguecase-southwest-area.kml
[c13]: https://geo.data.gov.sg/denguecase-central-area/2020/07/15/kml/denguecase-central-area.kml
[c14]: https://geo.data.gov.sg/denguecase-northeast-area/2020/07/15/kml/denguecase-northeast-area.kml
[c15]: https://geo.data.gov.sg/denguecase-southeast-area/2020/07/15/kml/denguecase-southeast-area.kml
[c16]: https://geo.data.gov.sg/denguecase-southwest-area/2020/07/15/kml/denguecase-southwest-area.kml
[c17]: https://geo.data.gov.sg/denguecase-central-area/2020/07/17/kml/denguecase-central-area.kml
[c18]: https://geo.data.gov.sg/denguecase-northeast-area/2020/07/17/kml/denguecase-northeast-area.kml
[c19]: https://geo.data.gov.sg/denguecase-southeast-area/2020/07/17/kml/denguecase-southeast-area.kml
[c20]: https://geo.data.gov.sg/denguecase-southwest-area/2020/07/17/kml/denguecase-southwest-area.kml
[c21]: https://geo.data.gov.sg/denguecase-central-area/2020/07/28/kml/denguecase-central-area.kml
[c22]: https://geo.data.gov.sg/denguecase-northeast-area/2020/07/28/kml/denguecase-northeast-area.kml
[c23]: https://geo.data.gov.sg/denguecase-southeast-area/2020/07/28/kml/denguecase-southeast-area.kml
[c24]: https://geo.data.gov.sg/denguecase-southwest-area/2020/07/28/kml/denguecase-southwest-area.kml

- [Locations of _Aedes_ mosquito breeding habitats](https://data.gov.sg/search?q=aedes+habitats), Data.gov.sg

Date       | Central     | North East  | North West  | South East  | South West 
:--------: | :---------: | :---------: | :---------: | :---------: | :---------:
2020-07-14 | [.kml][h1]  | [.kml][h2]  | [.kml][h3]  | [.kml][h4]  | [.kml][h5] 
2020-07-17 | [.kml][h6]  | [.kml][h7]  | [.kml][h8]  | [.kml][h9]  | [.kml][h10]
2020-07-23 |             |             |             | [.kml][h14] | [.kml][h15]
2020-07-28 | [.kml][h16] | [.kml][h17] | [.kml][h18] | [.kml][h19] | [.kml][h20]

[h1]: https://geo.data.gov.sg/breedinghabitat-central-area/2020/07/14/kml/breedinghabitat-central-area.kml
[h2]: https://geo.data.gov.sg/breedinghabitat-northeast-area/2020/07/14/kml/breedinghabitat-northeast-area.kml
[h3]: https://geo.data.gov.sg/breedinghabitat-northwest-area/2020/07/14/kml/breedinghabitat-northwest-area.kml
[h4]: https://geo.data.gov.sg/breedinghabitat-southeast-area/2020/07/14/kml/breedinghabitat-southeast-area.kml
[h5]: https://geo.data.gov.sg/breedinghabitat-southwest-area/2020/07/14/kml/breedinghabitat-southwest-area.kml
[h6]: https://geo.data.gov.sg/breedinghabitat-central-area/2020/07/17/kml/breedinghabitat-central-area.kml
[h7]: https://geo.data.gov.sg/breedinghabitat-northeast-area/2020/07/17/kml/breedinghabitat-northeast-area.kml
[h8]: https://geo.data.gov.sg/breedinghabitat-northwest-area/2020/07/17/kml/breedinghabitat-northwest-area.kml
[h9]: https://geo.data.gov.sg/breedinghabitat-southeast-area/2020/07/17/kml/breedinghabitat-southeast-area.kml
[h10]: https://geo.data.gov.sg/breedinghabitat-southwest-area/2020/07/17/kml/breedinghabitat-southwest-area.kml
[h14]: https://geo.data.gov.sg/breedinghabitat-southeast-area/2020/07/23/kml/breedinghabitat-southeast-area.kml
[h15]: https://geo.data.gov.sg/breedinghabitat-southwest-area/2020/07/23/kml/breedinghabitat-southwest-area.kml
[h16]: https://geo.data.gov.sg/breedinghabitat-central-area/2020/07/28/kml/breedinghabitat-central-area.kml
[h17]: https://geo.data.gov.sg/breedinghabitat-northeast-area/2020/07/28/kml/breedinghabitat-northeast-area.kml
[h18]: https://geo.data.gov.sg/breedinghabitat-northwest-area/2020/07/28/kml/breedinghabitat-northwest-area.kml
[h19]: https://geo.data.gov.sg/breedinghabitat-southeast-area/2020/07/28/kml/breedinghabitat-southeast-area.kml
[h20]: https://geo.data.gov.sg/breedinghabitat-southwest-area/2020/07/28/kml/breedinghabitat-southwest-area.kml

- [Singapore Residents by Planning Area and Type of Dwelling, Jun 2017](https://data.gov.sg/dataset/singapore-residents-by-planning-area-and-type-of-dwelling-jun-2017), Data.gov.sg
  - Planning areas (URA MP14)
  - Populations of planning areas
  - Breakdown by type of dwelling
  - [.kml file](https://geo.data.gov.sg/plan-bdy-dwelling-type-2017/2017/09/27/kml/plan-bdy-dwelling-type-2017.kml)
- [Master Plan 2014 Region Boundary (Web)](https://data.gov.sg/dataset/master-plan-2014-region-boundary-web), Data.gov.sg
  - Regions (URA MP14)
  - [.zip file](https://geo.data.gov.sg/mp14-region-web-pl/2014/12/05/kml/mp14-region-web-pl.zip)

---

![](./imgs/ncases_4diseases_sep_2012_2020.png)

---

# Capstone Project Proposal

![](./imgs/ncases_2012_2020.png)

## Overview
Dengue fever is a vector-borne infectious disease that is endemic in the tropical world. Singapore is one of several countries with high disease burden of dengue. In 2020, Singapore saw 1,158 dengue cases in a week of June - the highest number of weekly dengue cases ever recorded since 2014. Why is there a sudden spike in dengue cases this year?

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
