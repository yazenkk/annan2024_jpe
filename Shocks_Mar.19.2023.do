/*
JPE2023-Annan
y = shocks mitigation: financial resilience*
Phone Surveys + Intensive Tracking: April 2020+

Input:
	- FFPhone in 2020/CustomersData.dta
	- data-Mgt/Stats?/Mkt_census_xtics_+_interventions_localized.dta
Output:
	- NA
*/

***************
use "$dta_loc_repl/02_final/Customer_+_Mktcensus_+_Interventions.dta", clear

gen districtID = ge01

**unmitigated shocks?
gen udeath=(c21a==1) if _merge==3
gen urevenue=(c21b==1) if _merge==3
gen usickness=(c21c==1) if _merge==3
gen uweather=(c21d==1) if _merge==3
gen uprices=(c21e==1) if _merge==3
gen ushocks=(c21f==1) if _merge==3

gen udeath_t0=(c6q1a==1) 
gen urevenue_t0=(c6q1b==1)
gen usickness_t0=(c6q1c==1)
gen uweather_t0=(c6q1d==1) 
gen uprices_t0=(c6q1e==1)
gen ushocks_t0=(c6q1f==1)

gen ushocks_exp_t1 = (udeath==1 | urevenue==1 | usickness==1 | uweather==1 | uprices==1 | ushocks==1)  if _merge==3
gen ushocks_exp_t0 = (udeath_t0==1 | urevenue_t0==1 | usickness_t0==1 | uweather_t0==1 | uprices_t0==1 | ushocks_t0==1) if _merge==3

gen health_t1=(usickness==1 | ushocks==1) if _merge==3
gen revenue_t1=(urevenue==1 | ushocks==1) if _merge==3
gen hhexpense_t1= (ushocks==1) if _merge==3


**midterm: poverty effects?
**poverty rate, by locality etc? 100% Nat. Pov
gen c_pov_likelihood_t0=c_pov_likelihood if _merge==3
egen c_rScore_t1 = rowtotal(c11 - c20) if _merge==3
gen c_pov_likelihood_t1 = 91.4 if (c_rScore_t1>=0 & c_rScore_t1<=9)
replace c_pov_likelihood_t1 =75.9 if (c_rScore_t1>=10 & c_rScore_t1<=14)
replace c_pov_likelihood_t1 =66.8 if (c_rScore_t1>=15 & c_rScore_t1<=19)
replace c_pov_likelihood_t1 =63.8 if (c_rScore_t1>=20 & c_rScore_t1<=24)
replace c_pov_likelihood_t1 =53.3 if (c_rScore_t1>=25 & c_rScore_t1<=29)
replace c_pov_likelihood_t1 =40.2 if (c_rScore_t1>=30 & c_rScore_t1<=34)
replace c_pov_likelihood_t1 =29.0 if (c_rScore_t1>=35 & c_rScore_t1<=39)
replace c_pov_likelihood_t1 =19.6 if (c_rScore_t1>=40 & c_rScore_t1<=44)
replace c_pov_likelihood_t1 =11.7 if (c_rScore_t1>=45 & c_rScore_t1<=49)
replace c_pov_likelihood_t1 =7.2 if (c_rScore_t1>=50 & c_rScore_t1<=54)
replace c_pov_likelihood_t1 =4.3 if (c_rScore_t1>=55 & c_rScore_t1<=59)
replace c_pov_likelihood_t1 =2.2 if (c_rScore_t1>=60 & c_rScore_t1<=64)
replace c_pov_likelihood_t1 =1.1 if (c_rScore_t1>=65 & c_rScore_t1<=69)
replace c_pov_likelihood_t1 =0.8 if (c_rScore_t1>=70 & c_rScore_t1<=74)
replace c_pov_likelihood_t1 =0.3 if (c_rScore_t1>=75 & c_rScore_t1<=79)
replace c_pov_likelihood_t1 =0.0 if (c_rScore_t1>=80 & c_rScore_t1<=100)
sum c_pov_likelihood_t0 c_pov_likelihood_t1


