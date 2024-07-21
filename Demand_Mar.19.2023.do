/*
JPE2023-Annan
y = demand: usage + savings*
Title: Phone Surveys + Intensive Tracking: April 2020+

Input:
	- FFPhone in 2020/CustomersData.dta
	- data-Mgt/Stats?/Mkt_census_xtics_+_interventions_localized.dta
	- data-Mgt/Stats?/ofdrate_mktadminTransactData.dta

Output:
	- FFPhone in 2020/_impact-evaluation/te_all_graph.eps
	- FFPhone in 2020/_impact-evaluation/te_pt_graph.eps
	- FFPhone in 2020/_impact-evaluation/te_m&r_graph.eps
	- FFPhone in 2020/_impact-evaluation/te_both_graph.eps

*/

use "$dta_loc_repl/02_final/Customer_+_Mktcensus_+_Interventions.dta", clear

gen districtID = ge01

*Attrition - Test for Significance by Treatment Program
sum dropouts if trt_pool==0
reg dropouts trt_pool, cluster(ge02)
reg dropouts i.trt, cluster(ge02)

*distplot c0a, saving("distplot_ccalls", replace) //customers answer quicker than vendors/business (as expected)
hist c0a, percent xtitle("Customers: Number of phone call times before answering survey")
gr export "$output_loc/main_results/customer_calltimeS.eps", replace

**differential attrition/ drop outs?
tab _merge
bys trtment: sum dropouts 
dis 0.23-0.18 //control has 5pp higher attrition, responserate for treatment=0.82=82% 
tab dropouts if trtment==0
tab dropouts if trtment==1
**so trim 0.05/0.82 = 6.1% of treatment group
**764 responses, so triming 46 customers

bys trt: sum dropouts 


*********
*Results*
*************
**Effects--graphical: (endline) effects driven by few tails? no
*ihs transformation 
**ihs(y) similar, so for our purposes - ihs(y) ~= log(y+1)
gen ihs_mmtotamt_t1 = asinh(mmtotamt_t1)

** Figure 2 --------------------------------------------------------------------
/*
*(1) voxdev blogpost
bys trtment: sum ihs_mmtotamt_t1
quietly eststo Control: mean ihs_mmtotamt_t1 if trtment==0
quietly eststo Treatment: mean ihs_mmtotamt_t1 if trtment==1
coefplot Control Treatment, vertical xlabel("") xtitle("{stMono:asinh}(Total Transactions per week)") ytitle(Mean) recast(bar) barwidth(0.25) fcolor(*.5) ciopts(recast(rcap)) citop citype(normal) level(90) graphregion(color(white)) ylab(3(.5)5,nogrid)
gr export $dta_loc/_project/_xREPUTATION/slides/results/gr_serviceusage.eps, replace
gr save $dta_loc/_project/_xREPUTATION/slides/results/gr_serviceusage, replace
*/
cdfplot ihs_mmtotamt_t1, by(trtment) opt1(lc() lp(solid dash)) xtitle("{stMono:asinh}(Total Transactions per week)") ytitle("Cummulative Probability") legend(pos(7) row(1) stack label(1 "Control") label(2 "Any treatment"))
gr export "$output_loc/main_results/te_all_graph.eps", replace

cdfplot ihs_mmtotamt_t1 if (trt==0 | trt==1), by(trtment) opt1(lc() lp(solid dash)) xtitle("{stMono:asinh}(Total Transactions per week)") ytitle("Cumulative Probability") legend(pos(7) row(1) stack label(1 "Control") label(2 "Transparency alone (PT)"))
gr export "$output_loc/main_results/te_pt_graph.eps", replace

cdfplot ihs_mmtotamt_t1 if (trt==0 | trt==2), by(trtment) opt1(lc() lp(solid dash)) xtitle("{stMono:asinh}(Total Transactions per week)") ytitle("Cumulative Probability") legend(pos(7) row(1) stack label(1 "Control") label(2 "Monitoring alone (MR)"))
gr export "$output_loc/main_results/te_m&r_graph.eps", replace

cdfplot ihs_mmtotamt_t1 if (trt==0 | trt==3), by(trtment) opt1(lc() lp(solid dash)) xtitle("{stMono:asinh}(Total Transactions per week)") ytitle("Cumulative Probability") legend(pos(7) row(1) stack label(1 "Control") label(2 "Combined (PT + MR)"))
gr export "$output_loc/main_results/te_both_graph.eps", replace

