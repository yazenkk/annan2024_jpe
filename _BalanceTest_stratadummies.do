/*
Title: Balance tests?

Input:
	- Mkt_fieldData_sample_repMkt,dta
	- interventionsTomake_list_local
Output:
	- Regressions, no table (esttab etc) yet
	
*/

***ADD STRATA DUMMIES R3 (JPE)***

** Table B.3 -------------------------------------------------------------------
**Balance Tests II (program assignments): JULY 4 2020 = APR 3 2023
use "$dta_loc_repl/01_intermediate/Mkt_fieldData_sample_repMkt", clear
merge m:m ge02 ge03 using "$dta_loc_repl/01_intermediate/interventionsTomake_list_local"

keep if _merge==3

*use interventionsTomake_list_local, clear
gen trt0vsall = (treatment !=0)
*br districtName regionDistrictCode_j localityName localityCode_j treatment Trt* trt*

***ADD STRATA DUMMIES R3 (JPE)***
egen strataFE = group(ge01)

**Supply side: merchants...?
reg mfemale i.strataFE i.treatment, cluster(ge02)
reg mmarried i.strataFE i.treatment, cluster(ge02)
reg makan i.strataFE i.treatment, cluster(ge02)
reg mage i.strataFE i.treatment, cluster(ge02)
reg mEducAny i.strataFE i.treatment, cluster(ge02)
reg mselfemployed i.strataFE i.treatment, cluster(ge02)
*reg mselfIncome i.treatment, cluster(ge02) //fine but too many already
reg mbusTrained i.strataFE i.treatment, cluster(ge02)

**poverty?
reg m4q3 i.strataFE i.treatment, cluster(ge02)
reg m4q4 i.strataFE i.treatment, cluster(ge02)
reg m4q5 i.strataFE i.treatment, cluster(ge02)
reg m4q9 strataFE i.treatment, cluster(ge02)
reg m4q10 i.strataFE i.treatment, cluster(ge02)
reg m_pov_likelihood i.strataFE i.treatment, cluster(ge02) //just report this index?


*reg dailyNobCustomers i.treatment, cluster(ge02) //fine but too many already
*reg CustPer_w_Mkt strataFE i.treatment, cluster(ge02) //fine but too many already
reg dailyTotMoney i.strataFE i.treatment, cluster(ge02)
reg dailyNobCustomers_nonM i.strataFE i.treatment, cluster(ge02)
reg dailyTotMoney_nonM i.strataFE i.treatment, cluster(ge02)

**joint, exclude main Y
reg trt0vsall mfemale mmarried makan mage mEducAny mselfemployed mselfIncome mbusTrained, cluster(ge02)
test mfemale mmarried makan mage mEducAny mselfemployed mselfIncome mbusTrained

probit trt0vsall mfemale mmarried makan mage mEducAny mselfemployed mselfIncome mbusTrained, cluster(ge02)
test mfemale mmarried makan mage mEducAny mselfemployed mselfIncome mbusTrained



** Table B.4 -------------------------------------------------------------------
**Demand side: customers...?
reg cfemale i.strataFE i.treatment, cluster(ge02)
reg cmarried i.strataFE i.treatment, cluster(ge02)
reg cakan i.strataFE i.treatment, cluster(ge02)
reg cage i.strataFE i.treatment, cluster(ge02)
reg cEducAny i.strataFE i.treatment, cluster(ge02)
reg cselfemployed i.strataFE i.treatment, cluster(ge02)
*reg cselfIncome i.strataFE i.treatment, cluster(ge02) //fine but too manay already
reg cMMoneyregistered i.strataFE i.treatment, cluster(ge02)

**poverty?
reg c2q3 i.strataFE i.treatment, cluster(ge02)
reg c2q4 i.strataFE i.treatment, cluster(ge02)
reg c2q5 i.strataFE i.treatment, cluster(ge02)
reg c2q9 i.strataFE i.treatment, cluster(ge02)
reg c2q10 i.strataFE i.treatment, cluster(ge02)
reg c_pov_likelihood i.strataFE i.treatment, cluster(ge02) //just report this index?
**achieved strong balance on Trt vs Ctr...


reg cfAttempts i.strataFE i.treatment, cluster(ge02)
reg _Xcfraud i.strataFE i.treatment, cluster(ge02)


reg distToBank i.strataFE i.treatment, cluster(ge02)
reg distToMMoney i.strataFE i.treatment, cluster(ge02)


reg wklyTotUseVol i.strataFE i.treatment, cluster(ge02)
reg wklyNobUsage_nonM i.strataFE i.treatment, cluster(ge02)
reg wklyTotUseVol_nonM i.strataFE i.treatment, cluster(ge02)

reg likelyborrowMMoney i.strataFE i.treatment, cluster(ge02)
reg likelysaveMMoney i.strataFE i.treatment, cluster(ge02)


**joint, exclude main Y?
reg trt0vsall cfemale cmarried cakan cage cEducAny cselfemployed cselfIncome cMMoneyregistered, cluster(ge02)
test cfemale cmarried cakan cage cEducAny cselfemployed cselfIncome cMMoneyregistered
probit trt0vsall cfemale cakan cmarried cage cEducAny cselfemployed cselfIncome cMMoneyregistered, cluster(ge02)
test cfemale cmarried cakan cage cEducAny cselfemployed cselfIncome cMMoneyregistered






