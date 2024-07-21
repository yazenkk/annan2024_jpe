/*
JPE2023-Annan
y = beliefs*

Title: ?

Input:
	- FFPhone in 2020/Customer_+_Mktcensus_+_Interventions.dta
	- FINAL AUDIT DATA/_Francis/ofdrate_mktAudit_endline.dta
Output: 
	- FFPhone in 2020/_impact-evaluation/te_belief_all_graph.eps
	- FFPhone in 2020/_impact-evaluation/te_belief_pt_graph.eps
	- FFPhone in 2020/_impact-evaluation/te_belief_m&r_graph.eps
	- FFPhone in 2020/_impact-evaluation/te_belief_both_graph.eps
*/

**Consumers subjective beliefs: shifts + updates*
use "$dta_loc_repl/02_final/Customer_+_Mktcensus_+_Interventions.dta", clear

drop _merge
*drop if missing(_customer2020_id)
**bring in audit-objective endline data: "use sep 06 fd data"
merge m:1 ge01 ge02 using "$dta_loc_repl/01_intermediate/ofdrate_mktAudit_endline.dta"
*merge m:1 ge01 ge02 using "$dta_loc/FINAL AUDIT DATA/_Francis/MisconObj_Endline.dta"
*drop if missing(_customer2020_id)
gen dropout_belief = missing(customer2020_id) // PII but used as marker
tab dropout_belief

// encode ge01, gen(districtID)
gen districtID = ge01

**views now about misconduct in dxn of info assignments?
**e.g., perceive misconduct is low? "correctly" perceive others in locality perceive misconduct low?
tab c8a
tab c8b
tab c4
tab c8q3 //baseline belief (ok)

tab date_of_interview trt

gen dhonestVendors1=(c8a==1) if dropout_belief==0 //i agree to misconduct: not incentivized
gen dhonestVendors2=c8b if dropout_belief==0 //incentivized (% agree for dishonest vendors)
gen dhonestVendors3=(c4==1) if dropout_belief==0 //i think experiencing it (yes)
gen dhonestVendors4=(c8a==1 | c4==1) if dropout_belief==0
pwcorr dhonestVendors*, sig
sum dhonestVendors* if trtment==0 & dropout_belief==0


gen honestVendors1=(c8a==2) if dropout_belief==0 //i disagree misconduct: not incentivized
gen honestVendors2=100-c8b if dropout_belief==0 //incentivized (% WONT agree dishonest vendors)
gen honestVendors3=(c4==2) if dropout_belief==0 //i think experiencing it (no)
gen honestVendors4=(c8a==2 | c4==2) if dropout_belief==0
pwcorr honestVendors*, sig
sum honestVendors* if trtment==0 & dropout_belief==0

*********
*n=792 vs n=810 (ok)
tab _merge
egen uniqueLocalityID = group(ge01 ge02)

**********************************************
*q.1: beliefs shifted in right direction, yes?
sum honestVendors1 if trtment==0
tab trt if !missing(trt), gen(trt) //gen trts again and verifY
gen trt01 = (trt !=0) if !missing(trt)


** Table 3 ---------------------------------------------------------------------
*reg honestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt01 if dropout_belief==0, level(95) r
reg honestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment if dropout_belief==0, level(95) r
*reg honestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4 if dropout_belief==0, level(95) r cluster(uniqueLocalityID)
reg honestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt if dropout_belief==0, level(95) r cluster(uniqueLocalityID)
test 1.trt=3.trt
test 2.trt=3.trt
test 1.trt=2.trt
test 1.trt+2.trt=3.trt

** Figure 1 --------------------------------------------------------------------
*q.1: beliefs shifted in right direction, yes - graphically?
bys ge01 ge02: egen mx = mean(honestVendors1) if dropout_belief==0
bys trt: sum mx
cdfplot mx if (trt==0 | trt==1 | trt==2 | trt==3), by(trtment) opt1(lc() lp(solid dash)) xtitle("Share that perceive vendors are honest") ytitle("Cumulative Probability") legend(pos(7) row(1) stack label(1 "Control") label(2 "Any treatment"))
gr export "$output_loc/main_results/te_belief_all_graph.eps", replace
ksmirnov mx, by(trtment) exact //p-val=0.000

*(1) voxdev
bys trtment: sum mx
quietly eststo Control: mean mx if trtment==0
quietly eststo Treatment: mean mx if trtment==1
coefplot Control Treatment, vertical xlabel("") xtitle(Share that perceive vendors are honest) ytitle(Mean) recast(bar) barwidth(0.25) fcolor(*.5) ciopts(recast(rcap)) citop citype(logit) level(95)  graphregion(color(white)) ylab(,nogrid)
gr export $output_loc/main_results/gr_conduct_perceptions.eps, replace
gr save $output_loc/main_results/gr_conduct_perceptions, replace


cdfplot mx if (trt==0 | trt==1), by(trtment) opt1(lc() lp(solid dash)) xtitle("Share that perceive vendors are honest") ytitle("Cumulative Probability") legend(pos(7) row(1) stack label(1 "Control") label(2 "Transparency alone (PT)"))
gr export "$output_loc/main_results/te_belief_pt_graph.eps", replace
ksmirnov mx if (trt==0 | trt==1), by(trtment) exact //p-val=0.000

