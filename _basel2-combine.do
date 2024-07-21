/*
Combine baseline and raw datasets

Source: Commands_Test_f_evaluation_consumers.do
		The output dataset is also generated in Commands_Test_f_evaluation
		but that is outdated.
Input: 
	- Customer
	- Mkt_census_xtics_+_interventions_localized
Output:
	- Customer_+_Mktcensus_+_Interventions
	
[Confirm where variable y comes from]
[Remove unneeded comments/lines]

*/

** -----------------------------------------------------------------------------
**I--Mkt Census xtics + Interventions (localized)?
use "$dta_loc_repl/01_intermediate/Mkt_fieldData_census", clear
drop _merge
merge m:1 ge03 ge04 using "$dta_loc_repl/01_intermediate/interventionsTomake_list_local" //customers match subsumes vednors//
keep if _merge==3
drop _merge
tempfile Mkt_census_xtics_int_lclzd
save 	`Mkt_census_xtics_int_lclzd'



** -----------------------------------------------------------------------------
*Customer analysis?
**************
***************
use "$dta_loc_repl/00_raw_anon/Customer_corrected.dta", clear
merge 1:1 ge04 using `Mkt_census_xtics_int_lclzd'

** generate loccode for convenience
gen loccode = ge02

*keep if _merge ==3
*drop if _n>950

**attrition stats: numbers
tab intervention
gen dropouts = (_merge==2)
tab intervention if dropouts==0
*get mean=% and SD=%?
gen ins=(dropouts==0)
tabstat ins, stat(mean sd n) by(intervention)
tabstat dropouts, stat(mean sd n) by(intervention)



*drop if missing(c1a2)


tab intervention
gen trtment = (intervention != "Control")

gen trtment_mm =.
replace trtment_mm=1 if (intervention == "MKtMonitoring, MM")
replace trtment_mm=0 if (intervention == "Control")

gen trtment_pt=.
replace trtment_pt=1 if (intervention == "PriceTransparency, PT")
replace trtment_pt=0 if (intervention == "Control")

gen trtment_mmpt=.
replace trtment_mmpt=1 if (intervention == "joint: PT+MM")
replace trtment_mmpt=0 if (intervention == "Control")

gen trt=0
replace trt=1 if intervention=="PriceTransparency, PT"
replace trt=2 if intervention=="MKtMonitoring, MM"
replace trt=3 if intervention=="joint: PT+MM"

sum trt*
egen xloc =group(loccode)
*tab xloc

gen trt_pool = (trt !=0)


*distplot c0a, saving("distplot_ccalls", replace) //customers answer quicker than vendors/business (as expected)
*hist c0a, percent xtitle("Customers: Number of phone call times before answering survey")
*gr export "/Users/fannan/Dropbox/research_projs/fraud-monitors/_rGroup-finfraud/FFPhone in 2020/_impact-evaluation/customer_calltimeS.eps", replace


**(1) differential attrition/ drop outs?
tab _merge
*ciplot dropouts, by(trtment) title("differential attrition?")
*ciplot dropouts, by(trt) title("differential attrition?")
bys trtment: sum dropouts 
dis 0.23-0.18 //control has 5pp higher attrition, responserate for treatment=0.82=82% 
tab dropouts if trtment==0
tab dropouts if trtment==1
**so trim 0.05/0.82 = 6.1% of treatment group
**764 responses, so triming 46 customers

*gen item= y if trtment==1
*gen iranklo_a =rank(item) if trtment==1, unique
*gen iranklo_b =rank(-item) if trtment==1, unique
*gen yupper= y
*replace yupper=. if trtment==1 & iranklo_a<=46
*gen ylower= y
*replace ylower=. if trtment==1 & iranklo_b<=46
*areg ylower trtment, a(districtID) robust
*areg yupper trtment, a(districtID) robust


bys trt: sum dropouts 


**(2) balanced?
*3a Demand: customer xtics, same mkt?
** xtics? married out...
reg cfemale dropouts, cluster(loccode)
reg cmarried dropouts, cluster(loccode)
reg cakan dropouts, cluster(loccode)
reg cage dropouts, cluster(loccode)
reg cEducAny dropouts, cluster(loccode)
reg cselfemployed dropouts, cluster(loccode)
reg cselfIncome dropouts, cluster(loccode)
reg cMMoneyregistered dropouts, cluster(loccode)