sum ihs_mmtotamt_t1, d
gen Trim1=ihs_mmtotamt_t1 if ihs_mmtotamt_t1>=r(p5) & ihs_mmtotamt_t1<=r(p95)
ksmirnov Trim1, by(trtment) exact //p-val=0.091
ksmirnov Trim1 if (trt==0 | trt==1), by(trtment) exact //p-val=0.481
ksmirnov Trim1 if (trt==0 | trt==2), by(trtment) exact //p-val=0.068
ksmirnov Trim1 if (trt==0 | trt==3), by(trtment) exact //p-val=0.115 or 0,065




**Trtment Effects: y=a+bTrtment+FEs+X+e**
**Mobile Money - (i) $ Transact, (ii) 0/1 Usage, (iii) 0/1 Save, (iv) PCA Index**
*replace missing obs [y_end, y_base] w their means to maitain same n = 810 (reviewer #1, request, very helpful)*

*1
*ihs transform--a log allowing for 0 and -ve vals
sum ihs_mmtotamt_t1
replace ihs_mmtotamt_t1=r(mean) if missing(ihs_mmtotamt_t1) & _merge==3
sum mmtotamt_t0
replace mmtotamt_t0=r(mean) if missing(mmtotamt_t0) & _merge==3
gen ihs_mmtotamt_t0 = asinh(mmtotamt_t0)


** Table 5 ---------------------------------------------------------------------
sum ihs_mmtotamt_t1 if trtment==0
reg ihs_mmtotamt_t1 ihs_mmtotamt_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment, cluster(loccode) level(95)
reg ihs_mmtotamt_t1 ihs_mmtotamt_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt, cluster(loccode) level(95)
test _b[1.trt]=_b[3.trt]
test _b[2.trt]=_b[3.trt]
test _b[1.trt]=_b[2.trt]
test _b[1.trt] + _b[2.trt] =_b[3.trt]

*2
sum mmUser_t0
replace mmUser_t0=r(mean) if missing(mmUser_t0) & !missing(mmUser_t1)

sum mmUser_t1 if trtment==0
reg mmUser_t1 mmUser_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment, cluster(loccode) level(95)
reg mmUser_t1 mmUser_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt, cluster(loccode) level(95)
test _b[1.trt]=_b[3.trt]
test _b[2.trt]=_b[3.trt]
test _b[1.trt]=_b[2.trt]
test _b[1.trt] + _b[2.trt] =_b[3.trt]

*3
sum save_t0
replace save_t0=r(mean) if missing(save_t0) & !missing(save_t1)

sum save_t1 if trtment==0
reg save_t1 save_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment, cluster(loccode) level(95)
reg save_t1 save_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt, cluster(loccode) level(95)
test _b[1.trt]=_b[3.trt]
test _b[2.trt]=_b[3.trt]
test _b[1.trt]=_b[2.trt]
test _b[1.trt] + _b[2.trt] =_b[3.trt]

*4 (YK: Where is this reported?)
**construct index pooling all directional outcomes ff. Kling et al. (2007)**
factor ihs_mmtotamt_t1 mmUser_t1 save_t1
predict score_MMoneyDd_t1
factor ihs_mmtotamt_t0 mmUser_t0 save_t0
predict score_MMoneyDd_t0

sum score_MMoneyDd_t1 if trtment==0
reg score_MMoneyDd_t1 score_MMoneyDd_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment, cluster(loccode) level(95)
reg score_MMoneyDd_t1 score_MMoneyDd_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt, cluster(loccode) level(95)
test _b[1.trt]=_b[3.trt]
test _b[2.trt]=_b[3.trt]
test _b[1.trt]=_b[2.trt]
test _b[1.trt] + _b[2.trt] =_b[3.trt]


** Table C.5 -------------------------------------------------------------------
*Robustness checks - Inference, Multiple Testing, Attrition, LASSO Estimation
*POOLED
***wild cluster bootstrap, pval
reg ihs_mmtotamt_t1 ihs_mmtotamt_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment, cluster(loccode) level(95)
boottest trt, rep($bootstrap_reps) level(95) nogr seed(15465)
reg mmUser_t1 mmUser_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment, cluster(loccode) level(95)
boottest trt, rep($bootstrap_reps) level(95) nogr seed(1546)
reg save_t1 save_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment, cluster(loccode) level(95)
boottest trt, rep($bootstrap_reps) level(95) nogr seed(1546)
reg score_MMoneyDd_t1 score_MMoneyDd_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment, cluster(loccode) level(95)
boottest trt, rep($bootstrap_reps) level(95) nogr seed(1546)
**randomization inf: permuntation test, pval
ritest trtment _b[trtment], reps($bootstrap_reps) cluster(loccode) strata(districtID) seed(546): reg ihs_mmtotamt_t1 ihs_mmtotamt_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment
ritest trtment _b[trtment], reps($bootstrap_reps) cluster(loccode) strata(districtID) seed(546): reg mmUser_t1 mmUser_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment
ritest trtment _b[trtment], reps($bootstrap_reps) cluster(loccode) strata(districtID) seed(546): reg save_t1 save_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment
ritest trtment _b[trtment], reps($bootstrap_reps) cluster(loccode) strata(districtID) seed(546): reg score_MMoneyDd_t1 score_MMoneyDd_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment
**mht: implement Romano-Wolf (2005) procedure, pval
tab trt if !missing(trt), gen(trt) //gen trts again and verifY
gen trt01 = (trt !=0) if !missing(trt)
rwolf ihs_mmtotamt_t1 mmUser_t1 save_t1 score_MMoneyDd_t1, indepvar(trtment trt2 trt3 trt4) reps($bootstrap_reps) seed(124) controls(i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (demand: amount, 01 usage, 01 savings)
**attrition bounds
**1. [Lee Bounds]**
leebounds ihs_mmtotamt_t1 trtment, level(95) cieffect tight() 
leebounds mmUser_t1 trtment, level(95) cieffect tight() 
leebounds save_t1 trtment, level(95) cieffect tight() 
leebounds score_MMoneyDd_t1 trtment, level(95) cieffect tight() 
**2. [Behajel et al. Bounds]**
gen attempts= c0a
bys trtment: tab attempts
**with 3 or less phone /contact attempts: ctr has 92% response rate, trt has 95% response rate
**use number of attempts - "effort" to rank & bound te
**so trim (95-92)/95 =3% of trt group, x 667= 20 customers out
**Simply trim as follows:
foreach x of varlist ihs_mmtotamt_t1 mmUser_t1 save_t1 score_MMoneyDd_t1 {
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

** Table C.6 -------------------------------------------------------------------
*SEPARATE
***wild cluster bootstrap, pval
reg ihs_mmtotamt_t1 ihs_mmtotamt_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4, cluster(loccode) level(95)
boottest trt2, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt3, rep($bootstrap_reps) level(95) nogr seed(15465)
boottest trt4, rep($bootstrap_reps) level(95) nogr seed(15465)
reg mmUser_t1 mmUser_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4, cluster(loccode) level(95)
boottest trt2, rep($bootstrap_reps) level(95) nogr seed(1546)
boottest trt3, rep($bootstrap_reps) level(95) nogr seed(1546)
boottest trt4, rep($bootstrap_reps) level(95) nogr seed(1546)
reg save_t1 save_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4, cluster(loccode) level(95)
boottest trt2, rep($bootstrap_reps) level(95) nogr seed(1546)
boottest trt3, rep($bootstrap_reps) level(95) nogr seed(1546)
boottest trt4, rep($bootstrap_reps) level(95) nogr seed(1546)
reg score_MMoneyDd_t1 score_MMoneyDd_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4, cluster(loccode) level(95)
boottest trt2, rep($bootstrap_reps) level(95) nogr seed(1546)
boottest trt3, rep($bootstrap_reps) level(95) nogr seed(1546)
boottest trt4, rep($bootstrap_reps) level(95) nogr seed(1546)
**randomization inf: permuntation test, pval
ritest trt2 trt3 trt4 _b[trt2] _b[trt3] _b[trt4], reps($bootstrap_reps) cluster(loccode) strata(districtID) seed(546): reg ihs_mmtotamt_t1 ihs_mmtotamt_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4
ritest trt2 trt3 trt4 _b[trt2] _b[trt3] _b[trt4], reps($bootstrap_reps) cluster(loccode) strata(districtID) seed(546): reg mmUser_t1 mmUser_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4
ritest trt2 trt3 trt4 _b[trt2] _b[trt3] _b[trt4], reps($bootstrap_reps) cluster(loccode) strata(districtID) seed(546): reg save_t1 save_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4
ritest trt2 trt3 trt4 _b[trt2] _b[trt3] _b[trt4], reps($bootstrap_reps) cluster(loccode) strata(districtID) seed(546): reg score_MMoneyDd_t1 score_MMoneyDd_t0 i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4
**mht: implement Romano-Wolf (2005) procedure, pval
rwolf ihs_mmtotamt_t1 mmUser_t1 save_t1 score_MMoneyDd_t1, indepvar(trt2 trt3 trt4) reps($bootstrap_reps) seed(124) controls(i.districtID cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (demand: amount, 01 usage, 01 savings)
**attrition bounds
**1. [Lee Bounds]**
foreach x of varlist trt2 trt3 trt4 {
	leebounds ihs_mmtotamt_t1 `x', level(95) cieffect tight() 
}
*
foreach x of varlist trt2 trt3 trt4 {
	leebounds mmUser_t1 `x', level(95) cieffect tight() 
}
*
foreach x of varlist trt2 trt3 trt4 {
	leebounds save_t1 `x', level(95) cieffect tight() 
}
*
foreach x of varlist trt2 trt3 trt4 {
	leebounds score_MMoneyDd_t1 `x', level(95) cieffect tight() 
}
*
**2. [Behajel et al. Bounds]**
foreach x of varlist ihs_mmtotamt_t1 mmUser_t1 save_t1 score_MMoneyDd_t1 {
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

foreach x of varlist ihs_mmtotamt_t1 mmUser_t1 save_t1 score_MMoneyDd_t1 {
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

foreach x of varlist ihs_mmtotamt_t1 mmUser_t1 save_t1 score_MMoneyDd_t1 {
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
*



**Quantifying: Bias belief vs Direct Price Effects
*.......FROM ABOVE:
*subjective beliefs
gen iHave=(c4q17==1) if !missing(c4q17)
gen iThink=(c8q3==1) if !missing(c8q3)
gen i =(iHave==1 | iThink==1) if !missing(c4q17) | !missing(c8q3)
sum iHave i _clocalpFraud  cfAttempts  iThink

**1. base up-biased beliefs about misconduct
replace text_ge01 = . if cdistrict_name == ""
replace text_ge02 = . if clocality_name == ""
// replace ge03 = . if vn == ""
drop _merge


*bring in audit objective misconduct data
merge m:1 text_ge01 text_ge02 using "$dta_loc_repl/01_intermediate/ofdrate_mktadminTransactData.dta"

*keep if _merge==3
gen bias=(iThink != fdH0_t0) if !missing(iThink)
bys text_ge01 text_ge02: egen bias_mkt = mean(bias) 
sum bias_mkt, d

*drop xB
gen xB=(bias_mkt>0.9375) //bias: above median misrates at per market
sum ihs_mmtotamt_t1 mmUser_t1 if trtment==0

** Table C.17 ------------------------------------------------------------------
*pooled?

reg ihs_mmtotamt_t1 i.districtID ihs_mmtotamt_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome c.trtment if xB==1, cluster(loccode) level(95)
reg ihs_mmtotamt_t1 i.districtID ihs_mmtotamt_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome c.trtment if xB==0, cluster(loccode) level(95)

reg mmUser_t1 i.districtID mmUser_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome c.trtment if xB==1, cluster(loccode) level(95)
reg mmUser_t1 i.districtID mmUser_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome c.trtment if xB==0, cluster(loccode) level(95)

*separate?
reg ihs_mmtotamt_t1 i.districtID ihs_mmtotamt_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt if xB==1, cluster(loccode) level(95)
reg ihs_mmtotamt_t1 i.districtID ihs_mmtotamt_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt if xB==0, cluster(loccode) level(95)

reg mmUser_t1 i.districtID mmUser_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt if xB==1, cluster(loccode) level(95)
reg mmUser_t1 i.districtID mmUser_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt if xB==0, cluster(loccode) level(95)
reg mmUser_t1 i.districtID mmUser_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt if xB==0, r level(95)


**if assume identical price sensitibity - (balance test, yes-some balance)
reg cfemale xB, cluster(loccode)
reg cmarried xB, cluster(loccode)
reg cakan xB, cluster(loccode)
reg cage xB, cluster(loccode)
reg cEducAny xB, cluster(loccode)
reg cselfemployed xB, cluster(loccode)
reg cselfIncome xB, cluster(loccode)
reg cMMoneyregistered xB, cluster(loccode)
reg xB cfemale cmarried cakan cage cEducAny cselfemployed cselfIncome cMMoneyregistered, cluster(loccode)
test cfemale cmarried cakan cage cEducAny cselfemployed cselfIncome cMMoneyregistered
probit xB cfemale cakan cmarried cage cEducAny cselfemployed cselfIncome cMMoneyregistered, cluster(loccode)
test cfemale cmarried cakan cage cEducAny cselfemployed cselfIncome cMMoneyregistered