cdfplot mx if (trt==0 | trt==2), by(trtment) opt1(lc() lp(solid dash)) xtitle("Share that perceive vendors are honest") ytitle("Cumulative Probability") legend(pos(7) row(1) stack label(1 "Control") label(2 "Monitoring alone (MR)"))
gr export "$output_loc/main_results/te_belief_m&r_graph.eps", replace
ksmirnov mx if (trt==0 | trt==2), by(trtment) exact //p-val=0.000

cdfplot mx if (trt==0 | trt==3), by(trtment) opt1(lc() lp(solid dash)) xtitle("Share that perceive vendors are honest") ytitle("Cumulative Probability") legend(pos(7) row(1) stack label(1 "Control") label(2 "Combined (PT + MR)"))
gr export "$output_loc/main_results/te_belief_both_graph.eps", replace
ksmirnov mx if (trt==0 | trt==3), by(trtment) exact //p-val=0.000


** Table 4 ---------------------------------------------------------------------
********************************************************************
**q.2: beliefs update - ability to correctly infer vendor Misconduct - Key reputation ingredient
sum dhonestVendors* if trtment==0 & dropout_belief==0
replace fdH0=1 if missing(fdH0) & dropout_belief==0 //NOTE: results (n=792) = results (n=810) if recode implemented to get n=810
*replace MisconObj=1 if missing(MisconObj) //NOTE: results (n=792) = results (n=810) if recode implemented to get n=810
reg dhonestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome c.trtment##c.fdH0 if dropout_belief==0, level(95) r cluster(uniqueLocalityID)
reg dhonestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt##c.fdH0 if dropout_belief==0, level(95) r cluster(uniqueLocalityID)
test 1.trt#c.fdH0=3.trt#c.fdH0
test 2.trt#c.fdH0=3.trt#c.fdH0
test 1.trt#c.fdH0=2.trt#c.fdH0
test 1.trt#c.fdH0+2.trt#c.fdH0=3.trt#c.fdH0
/*
*or, easily replicated w Honesty (neg of disHonesty)
gen hfdH0=1-fdH0
sum honestVendors* if trtment==0
reg honestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome c.trtment##c.hfdH0 if dropout_belief==0, level(90) r cluster(uniqueLocalityID)
reg honestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trt##c.hfdH0 if dropout_belief==0, level(90) r cluster(uniqueLocalityID)
*/

