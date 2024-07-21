/*
JPE2023-Annan
y = revenues: momo + non-momo*
Phone Surveys + Intensive Tracking: April 2020+

Input:
	- FFPhone in 2020/MerchantsData.dta
	- data-Mgt/Stats?/Mkt_census_xtics_+_interventions_localized.dta
Output:
	-[regressions]
*/

use "$dta_loc_repl/02_final/Merchants_+_Mktcensus_+_Interventions.dta", clear


** Figure B.5 ------------------------------------------------------------------
distplot v0a //customers answer quicker than vendors/business (as expected)
hist v0a, gap(10) percent xtitle("Vendors: Number of phone call times before answering survey")
gr export "$output_loc/main_results/vendor_calltimeS.eps", replace

gen districtID = ge01

**control means?
sum mmtotamt_cust_t1 bus_exit nonmmtotamt_cust_t1 totamt_cust_t1 if trtment==0

** Table 6 ---------------------------------------------------------------------
regress mmtotamt_cust_t1 mmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment, r
regress bus_exit i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment, r

tab trt, gen(trt)
regress mmtotamt_cust_t1 mmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4, r
test _b[trt2]=_b[trt4]
test _b[trt3]=_b[trt4]
test _b[trt2]=_b[trt3]
test _b[trt2] + _b[trt3] =_b[trt4]
regress bus_exit i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4, r
test _b[trt2]=_b[trt4]
test _b[trt3]=_b[trt4]
test _b[trt2]=_b[trt3]
test _b[trt2] + _b[trt3] =_b[trt4]





** Table 8 ---------------------------------------------------------------------
*SPILLOVERS - non momo sales -- MAIN TEXT
*bundling w non momo?
tab m3q1 //75-79% of sample bundled stores
tab m3q1 if dropouts==0 
*we code non momo sales to 0 for momo only stores, to prevent n changing across specs*
replace nonmmtotamt_cust_t1=0 if m3q1==2 & dropouts==0
replace nonmmtotamt_cust_t0=0 if m3q1==2 & dropouts==0
replace totamt_cust_t1=0 if m3q1==2 & dropouts==0
replace totamt_cust_t0=0 if m3q1==2 & dropouts==0

regress nonmmtotamt_cust_t1 nonmmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment, r
regress totamt_cust_t1 totamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment, r


regress nonmmtotamt_cust_t1 nonmmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4, r
test _b[trt2]=_b[trt4]
test _b[trt3]=_b[trt4]
test _b[trt2]=_b[trt3]
test _b[trt2] + _b[trt3] =_b[trt4]

regress totamt_cust_t1 totamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4, r
test _b[trt2]=_b[trt4]
test _b[trt3]=_b[trt4]
test _b[trt2]=_b[trt3]
test _b[trt2] + _b[trt3] =_b[trt4]