**migrate?
gen migrateDesire= (c7q1==1)
gen migratein1yr = (c7q3 <3)
gen migratepermanent = (c7q4 ==2)
factor migrateDesire migratein1yr migratepermanent
predict migrate_score_c
reg migrateDesire dropouts, cluster(loccode)
reg migratein1yr dropouts, cluster(loccode)
reg migratepermanent dropouts, cluster(loccode)
reg migrate_score_c dropouts, cluster(loccode)


**poverty?
reg c2q1 dropouts, cluster(loccode)
*reg c2q2 dropouts, cluster(loccode)
reg c2q3 dropouts, cluster(loccode)
reg c2q4 dropouts, cluster(loccode)
reg c2q5 dropouts, cluster(loccode)
*reg c2q6 dropouts, cluster(loccode)
*reg c2q7 dropouts, cluster(loccode)
*reg c2q8 dropouts, cluster(loccode)
reg c2q9 dropouts, cluster(loccode)
reg c2q10 dropouts, cluster(loccode)
reg c_pov_likelihood dropouts, cluster(loccode)

**fraud?
reg cfAttempts dropouts, cluster(loccode)
reg _Xcfraud dropouts, cluster(loccode)

*3b mkt, transactions?
gen distToBank= c3q3a 
gen walkTimeBank= c3q3b 
gen bankUser = (c3q4==1)
replace bankUser=. if missing(c3q4)

gen distTopostOffice = c3q7a
gen walkTimepostOffice = c3q7b
gen postOffUser=(c3q8==1)
replace postOffUser=. if missing(c3q8)

gen distToMMoney= c4q2a
gen walkTimeMMoney= c4q2b
gen MMoneyUser=(c4q3==1)
replace MMoneyUser=. if missing(c4q3)

reg distToBank dropouts, cluster(loccode)
reg distToMMoney dropouts, cluster(loccode)

*reg wklyNobUsage dropouts, cluster(loccode)
reg wklyTotUseVol dropouts, cluster(loccode)
reg wklyNobUsage_nonM dropouts, cluster(loccode)
reg wklyTotUseVol_nonM dropouts, cluster(loccode)
**get distribution effects-main? which bound is more likely?
*sqreg wklyTotUseVol dropouts, q(.25 .5 .75)


*3c borrow + save behavior?
gen likelyborrowMMoney =c5q1
gen likelysaveMMoney =c5q5
reg likelyborrowMMoney dropouts, cluster(loccode)
reg likelysaveMMoney dropouts, cluster(loccode)
**get distribution effects-main? which bound is more likely?
*sqreg likelysaveMMoney dropouts, q(.25 .5 .75)

/* 
reg wklyNobBorrow dropouts, cluster(loccode)
reg wklyTotBorrowVol dropouts, cluster(loccode)
reg wklyNobSave dropouts, cluster(loccode)
reg wklyTotSaveVol dropouts, cluster(loccode)
*/
**joint, exclude main Y?
reg dropouts cfemale cmarried cakan cage cEducAny cselfemployed cselfIncome cMMoneyregistered, cluster(loccode)
test cfemale cmarried cakan cage cEducAny cselfemployed cselfIncome cMMoneyregistered
probit dropouts cfemale cakan cmarried cage cEducAny cselfemployed cselfIncome cMMoneyregistered, cluster(loccode)
test cfemale cmarried cakan cage cEducAny cselfemployed cselfIncome cMMoneyregistered



**Measurements...
gen mmUser_t1 = (c1a1 > 0) if _merge==3
gen mmUser_t0=(c4q3==1)
replace mmUser_t0=. if missing(c4q3)


gen mmtotnob_t1 = c1a1
gen mmtotnob_t0 = c4q11a


gen log_mmtotamt_t1 = log(c1a2+1) if !missing(c1a2)
gen log_mmtotamt_t0=log(c4q11b+1) if !missing(c4q11b)


gen mmtotamt_t1 = c1a2
gen mmtotamt_t0 = c4q11b
*hist mmtotamt_t1, discrete