*Robustness checks - Inference, Multiple Testing, Attrition, LASSO Estimation
*POOLED-belief (honesty)
**************
*wild cluster bootstrap, pval
reg honestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment if dropout_belief==0, r cluster(uniqueLocalityID) level(95)
boottest trtment, rep($bootstrap_reps) level(95) nogr seed(546)
*randomization inf: permuntation test, pval
preserve
keep if dropout_belief==0 //ON & OFF
ritest trtment _b[trtment], reps($bootstrap_reps) cluster(uniqueLocalityID) strata(districtID) seed(546): reg honestVendors1 i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trtment 
restore
*mht: implement Romano-Wolf (2005) procedure, pval
rwolf honestVendors1 dhonestVendors1 if dropout_belief==0, indepvar(trtment trt2 trt3 trt4) reps($bootstrap_reps) seed(124) controls(i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (1=beliefs & 2=update)
*attrition bounds
leebounds honestVendors1 trtment, level(95) cieffect tight() 

*SEPARATE-belief (honesty)
****************
*wild cluster bootstrap, pval
reg honestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4 if dropout_belief==0, r cluster(uniqueLocalityID) level(95)
boottest trt2, rep($bootstrap_reps) level(95) nogr seed(546)
boottest trt3, rep($bootstrap_reps) level(95) nogr seed(546)
boottest trt4, rep($bootstrap_reps) level(95) nogr seed(546)
*randomization inf: permuntation test, pval
preserve
keep if dropout_belief==0 //ON & OFF
ritest trt2 trt3 trt4 _b[trt2] _b[trt3] _b[trt4], reps($bootstrap_reps) cluster(uniqueLocalityID) strata(districtID) seed(546): reg honestVendors1 i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4 
restore
*mht: implement Romano-Wolf (2005) procedure, pval
rwolf honestVendors1 dhonestVendors1 if dropout_belief==0, indepvar(trt2 trt3 trt4) reps($bootstrap_reps) seed(124) controls(i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (1=beliefs & 2=update)
*attrition bounds
leebounds honestVendors1 trt2, level(95) cieffect tight() 
leebounds honestVendors1 trt3, level(95) cieffect tight() 
leebounds honestVendors1 trt4, level(95) cieffect tight() 


*POOLED-update (dishonesty)
****************
*wild cluster bootstrap, pval
reg dhonestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome c.trtment##c.fdH0 if dropout_belief==0, r cluster(uniqueLocalityID) level(95)
*boottest trtment, rep($bootstrap_reps) level(95) nogr seed(546)
*boottest fdH0, rep($bootstrap_reps) level(95) nogr seed(546)
boottest c.trtment#c.fdH0, rep($bootstrap_reps) level(95) nogr seed(546)
*randomization inf: permuntation test, pval
preserve
keep if dropout_belief==0 //ON & OFF
gen trtmentXfdH0= trtment*fdH0  if dropout_belief==0
ritest trtment trtmentXfdH0 fdH0 _b[trtment] _b[trtmentXfdH0] _b[fdH0], reps($bootstrap_reps) cluster(uniqueLocalityID) strata(districtID) seed(546): reg dhonestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome c.trtment trtmentXfdH0 fdH0
restore
*mht: implement Romano-Wolf (2005) procedure, pval
gen trtmentXfdH0= trtment*fdH0 if dropout_belief==0
rwolf dhonestVendors1 honestVendors1 if dropout_belief==0, indepvar(trtment trt2 trt3 trt4 trtmentXfdH0 fdH0) reps($bootstrap_reps) seed(124) controls(i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (1=beliefs & 2=update)
*attrition bounds
cap leebounds dhonestVendors1 trtmentXfdH0, level(95) cieffect tight() 

*SEPARATE-update (dishonesty)
**************
*wild cluster bootstrap, pval
reg dhonestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome c.trt2##c.fdH0 c.trt3##c.fdH0 c.trt4##c.fdH0 if dropout_belief==0, r cluster(uniqueLocalityID) level(95)
boottest c.trt2#c.fdH0, rep($bootstrap_reps) level(95) nogr seed(546) //ignore rest, not reporting in Table so OK
boottest c.trt3#c.fdH0, rep($bootstrap_reps) level(95) nogr seed(546)
boottest c.trt4#c.fdH0, rep($bootstrap_reps) level(95) nogr seed(546)
*randomization inf: permuntation test, pval
preserve
keep if dropout_belief==0 //ON & OFF
gen trt2XfdH0= trt2*fdH0 if dropout_belief==0
gen trt3XfdH0= trt3*fdH0 if dropout_belief==0
gen trt4XfdH0= trt4*fdH0 if dropout_belief==0
ritest trt2 trt3 trt4 trt2XfdH0 trt3XfdH0 trt4XfdH0 fdH0 _b[trt2] _b[trt3] _b[trt4] _b[trt2XfdH0] _b[trt3XfdH0] _b[trt4XfdH0] _b[fdH0], reps($bootstrap_reps) cluster(uniqueLocalityID) strata(districtID) seed(546): reg dhonestVendors1 i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome trt2 trt3 trt4 trt2XfdH0 trt3XfdH0 trt4XfdH0 fdH0
restore
*mht: implement Romano-Wolf (2005) procedure, pval
gen trt2XfdH0= trt2*fdH0 if dropout_belief==0
gen trt3XfdH0= trt3*fdH0 if dropout_belief==0
gen trt4XfdH0= trt4*fdH0 if dropout_belief==0
rwolf dhonestVendors1 honestVendors1 if dropout_belief==0, indepvar(trtment trt2 trt3 trt4 trt2XfdH0 trt3XfdH0 trt4XfdH0 fdH0) reps($bootstrap_reps) seed(124) controls(i.districtID i.c8q3 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome) //family (1=beliefs & 2=update)
*attrition bounds
cap leebounds dhonestVendors1 trt2XfdH0, level(95) cieffect tight() 
cap leebounds dhonestVendors1 trt2XfdH0, level(95) cieffect tight() 
cap leebounds dhonestVendors1 trt2XfdH0, level(95) cieffect tight() 



** Table C.15 ------------------------------------------------------------------
*Appendix: DIRECT LINK  - directly link belief update induced by treatments with quantities
*******************************************************************************************
gen predictingfd=(dhonestVendors1==fdH1) if (!missing(dhonestVendors1) | !missing(fdH1)) //0-1 indicator for matches

gen ihs_mmtotamt_t1 = asinh(mmtotamt_t1)
gen ihs_mmtotamt_t0 = asinh(mmtotamt_t0)
sum ihs_mmtotamt_t0 mmUser_t0 predictingfd if trtment==0 & dropout_belief==0
**Effect of consumer belief update (due to trt) on market outcomes? 
*NOTE: interacted with "trt" so control=0

*pooled effect
gen trtmentXpredictingfd= trtment*predictingfd
reg ihs_mmtotamt_t1 i.districtID ihs_mmtotamt_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trtmentXpredictingfd, cluster(loccode) level(95)
reg mmUser_t1 i.districtID mmUser_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trtmentXpredictingfd, cluster(loccode) level(95)
*separate effects
gen trtXpredictingfd = trt*c.predictingfd
reg ihs_mmtotamt_t1 i.districtID ihs_mmtotamt_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trtXpredictingfd, cluster(loccode) level(95)
reg mmUser_t1 i.districtID mmUser_t0 cfemale cage cmarried cakan cselfemployed cEducAny cselfIncome i.trtXpredictingfd, cluster(loccode) level(95)





