** Table C7 ---------------------------------------------------------------------
*ROBUSTNESS checks - Inference, Multiple Testing, Attrition, LASSO Estimation
*POOLED
***wild cluster bootstrap, pval
reg mmtotamt_cust_t1 mmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment, r level(95)
boottest trt, rep($bootstrap_reps) level(95) nogr seed(15465)
reg bus_exit i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment, r level(95)
boottest trt, rep($bootstrap_reps) level(95) nogr seed(1546)
**randomization inf: permuntation test, pval
ritest trtment _b[trtment], reps($bootstrap_reps) strata(districtID) seed(546): reg mmtotamt_cust_t1 mmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment
ritest trtment _b[trtment], reps($bootstrap_reps) strata(districtID) seed(546): reg bus_exit i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment
**mht: implement Romano-Wolf (2005) procedure, pval
rwolf mmtotamt_cust_t1 bus_exit nonmmtotamt_cust_t1 totamt_cust_t1, indepvar(trtment trt2 trt3 trt4) reps($bootstrap_reps) seed(124) controls(i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (all 3 sales measures: momo; non-momo; total + bus exit)
**attrition bounds
**1. [Lee Bounds]**
leebounds mmtotamt_cust_t1 trtment, level(95) cieffect tight() 
// leebounds bus_exit trtment, level(95) cieffect tight() 
**2. [Behajel et al. Bounds]**
gen attempts= v0a
bys trtment: tab attempts
**with 4 or less phone /contact attempts: ctr has 96% response rate, trt has 94% response rate
**use number of attempts - "effort" to rank & bound te
**so trim (94-96)/94 =2% of trt group, x 82= 2 vendors out
**Simply trim as follows:
*(drop bus_exit, makes no sense b/cx 129/130)
foreach x of varlist mmtotamt_cust_t1  {
	preserve
		display "`x'"
		gen itemA= `x' if trtment==1 & attempts<=4 
		egen iranklo_Aa =rank(itemA) if trtment==1, unique //from above
		egen iranklo_Ab =rank(-itemA) if trtment==1, unique //from below
		gen yupperA= `x'
		replace yupperA=. if (trtment==1 & iranklo_Aa<=2) | (trtment==1 & attempts>4) //trim differences within 3 attempts and cut off all above 3-attempts
		gen ylowerA= `x'
		replace ylowerA=. if (trtment==1 & iranklo_Ab<=2) | (trtment==1 & attempts>4)
		reg ylowerA  trtment, r
		reg yupperA trtment, r
	restore
} 
*

**SEPARATE
***wild cluster bootstrap, pval
reg mmtotamt_cust_t1 mmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4, r level(95)
boottest trt2, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt3, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt4, rep($bootstrap_reps) level(95) nogr seed(15465)
reg bus_exit i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4, r level(95)
boottest trt2, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt3, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt4, rep($bootstrap_reps) level(95) nogr seed(15465)
**randomization inf: permuntation test, pval
ritest  trt2 trt3 trt4 _b[trt2] _b[trt3] _b[trt4], reps($bootstrap_reps) strata(districtID) seed(546): reg mmtotamt_cust_t1 mmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4
ritest  trt2 trt3 trt4 _b[trt2] _b[trt3] _b[trt4], reps($bootstrap_reps) strata(districtID) seed(546): reg bus_exit i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4
**mht: implement Romano-Wolf (2005) procedure, pval
rwolf mmtotamt_cust_t1 bus_exit nonmmtotamt_cust_t1 totamt_cust_t1, indepvar(trt2 trt3 trt4) reps($bootstrap_reps) seed(124) controls(i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (all 3 sales measures: momo; non-momo; total + bus exit)
**attrition bounds
**1. [Lee Bounds]**
foreach x of varlist trt2 trt3 trt4 {
	leebounds mmtotamt_cust_t1 `x', level(95) cieffect tight() 
}
*
foreach x of varlist trt2 trt3 trt4 {
	cap leebounds bus_exit `x', level(95) cieffect tight() 
}
*
/* dropped to save table space
**2. [Behajel et al. Bounds]**
gen attempts= v0a
bys trtment: tab attempts
**with 4 or less phone /contact attempts: ctr has 96% response rate, trt has 94% response rate
**use number of attempts - "effort" to rank & bound te
**so trim (94-96)/94 =2% of trt group, x 82= 2 vendors out
**Simply trim as follows:
*(drop bus_exit, makes no sense b/cx 129/130)
foreach x of varlist mmtotamt_cust_t1  {
preserve
display "`x'"
gen itemA= `x' if trt2==1 & attempts<=4 
egen iranklo_Aa =rank(itemA) if trt2==1, unique //from above
egen iranklo_Ab =rank(-itemA) if trt2==1, unique //from below
gen yupperA= `x'
replace yupperA=. if (trt2==1 & iranklo_Aa<=2) | (trt2==1 & attempts>4) //trim differences within 3 attempts and cut off all above 3-attempts
gen ylowerA= `x'
replace ylowerA=. if (trt2==1 & iranklo_Ab<=2) | (trt2==1 & attempts>4)
reg ylowerA  trt2, r
reg yupperA trt2, r
restore
		} 
*
foreach x of varlist mmtotamt_cust_t1  {
preserve
display "`x'"
gen itemA= `x' if trt3==1 & attempts<=4 
egen iranklo_Aa =rank(itemA) if trt3==1, unique //from above
egen iranklo_Ab =rank(-itemA) if trt3==1, unique //from below
gen yupperA= `x'
replace yupperA=. if (trt3==1 & iranklo_Aa<=2) | (trt3==1 & attempts>4) //trim differences within 3 attempts and cut off all above 3-attempts
gen ylowerA= `x'
replace ylowerA=. if (trt3==1 & iranklo_Ab<=2) | (trt3==1 & attempts>4)
reg ylowerA  trt3, r
reg yupperA trt3, r
restore
		} 
*
foreach x of varlist mmtotamt_cust_t1  {
preserve
display "`x'"
gen itemA= `x' if trt4==1 & attempts<=4 
egen iranklo_Aa =rank(itemA) if trt4==1, unique //from above
egen iranklo_Ab =rank(-itemA) if trt4==1, unique //from below
gen yupperA= `x'
replace yupperA=. if (trt4==1 & iranklo_Aa<=2) | (trt4==1 & attempts>4) //trim differences within 3 attempts and cut off all above 3-attempts
gen ylowerA= `x'
replace ylowerA=. if (trt4==1 & iranklo_Ab<=2) | (trt4==1 & attempts>4)
reg ylowerA trt4, r
reg yupperA trt4, r
restore
		} 
*/
*



** Table C9 ---------------------------------------------------------------------
*Robustness checks [SPILLOVER EFFECTS = NON MOMO SALES] - Inference, Multiple Testing, Attrition, LASSO Estimation
*NON MOMO SALES*
*bundling w non momo?
tab m3q1 //75-79% of sample bundled stores
tab m3q1 if dropouts==0 
*we code non momo sales to 0 for momo only stores, to prevent n changing across specs*
replace nonmmtotamt_cust_t1=0 if m3q1==2 & dropouts==0
replace nonmmtotamt_cust_t0=0 if m3q1==2 & dropouts==0
replace totamt_cust_t1=0 if m3q1==2 & dropouts==0
replace totamt_cust_t0=0 if m3q1==2 & dropouts==0

sum nonmmtotamt_cust_t1 totamt_cust_t1 if trtment==0

*POOLED
***wild cluster bootstrap, pval
reg nonmmtotamt_cust_t1 nonmmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment, r level(95)
boottest trt, rep($bootstrap_reps) level(95) nogr seed(15465)
reg totamt_cust_t1 totamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment, r level(95)
boottest trt, rep($bootstrap_reps) level(95) nogr seed(1546)
**randomization inf: permuntation test, pval
ritest trtment _b[trtment], reps($bootstrap_reps) strata(districtID) seed(546): reg nonmmtotamt_cust_t1 nonmmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment
ritest trtment _b[trtment], reps($bootstrap_reps) strata(districtID) seed(546): reg totamt_cust_t1 totamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment
**mht: implement Romano-Wolf (2005) procedure, pval
rwolf nonmmtotamt_cust_t1 totamt_cust_t1, indepvar(trtment trt2 trt3 trt4) reps($bootstrap_reps) seed(124) controls(i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (all 3 sales measures: momo; non-momo; total + bus exit)
**attrition bounds
**1. [Lee Bounds]**
leebounds nonmmtotamt_cust_t1 trtment, level(95) cieffect tight() 
leebounds totamt_cust_t1 trtment, level(95) cieffect tight() 
**2. [Behajel et al. Bounds]**
// gen attempts= v0a
bys trtment: tab attempts
**with 4 or less phone /contact attempts: ctr has 96% response rate, trt has 94% response rate
**use number of attempts - "effort" to rank & bound te
**so trim (94-96)/94 =2% of trt group, x 82= 2 vendors out
**Simply trim as follows:
*(drop bus_exit, makes no sense b/cx 129/130)
foreach x of varlist nonmmtotamt_cust_t1 totamt_cust_t1  {
	preserve
		display "`x'"
		gen itemA= `x' if trtment==1 & attempts<=4 
		egen iranklo_Aa =rank(itemA) if trtment==1, unique //from above
		egen iranklo_Ab =rank(-itemA) if trtment==1, unique //from below
		gen yupperA= `x'
		replace yupperA=. if (trtment==1 & iranklo_Aa<=2) | (trtment==1 & attempts>4) //trim differences within 3 attempts and cut off all above 3-attempts
		gen ylowerA= `x'
		replace ylowerA=. if (trtment==1 & iranklo_Ab<=2) | (trtment==1 & attempts>4)
		reg ylowerA  trtment, r
		reg yupperA trtment, r
	restore
} 
*

**SEPARATE
***wild cluster bootstrap, pval
reg nonmmtotamt_cust_t1 nonmmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4, r level(95)
boottest trt2, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt3, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt4, rep($bootstrap_reps) level(95) nogr seed(15465)
reg totamt_cust_t1 totamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4, r level(95)
boottest trt2, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt3, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt4, rep($bootstrap_reps) level(95) nogr seed(15465)
**randomization inf: permuntation test, pval
ritest  trt2 trt3 trt4 _b[trt2] _b[trt3] _b[trt4], reps($bootstrap_reps) strata(districtID) seed(546): reg nonmmtotamt_cust_t1 nonmmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4
ritest  trt2 trt3 trt4 _b[trt2] _b[trt3] _b[trt4], reps($bootstrap_reps) strata(districtID) seed(546): reg totamt_cust_t1 totamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trt2 trt3 trt4
**mht: implement Romano-Wolf (2005) procedure, pval
rwolf mmtotamt_cust_t1 bus_exit nonmmtotamt_cust_t1 totamt_cust_t1, indepvar(trt2 trt3 trt4) reps($bootstrap_reps) seed(124) controls(i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (all 3 sales measures: momo; non-momo; total + bus exit)
**attrition bounds
**1. [Lee Bounds]**
foreach x of varlist trt2 trt3 trt4 {
	leebounds nonmmtotamt_cust_t1 `x', level(95) cieffect tight() 
}
*
foreach x of varlist trt2 trt3 trt4 {
	leebounds totamt_cust_t1 `x', level(95) cieffect tight() 
}
*
**2. [Behajel et al. Bounds]**
*gen attempts= v0a
*bys trtment: tab attempts
**with 4 or less phone /contact attempts: ctr has 96% response rate, trt has 94% response rate
**use number of attempts - "effort" to rank & bound te
**so trim (94-96)/94 =2% of trt group, x 82= 2 vendors out
**Simply trim as follows:
*(drop bus_exit, makes no sense b/cx 129/130)
foreach x of varlist nonmmtotamt_cust_t1 totamt_cust_t1  {
	preserve
		display "`x'"
		gen itemA= `x' if trt2==1 & attempts<=4 
		egen iranklo_Aa =rank(itemA) if trt2==1, unique //from above
		egen iranklo_Ab =rank(-itemA) if trt2==1, unique //from below
		gen yupperA= `x'
		replace yupperA=. if (trt2==1 & iranklo_Aa<=2) | (trt2==1 & trt2>4) //trim differences within 3 attempts and cut off all above 3-attempts
		gen ylowerA= `x'
		replace ylowerA=. if (trt2==1 & iranklo_Ab<=2) | (trt2==1 & trt2>4)
		reg ylowerA  trt2, r
		reg yupperA trt2, r
	restore
} 
*
foreach x of varlist nonmmtotamt_cust_t1 totamt_cust_t1  {
	preserve
		display "`x'"
		gen itemA= `x' if trt3==1 & attempts<=4 
		egen iranklo_Aa =rank(itemA) if trt3==1, unique //from above
		egen iranklo_Ab =rank(-itemA) if trt3==1, unique //from below
		gen yupperA= `x'
		replace yupperA=. if (trt3==1 & iranklo_Aa<=2) | (trt3==1 & trt3>4) //trim differences within 3 attempts and cut off all above 3-attempts
		gen ylowerA= `x'
		replace ylowerA=. if (trt3==1 & iranklo_Ab<=2) | (trt3==1 & trt3>4)
		reg ylowerA  trt3, r
		reg yupperA trt3, r
	restore
} 
*
foreach x of varlist nonmmtotamt_cust_t1 totamt_cust_t1  {
	preserve
		display "`x'"
		gen itemA= `x' if trt4==1 & attempts<=4 
		egen iranklo_Aa =rank(itemA) if trt4==1, unique //from above
		egen iranklo_Ab =rank(-itemA) if trt4==1, unique //from below
		gen yupperA= `x'
		replace yupperA=. if (trt4==1 & iranklo_Aa<=2) | (trt4==1 & trt4>4) //trim differences within 3 attempts and cut off all above 3-attempts
		gen ylowerA= `x'
		replace ylowerA=. if (trt4==1 & iranklo_Ab<=2) | (trt4==1 & trt4>4)
		reg ylowerA  trt4, r
		reg yupperA trt4, r
	restore
} 
*



** Table C16 ---------------------------------------------------------------------
**No Marketing Effects: # of customers
*extensive margin - no effect
sum v1a1 if trtment==0 & dropouts==0
regress v1a1 m2q4a i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment, robust //no effect
*regress v1a1 mmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 trtment, robust //no effect

regress v1a1 m2q4a i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 i.trt, robust //no effect
*regress v1a1 mmtotamt_cust_t0 i.districtID mage mmarried makan mselfemployed m2q1a i.m3q1 i.trt, robust //no effect




 
 
 
 
 
 