gen nonmmUser_t1 = (c1b1 > 0) if _merge==3
gen nonmmUser_t0=(c4q18a > 0)
replace nonmmUser_t0=. if missing(c4q18a)


gen nonmmtotnob_t1 = c1b1
gen nonmmtotnob_t0 = c4q18a


gen log_nonmmtotamt_t1 = log(c1b2+1) if !missing(c1b2)
gen log_nonmmtotamt_t0 = log(c4q18b+1) if !missing(c4q18b)


gen nonmmtotamt_t1 = c1b2
gen nonmmtotamt_t0 = c4q18b


gen save_t1 =(c3>2) if _merge==3
gen save_t0 =(c4q5==1)
replace save_t0=. if missing(c4q5)


gen indebt_t1 =(c2>2) if _merge==3
gen indebt_t0 =(c5q1>2)
replace indebt_t0=. if missing(c5q1)

*tab districtID, gen(districtID)
egen locfes = group(loccode)
*tab locfes, gen(locfes)

save "$dta_loc_repl/02_final/Customer_+_Mktcensus_+_Interventions.dta", replace  //good? yes



** -----------------------------------------------------------------------------
** Merchants
**************
***************
use "$dta_loc_repl/00_raw_anon/Merchant_corrected.dta", clear

gen duration_min = end_time-start_time

merge m:m ge01 ge02 using `Mkt_census_xtics_int_lclzd'
*keep if _merge ==3
bys ge01 ge02: keep if _n==1  //only vendors + dropouts

**attrition stats: numbers
tab intervention
gen dropouts = (_merge==2)
tab intervention if dropouts==0
*get mean=% and SD=%?
gen ins=(dropouts==0)
tabstat ins, stat(mean sd n) by(intervention)
tabstat dropouts, stat(mean sd n) by(intervention)

**define treatment indicators
tab intervention
gen trtment = (intervention != "Control")

gen trtment_mm =.
replace trtment_mm=1 if (intervention == "MKtMonitoring, MM")
replace trtment_mm=0 if (intervention == "Control")

gen trtment_pt=.
replace trtment_pt=1 if (intervention == "PriceTransparency, PT")
replace trtment_pt=0 if (intervention == "Control")

gen trtment_mmpt=.
replace trtment_mmpt=1 if (intervention == "joint: PT+MM")
replace trtment_mmpt=0 if (intervention == "Control")

gen trt=0
replace trt=1 if intervention=="PriceTransparency, PT"
replace trt=2 if intervention=="MKtMonitoring, MM"
replace trt=3 if intervention=="joint: PT+MM"

*Attrition - Test for Significance by Treatment Program
gen trt_pool = (trt !=0)
sum dropouts if trt_pool==0
reg dropouts trt_pool, r
reg dropouts i.trt, r


tab date_of_interview
tab date_of_interview, missing


*get measurements?
***momo sales? I
gen mmtotamt_cust_t1 = v1a2
gen mmtotamt_cust_t0 = m2q4b
gen log_mmtotamt_cust_t1 = ln(v1a2)
gen log_mmtotamt_cust_t0=ln(m2q4b)

***non-momo sales? II
gen nonmmtotamt_cust_t1 = v1b2
gen nonmmtotamt_cust_t0 = dailyTotMoney_nonM
gen log_nonmmtotamt_cust_t1 = ln(v1b2)
gen log_nonmmtotamt_cust_t0=ln(dailyTotMoney_nonM)


**Total sales-combined momo+nonmomo? III
gen totamt_cust_t1 = mmtotamt_cust_t1+nonmmtotamt_cust_t1
gen totamt_cust_t0 = mmtotamt_cust_t0+nonmmtotamt_cust_t0
gen log_totamt_cust_t1 = ln(totamt_cust_t1)
gen log_totamt_cust_t0 = ln(totamt_cust_t0)

**exits? IV
gen bus_exit = dropouts

gen migrateDesire= (m5q1==1)
gen migratein1yr = (m5q3 <3)
gen migratepermanent = (m5q4 ==2)


save "$dta_loc_repl/02_final/Merchants_+_Mktcensus_+_Interventions.dta", replace  //good? yes