** Table 9+10 ---------------------------------------------------------------------
sum ushocks_exp_t1 revenue_t1 health_t1 hhexpense_t1 c_pov_likelihood_t1 if trtment==0
regress ushocks_exp_t1 ushocks_exp_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment if _merge==3, cluster(ge02) level(95)
regress revenue_t1 urevenue_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment if _merge==3, cluster(ge02) level(95)
regress health_t1 usickness_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment if _merge==3, cluster(ge02) level(95)
regress hhexpense_t1 ushocks_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment if _merge==3, cluster(ge02) level(95)
regress c_pov_likelihood_t1 c_pov_likelihood_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment if _merge==3, cluster(ge02) level(95)


tab trt, gen(trt)
regress ushocks_exp_t1 ushocks_exp_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4 if _merge==3, cluster(ge02) level(95)
test _b[trt2]=_b[trt4]
test _b[trt3]=_b[trt4]
test _b[trt2]=_b[trt3]
test _b[trt2] + _b[trt3] =_b[trt4]
regress revenue_t1 urevenue_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4 if _merge==3, cluster(ge02) level(95)
test _b[trt2]=_b[trt4]
test _b[trt3]=_b[trt4]
test _b[trt2]=_b[trt3]
test _b[trt2] + _b[trt3] =_b[trt4]
regress health_t1 usickness_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4 if _merge==3, cluster(ge02) level(95)
test _b[trt2]=_b[trt4]
test _b[trt3]=_b[trt4]
test _b[trt2]=_b[trt3]
test _b[trt2] + _b[trt3] =_b[trt4]
regress hhexpense_t1 ushocks_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4 if _merge==3, cluster(ge02) level(95)
test _b[trt2]=_b[trt4]
test _b[trt3]=_b[trt4]
test _b[trt2]=_b[trt3]
test _b[trt2] + _b[trt3] =_b[trt4]
regress c_pov_likelihood_t1 c_pov_likelihood_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4 if _merge==3, cluster(ge02) level(95)
test _b[trt2]=_b[trt4]
test _b[trt3]=_b[trt4]
test _b[trt2]=_b[trt3]
test _b[trt2] + _b[trt3] =_b[trt4]


** Table C10 ---------------------------------------------------------------------
*Robustness checks - Inference, Multiple Testing, Attrition, LASSO Estimation
*POOLED
***wild cluster bootstrap, pval
reg ushocks_exp_t1 ushocks_exp_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment if _merge==3, cluster(loccode) level(95)
boottest trt, rep($bootstrap_reps) level(95) nogr seed(15465)
**randomization inf: permuntation test, pval
ritest trtment _b[trtment], reps($bootstrap_reps) cluster(loccode) strata(districtID) seed(546): reg ushocks_exp_t1 ushocks_exp_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment
**mht: implement Romano-Wolf (2005) procedure, pval
rwolf ushocks_exp_t1 revenue_t1 health_t1 hhexpense_t1 c_pov_likelihood_t1, indepvar(trtment trt2 trt3 trt4) reps($bootstrap_reps) seed(124) controls(i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (all 4 0-1 shocks, poverty %)
**attrition bounds
**1. [Lee Bounds]**
leebounds ushocks_exp_t1 trtment, level(95) cieffect tight()
**2. [Behajel et al. Bounds]**
gen attempts= c0a
bys trtment: tab attempts
**with 3 or less phone /contact attempts: ctr has 92% response rate, trt has 95% response rate
**use number of attempts - "effort" to rank & bound te
**so trim (95-92)/95 =3% of trt group, x 667= 20 customers out
**Simply trim as follows:
foreach x of varlist ushocks_exp_t1 {
	preserve
		display "`x'"
		gen itemA= `x' if trtment==1 & attempts<=3 
		egen iranklo_Aa =rank(itemA) if trtment==1, unique //from above
		egen iranklo_Ab =rank(-itemA) if trtment==1, unique //from below
		gen yupperA= `x'
		replace yupperA=. if (trtment==1 & iranklo_Aa<=20) | (trtment==1 & attempts>3) //trim differences within 3 attempts and cut off all above 3-attempts
		gen ylowerA= `x'
		replace ylowerA=. if (trtment==1 & iranklo_Ab<=20) | (trtment==1 & attempts>3)
		reg ylowerA  trtment, r
		reg yupperA trtment, r
	restore
} 
*

*SEPARATE
***wild cluster bootstrap, pval
reg ushocks_exp_t1 ushocks_exp_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4 if _merge==3, cluster(loccode) level(95)
boottest trt2, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt3, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt4, rep($bootstrap_reps) level(95) nogr seed(15465)
**randomization inf: permuntation test, pval
ritest trt2 trt3 trt4 _b[trt2] _b[trt3] _b[trt4], reps($bootstrap_reps) cluster(loccode) strata(districtID) seed(546): reg ushocks_exp_t1 ushocks_exp_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4
**mht: implement Romano-Wolf (2005) procedure, pval
rwolf ushocks_exp_t1 revenue_t1 health_t1 hhexpense_t1 c_pov_likelihood_t1, indepvar(trt2 trt3 trt4) reps($bootstrap_reps) seed(124) controls(i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (all 4 0-1 shocks, poverty %)
**attrition bounds
**1. [Lee Bounds]**
foreach x of varlist trt2 trt3 trt4 {
	leebounds ushocks_exp_t1 `x', level(95) cieffect tight() 
}
*
/* dropped to save table space
**2. [Behajel et al. Bounds]**
foreach x of varlist ushocks_exp_t1 {
	preserve
		display "`x'"
		gen itemA= `x' if trt2==1 & attempts<=3 
		egen iranklo_Aa =rank(itemA) if trt2==1, unique //from above
		egen iranklo_Ab =rank(-itemA) if trt2==1, unique //from below
		gen yupperA= `x'
		replace yupperA=. if (trt2==1 & iranklo_Aa<=20) | (trt2==1 & attempts>3) //trim differences within 3 attempts and cut off all above 3-attempts
		gen ylowerA= `x'
		replace ylowerA=. if (trt2==1 & iranklo_Ab<=20) | (trt2==1 & attempts>3)
		reg ylowerA  trt2, r
		reg yupperA trt2, r
	restore
}
*
foreach x of varlist ushocks_exp_t1 {
	preserve
		display "`x'"
		gen itemA= `x' if trt3==1 & attempts<=3 
		egen iranklo_Aa =rank(itemA) if trt3==1, unique //from above
		egen iranklo_Ab =rank(-itemA) if trt3==1, unique //from below
		gen yupperA= `x'
		replace yupperA=. if (trt3==1 & iranklo_Aa<=20) | (trt3==1 & attempts>3) //trim differences within 3 attempts and cut off all above 3-attempts
		gen ylowerA= `x'
		replace ylowerA=. if (trt3==1 & iranklo_Ab<=20) | (trt3==1 & attempts>3)
		reg ylowerA  trt3, r
		reg yupperA trt3, r
	restore
}
*

foreach x of varlist ushocks_exp_t1 {
	preserve
		display "`x'"
		gen itemA= `x' if trt4==1 & attempts<=3 
		egen iranklo_Aa =rank(itemA) if trt4==1, unique //from above
		egen iranklo_Ab =rank(-itemA) if trt4==1, unique //from below
		gen yupperA= `x'
		replace yupperA=. if (trt4==1 & iranklo_Aa<=20) | (trt4==1 & attempts>3) //trim differences within 3 attempts and cut off all above 3-attempts
		gen ylowerA= `x'
		replace ylowerA=. if (trt4==1 & iranklo_Ab<=20) | (trt4==1 & attempts>3)
		reg ylowerA  trt4, r
		reg yupperA trt4, r
	restore
}
*/
*















