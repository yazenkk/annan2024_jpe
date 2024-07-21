/*
Title: 

Input:
	- data-Mgt/Stats?/_M_all_2_18.dta (merged raw data: M?+_M1)
	- data-Mgt/Stats?/_CM_all_2_18.dta (merged raw data: CM?+_CM1)
	
Output:
	Data:
		- Mkt_fieldData.dta/csv
		- Mkt_fieldData_census.dta
		
	Graphs:
		- FFPhone in 2020/_impact-evaluation/ai_customerVsvendor_graph.eps
		- FFPhone in 2020/_impact-evaluation/mispercep_misconduct_graph.eps
		- _dailyNobCustomers.eps
		- _dailyTotMoney.eps
		- _dailyNobCustomers_NonM.eps
		- _dailyTotMoney_nonM.eps
		- _wklyNobUsage.eps
		- _wklyTotUseVol.eps
		- _wklyNobUsage_nonM.eps
		- _wklyTotUseVol_nonM.eps
		- _xdevsKdensStr.eps
		- _xdevsKdensAsy.eps
		
[Confirm: separate data prep from analysis?]
	
*/


*TROUBLE FOR VENDORS UP?
use "$dta_loc_repl/00_raw_anon/_M_all_2_18_corrected.dta", clear 

tab vendor, miss


**number M per local?
bys ge02: gen MktPerLocal = _N
hist MktPerLocal
sum MktPerLocal // 1 to 12 with avg=5 merchants

**Next, add customers?
gen locality_name= ln
gen vendor_id= vendor // only unique within loccode (locality)
gen interviewer =interviewer_v

merge 1:m distcode ge03 using "$dta_loc_repl/00_raw_anon/_CM_all_2_18.dta" // distcode drops three vendors


*keep if (_merge==3)
egen Mkt = group(loccode vendor_id)
tab Mkt

** # of localities & # of customers per mkt
egen cnoofLocalities = group(loccode)
bys Mkt: gen cnoofCustPerMkt = _N

sum cnoofLocalities
sum cnoofCustPerMkt


**summaries
**get customers
gen cfemale=(c1q1==2)
replace cfemale=. if missing(c1q1)

gen cakan =(c1q2==1)
replace cakan=. if missing(c1q2)

gen cmarried=(c1q3==1)
replace cmarried=. if missing(c1q3)

gen cage =c1q4
replace cage=. if missing(c1q4)

gen cEducAny =(c1q5>1)
replace cEducAny=. if missing(c1q5)

gen cEduc =c1q5
replace cEduc=. if missing(c1q5)

gen cselfemployed =(c1q6==1)
replace cselfemployed=. if missing(c1q6)

gen cselfIncome =c1q7
replace cselfIncome=. if missing(c1q7)

gen cMMoneyregistered=(c1q9==1)
replace cMMoneyregistered=. if missing(c1q9)


**get merchants
gen mfemale=(m1q1==2)
replace mfemale=. if missing(m1q1)

gen makan =(m1q2==1)
replace makan=. if missing(m1q2)

gen mmarried=(m1q3==1)
replace mmarried=. if missing(m1q3)

gen mage =m1q4
replace mage=. if missing(m1q4)

gen mEducAny =(m1q5>3)
replace mEducAny=. if missing(m1q5)

gen mEduc =m1q5
replace mEduc=. if missing(m1q5)

gen mselfemployed =(m1q6==1)
replace mselfemployed=. if missing(m1q6)

gen mselfIncome =m1q7
replace mselfIncome=. if missing(m1q7)

gen mbusTrained = (m2q2==1)
replace mbusTrained=. if missing(m2q2)

**females?
tab mfemale
*joint business structure?
tab m3q1


**Fraud: Measure I
gen cfAttempts =(c5q7a==1 | c5q7b==1 | c5q7c==1)
replace cfAttempts=. if missing(c5q7a)
replace cfAttempts=. if missing(c5q7b)
replace cfAttempts=. if missing(c5q7c)

gen cfAccountUse =(c5q7a==1)
replace cfAccountUse=. if missing(c5q7a)

gen cfCallers =(c5q7b==1)
replace cfAccountUse=. if missing(c5q7b)

gen cfIncorrects =(c5q7c==1)
replace cfIncorrects=. if missing(c5q7c)

sum cfAttempts cfAccountUse cfCallers cfIncorrects

**xbase correlates of fraud
reg cfAttempts cfemale cakan cmarried cage cEducAny cselfemployed cselfIncome cMMoneyregistered, cluster(loccode)



**Knowledge discrepancies & perceived Mkt structure/ fraud evidence?
*Knowledge test?
**Customers?
**c8q1b=c200 vs c8q2=c1200
gen c_chargeC200 = c8q1b

replace c_chargeC200=. if (c_chargeC200==0 | c_chargeC200>=99)
// br c_chargeC200

*replace c_chargeC200=. if (c_chargeC200==0 | c_chargeC200==99)
*hist c_chargeC200, xline(2, lwidth(vthick) lcolor(blue)) fcolor(none) title("Knowledge Test: Customers, MTN Charge for GHC200") ///
* xtitle("Discrepancy in stated charges for GHC200") text(2 2 "Correct charge--in blue", place(e))

gen c_x200=c_chargeC200-2
*hist c_x200

gen c_chargeC1200 = c8q2
replace c_chargeC1200=. if (c_chargeC1200==0 | c_chargeC1200>=99)
*replace c_chargeC1200=. if (c_chargeC1200==0 | c_chargeC1200==99)
*hist c_chargeC1200, xline(10, lwidth(vthick) lcolor(blue)) fcolor(none) title("Knowledge Test: Customers, MTN Charge for GHC1200") ///
* xtitle("Discrepancy in stated charges for GHC1200") text(0.15 10 "Correct charge--in blue", place(e))

gen c_x1200=c_chargeC1200-10
*hist c_x1200

gen c_deviations = c_x200
replace c_deviations= c_x1200 if missing(c_deviations)
// hist c_deviations

**gender difference in customer knowledge?
reg c_deviations cfemale

*drop if missing(c_deviations)
*drop if missing(cfemale)
cdfplot c_deviations, by(cfemale) opt1(lc(blue red)) xtitle("Knowledge Tests: n (Males)=231, n (Females)=157") ytitle("CDF") legend(pos(3) col(1) stack label(1 "Males") label(2 "Females"))
hist c_deviations, by(cfemale)

gen c_correctsI=(c_deviations==0) 
gen c_corrects=(c_deviations==0)  if !missing(c_deviations)
bys cfemale: sum c_corrects
bys loccode cfemale: egen fq_cc_corrects = mean(c_corrects) 
cdfplot fq_cc_corrects if !missing(cfemale), by(cfemale) opt1(lc(blue red)) xtitle("Knowledge Tests: n (Males)=743, n (Females)=1,253") ytitle("CDF") legend(pos(3) col(1) stack label(1 "Males") label(2 "Females"))

regress c_corrects cfemale
regress fq_cc_corrects cfemale
**42%(c-females) vs 48%(c-males) accuracy



**Merchants?
gen m_chargeC200 = m6q1b
replace m_chargeC200=. if (m_chargeC200==0 | m_chargeC200>=99)
*replace m_chargeC200=. if (m_chargeC200==0 | m_chargeC200==99)
*hist m_chargeC200, xline(2, lwidth(vthick) lcolor(blue)) fcolor(none) title("Knowledge Test: Merchants, MTN Charge for GHC200") ///
* xtitle("Discrepancy in stated charges for GHC200") text(2 2 "Correct charge--in blue", place(e))

gen m_x200=m_chargeC200-2
*hist m_x200

gen m_chargeC1200 = m6q2
replace m_chargeC1200=. if (m_chargeC1200==0 | m_chargeC1200>=99)
*replace m_chargeC1200=. if (m_chargeC1200==0 | m_chargeC1200==99)
*hist m_chargeC1200, xline(2, lwidth(vthick) lcolor(blue)) fcolor(none) title("Knowledge Test: Merchants, MTN Charge for GHC1200") ///
* xtitle("Discrepancy in stated charges for GHC1200") text(2 10 "Correct charge--in blue", place(e))

gen m_x1200=m_chargeC1200-10
*hist m_x1200 if m_x1200<20

gen m_deviations = m_x200
replace m_deviations= m_x1200 if missing(m_deviations)
hist m_deviations

regress m_deviations mfemale


**Testing AI?
twoway (hist c_x200 if c_x200<200, color(green)) ///
(hist m_x200 if m_x200<200, fcolor(green) color(blue)), legend(order(1 "Customers" 2 "Merchants" ))
graph export "$output_loc/baseline/_x200.eps", replace


twoway (hist c_x1200 if c_x1200<200, color(green)) ///
(hist m_x1200 if m_x1200<200, fcolor(grey) color(blue)), legend(order(1 "Customers" 2 "Merchants" ))
graph export "$output_loc/baseline/_x1200.eps", replace

*replace _asymLocally1200=. if (c_x1200<-800 | c_x1200>800)
twoway (hist c_deviations if c_deviations<200, color(green)) ///
(hist m_deviations if m_deviations<200, fcolor(grey) color(blue)), legend(order(1 "Customers" 2 "Merchants" )) title("Knowledge Tests:") subtitle("Deviations from Correct Transactional Charges") note("NOTE: Customers are 52.3% of the time Incorrect. Merchants are 33.1% of the time Incorrect")
graph export "$output_loc/baseline/_xdevs.eps", replace


**incorrections Counts...
count if (c_deviations==0 & c_deviations<200)
count if (!missing(c_deviations) & c_deviations<200)
dis "Wrong crate is, custormers: =" (1-(897/1836))*100 "%"

count if (m_deviations==0 & m_deviations<200)
count if (!missing(m_deviations) & m_deviations<200)
dis "Wrong mrate is, merchants: =" (1-(1225/1886))*100 "%"

**incorrectness: 51% vs 35%



**by Gender?
gen m_correctsI=(m_deviations==0)
gen m_corrects=(m_deviations==0) if !missing(m_deviations)

bys mfemale: sum m_corrects
regress m_corrects mfemale
regress m_corrects mfemale, cluster(loccode)
**59(m-females) vs (m-males)70 accuracy
**graphically?
bys loccode mfemale: egen fq_mm_corrects = mean(m_corrects)
cdfplot fq_mm_corrects if !missing(cfemale), by(cfemale) opt1(lc(blue red)) xtitle("Knowledge Tests: n (Males)=743, n (Females)=1,253") ytitle("CDF") legend(pos(3) col(1) stack label(1 "Males") label(2 "Females"))

**ttests
ttest c_deviations == m_deviations, unpaired


**Asymmetric Tnformation Test**
bys loccode: egen mkt_m_corrects = mean(m_corrects)
bys loccode: egen mkt_c_corrects = mean(c_corrects)


bys loccode vendor_id: gen nobvendors=_N
bys loccode: gen nobcustomers=_N

sum mkt_c_corrects, d
sum mkt_m_corrects if (mkt_m_corrects > 0), d
*Means: c=48 vs v=73
*Median: c=42 vs v=79
**Trim: zero vendor knowledge in a whole locality is sugestive of potential vendor misconduct, so drop those
distplot mkt_c_corrects mkt_m_corrects if (mkt_m_corrects > 0), xline(0.48, lp(solid) lw(vthin)) text(0.8 0.38 "Customers: Overall share", size(vsmall)) xline(0.73, lp(dash) lw(vthin)) lp(solid dash) text(0.1 0.82 "Vendors: Overall share", size(vsmall))  xtitle("Share with correct answers") ytitle("Cumulative Probability") legend(pos(7) row(1) stack label(1 "Customers") label(2 "Vendors"))
gr export "$output_loc/baseline/ai_customerVsvendor_graph.eps", replace
**NOTE: Trimmed to exlude unrealistic zero vendor knowlege at the mkt level


**Misperceived beliefs about Misconduct?
gen cat="true" if _n==1
gen misconduct=0.22 if cat=="true"
gen n=663 if cat=="true"
gen sd=0.41 if cat=="true"

replace cat="subjective" if _n==2
replace misconduct=0.59 if cat=="subjective"
replace sd=0.49 if cat=="subjective"
replace n=1921 if cat=="subjective"

gen se=sd/sqrt(n) 
gen upper = misconduct + se
gen lower = misconduct - se 

generate himiscon90 = misconduct + invttail(n-1,0.05)*(sd / sqrt(n))
generate lowmiscon90 = misconduct - invttail(n-1,0.05)*(sd / sqrt(n))
*graph twoway (bar meanwrite race) (rcap hiwrite lowrite race), by(se) // (YK: change to SE. meanwrite DNE)

gen catt=(cat=="true") if !missing(cat)
** Figure B.10 ----------------------------------------------------------------
graph hbar misconduct, over(cat, sort(1)) bar(1, color(black)) bar(2, color(gs8)) nofill asyvars ///
 blabel(group, position(inside) format(%4.2f) box fcolor(white) lcolor(white)) ytitle("Misconduct Incidence: Share of transactions overcharged", size(small)) blabel(bar) ///
 legend(pos(7) row(1) stack label(1 "Perceived misconduct") label(2 "Objective (true) misconduct"))
gr export "$output_loc/baseline/mispercep_misconduct_graph.eps", replace

ttesti 663 0.22 0.41 1921 0.59 0.49



  
**Correlates of incorrectness: Merchants vs Customers
gen _dVc=(c_deviations !=0)
gen _dVm=(m_deviations !=0)
reg _dVc cfemale cakan cmarried cage cEduc cMMoneyregistered cselfemployed cselfIncome
reg _dVm mfemale makan mmarried mage mEduc mbusTrained cselfemployed cselfIncome

*********************************************
** YK: where is this reported?
preserve
	keep c_deviations m_deviations
	gen id=_n 
	tempfile deviations
	save 	`deviations'

	use `deviations', clear
	keep id c_deviations
	gen group=0
	gen deviations=c_deviations
	tempfile c_deviations
	save `c_deviations'

	use `deviations', clear
	keep id m_deviations
	gen group=1
	gen deviations=m_deviations
	tempfile m_deviations
	save 	`m_deviations'

	append using `c_deviations'
	ksmirnov deviations, by(group) //strong nonparametric rejection 1% level...

restore
**********************************************

**Fraud: Measure II
gen c_localpFraudi = (c4q17==1)
replace c_localpFraudi=. if missing(c4q1)

gen c_localpFraudii = (c8q3==1)
replace c_localpFraudii=. if missing(c8q3)

gen _clocalpFraud=(c_localpFraudi==1 |c_localpFraudii==1)
replace _clocalpFraud=. if missing(c_localpFraudi)
replace _clocalpFraud=. if missing(c_localpFraudii)

gen everOvercharged=c_localpFraudi
gen thinkOvercharging=c_localpFraudii
sum everOvercharged thinkOvercharging _clocalpFraud


**Mkt structure?
gen c_badReportSys = (c8q4==2)
replace c_badReportSys=. if missing(c8q4)

gen c_dontTrustSys = (c8q5==2)
replace c_dontTrustSys=. if missing(c8q5)

gen c_badMktStructure=(c_badReportSys==1 |c_dontTrustSys==1)
replace c_badMktStructure=. if missing(c_badReportSys)
replace c_badMktStructure=. if missing(c_dontTrustSys)

sum c_badMktStructure c_badReportSys c_dontTrustSys
*hist c_localpFraud, title("Custmers: Perceived overcharge / fraud")
*hist c_badMktStructure, discrete fraction gap(5) fcolor(grey) color(blue) title("Customers: bad Mkt structure to report fraud") 



***************************
**asy info vs mkt str
gen _cfraud=(cfAttempts==1 | _clocalpFraud==1)
replace _cfraud=. if missing(cfAttempts)
replace _cfraud=. if missing(_clocalpFraud)

gen _Xcfraud=(cfAccountUse==1 | everOvercharged==1)
replace _Xcfraud=. if missing(cfAccountUse)
replace _Xcfraud=. if missing(everOvercharged)


gen _asymLocally200 = (c_x200 !=0)  
replace _asymLocally200=. if missing(c_x200) 

gen _asymLocally1200 = (c_x1200 !=0) 
replace _asymLocally1200=. if (c_x1200<-800 | c_x1200>800)
replace _asymLocally1200=. if missing(c_x1200)  

gen _asymLocally = (_asymLocally200==1 | _asymLocally1200 ==1)
replace _asymLocally=. if missing(_asymLocally200)
replace _asymLocally=. if missing(_asymLocally1200)


**Testing...
reg cfAttempts c_badMktStructure _asymLocally, cluster(loccode)
reg _Xcfraud c_badMktStructure _asymLocally, cluster(loccode)


**Ia. MMoney sales?
gen dailyNobCustomers=m2q4a
gen dailyTotMoney=m2q4b
hist dailyNobCustomers, title(Merchants: dailyNobCustomers)
graph export "$output_loc/baseline/_dailyNobCustomers.eps", replace
hist dailyTotMoney, title(Merchants: dailyTotMoney)
graph export "$output_loc/baseline/_dailyTotMoney.eps", replace

**Ib. nonMMoney sales?
gen dailyNobCustomers_nonM =m3q3a1 
gen dailyTotMoney_nonM =m3q3a2
hist dailyNobCustomers_nonM, title(Merchants: dailyNobCustomers_nonM)
graph export "$output_loc/baseline/_dailyNobCustomers_NonM.eps", replace
hist dailyTotMoney_nonM, title(Merchants: dailyTotMoney_nonM)
graph export "$output_loc/baseline/_dailyTotMoney_nonM.eps", replace


**IIa. Take-up & MMoney adoption decisions?
gen wklyNobUsage=c4q11a
gen wklyTotUseVol=c4q11b
hist wklyNobUsage, title(Customers: wklyNobUsage)
graph export "$output_loc/baseline/_wklyNobUsage.eps", replace
hist wklyTotUseVol, title(Customers: wklyTotUseVol)
graph export "$output_loc/baseline/_wklyTotUseVol.eps", replace


**IIb. Take-up & NonMMoney adoption decisions?
gen wklyNobUsage_nonM=c4q18a
gen wklyTotUseVol_nonM=c4q18b
hist wklyNobUsage_nonM, title(Customers: wklyNobUsage_nonM)
graph export "$output_loc/baseline/_wklyNobUsage_nonM.eps", replace
hist wklyTotUseVol_nonM, title(Customers: wklyTotUseVol_nonM)
graph export "$output_loc/baseline/_wklyTotUseVol_nonM.eps", replace


*IIc. borrow + save behavior?
gen wklyNobBorrow=c5q2a
gen wklyTotBorrowVol=c5q2b
gen wklyNobSave=c5q6a
gen wklyTotSaveVol=c5q6b
sum wklyNobBorrow wklyTotBorrowVol wklyNobSave wklyTotSaveVol



**Graphical evidence
bys Mkt: egen _MktFraudI=mean(cfAttempts)
bys Mkt: egen _MktFraudII=mean(_Xcfraud)

bys Mkt: egen _MktbadStr=mean(c_badMktStructure)
bys Mkt: egen _MktAsym=mean(_asymLocally)

*scatter?
tw (sc _MktFraudI _MktbadStr, jitter(1) xtitle("Market: fraction indicating bad structure") ///
ytitle("Market: Fraction experiencing attempt fraud")) ///
(lfit _MktFraudI _MktbadStr if _MktbadStr<=0.5, lcolor(black) lwidth(thick)) ///
(lfit _MktFraudI _MktbadStr if _MktbadStr>=0.5, lcolor(black) lwidth(thick))

tw (sc _MktFraudI _MktAsym, jitter(1) xtitle("Market: fraction incorrect transactional knowledge") ///
ytitle("Market: Fraction experiencing attempt fraud")) ///
(lfit _MktFraudI _MktAsym if _MktAsym<=0.5, lcolor(black) lwidth(thick)) ///
(lfit _MktFraudI _MktAsym if _MktAsym>=0.5, lcolor(black) lwidth(thick))

*kdensity?
tw (kdensity _MktFraudI if _MktbadStr==0, lcolor(black) xtitle("Market: Attempted fraud rate")) ///
(kdensity _MktFraudI if _MktbadStr==1, lcolor(blue) ytitle("Probability") legend(label(1 "Bad Mkt structure=No") label(2 "Bad Mkt structure=Yes")))
graph export "$output_loc/baseline/_xdevsKdensStr.eps", replace

tw (kdensity _MktFraudI if _MktAsym==0, lcolor(black) xtitle("Market:  Attempted fraud rate")) ///
(kdensity _MktFraudI if _MktAsym==1, lcolor(blue) ytitle("Probability") legend(label(1 "Incorrect knowledge=No") label(2 "Incorrect knowledge=Yes")))
graph export "$output_loc/baseline/_xdevsKdensAsy.eps", replace


**III. Selection in fraud? any evidence of discrimination, gender?
reg cfAttempts cfemale cakan cmarried cage cEducAny cMMoneyregistered, cluster(loccode)
reg _Xcfraud cfemale cakan cmarried cage cEducAny cMMoneyregistered, cluster(loccode)

**gen mismatches [& sortingX]?
bys Mkt: gen mismatch_Mktfemale=(cfemale != mfemale)
bys Mkt: gen mismatch_Mktakan=(cakan != makan)
bys Mkt: gen _MktEducHighM=(cEducAny < mEducAny)

reg cfAttempts mismatch_Mktfemale mismatch_Mktakan cmarried cage _MktEducHighM cMMoneyregistered, cluster(loccode)
reg _Xcfraud mismatch_Mktfemale mismatch_Mktakan cmarried cage _MktEducHighM cMMoneyregistered, cluster(loccode)


**poverty rate, by locality etc? 100% Nat. Pov
egen c_rScore = rowtotal(c2q1 - c2q10)
egen m_rScore = rowtotal(m4q1 - m4q10) 

//customers
gen c_pov_likelihood = 91.4 if (c_rScore>=0 & c_rScore<=9)
replace c_pov_likelihood =75.9 if (c_rScore>=10 & c_rScore<=14)
replace c_pov_likelihood =66.8 if (c_rScore>=15 & c_rScore<=19)
replace c_pov_likelihood =63.8 if (c_rScore>=20 & c_rScore<=24)
replace c_pov_likelihood =53.3 if (c_rScore>=25 & c_rScore<=29)
replace c_pov_likelihood =40.2 if (c_rScore>=30 & c_rScore<=34)
replace c_pov_likelihood =29.0 if (c_rScore>=35 & c_rScore<=39)
replace c_pov_likelihood =19.6 if (c_rScore>=40 & c_rScore<=44)
replace c_pov_likelihood =11.7 if (c_rScore>=45 & c_rScore<=49)
replace c_pov_likelihood =7.2 if (c_rScore>=50 & c_rScore<=54)
replace c_pov_likelihood =4.3 if (c_rScore>=55 & c_rScore<=59)
replace c_pov_likelihood =2.2 if (c_rScore>=60 & c_rScore<=64)
replace c_pov_likelihood =1.1 if (c_rScore>=65 & c_rScore<=69)
replace c_pov_likelihood =0.8 if (c_rScore>=70 & c_rScore<=74)
replace c_pov_likelihood =0.3 if (c_rScore>=75 & c_rScore<=79)
replace c_pov_likelihood =0.0 if (c_rScore>=80 & c_rScore<=100)

//merchants
gen m_pov_likelihood = 91.4 if (m_rScore>=0 & m_rScore<=9)
replace m_pov_likelihood =75.9 if (m_rScore>=10 & m_rScore<=14)
replace m_pov_likelihood =66.8 if (m_rScore>=15 & m_rScore<=19)
replace m_pov_likelihood =63.8 if (m_rScore>=20 & m_rScore<=24)
replace m_pov_likelihood =53.3 if (m_rScore>=25 & m_rScore<=29)
replace m_pov_likelihood =40.2 if (m_rScore>=30 & m_rScore<=34)
replace m_pov_likelihood =29.0 if (m_rScore>=35 & m_rScore<=39)
replace m_pov_likelihood =19.6 if (m_rScore>=40 & m_rScore<=44)
replace m_pov_likelihood =11.7 if (m_rScore>=45 & m_rScore<=49)
replace m_pov_likelihood =7.2 if (m_rScore>=50 & m_rScore<=54)
replace m_pov_likelihood =4.3 if (m_rScore>=55 & m_rScore<=59)
replace m_pov_likelihood =2.2 if (m_rScore>=60 & m_rScore<=64)
replace m_pov_likelihood =1.1 if (m_rScore>=65 & m_rScore<=69)
replace m_pov_likelihood =0.8 if (m_rScore>=70 & m_rScore<=74)
replace m_pov_likelihood =0.3 if (m_rScore>=75 & m_rScore<=79)
replace m_pov_likelihood =0.0 if (m_rScore>=80 & m_rScore<=100)


sum c_pov_likelihood m_pov_likelihood //13.9% vs 10.7% need weight? quasi-Census...
bys loccode: sum c_pov_likelihood m_pov_likelihood


bys loccode: gen Nf=_N if mfemale==1
bys loccode: gen Nm=_N if mfemale==0


**income brackets: 1->2
gen income_group= c1q7
hist income_group
bys loccode: egen vincome_group=mean(income_group) 
bys loccode: egen vincome_groupf=mean(income_group) if mfemale==1
bys loccode: egen vincome_groupm=mean(income_group) if mfemale==0

bys loccode: gen worse_incomeGp_FemaleV =(vincome_groupf < vincome_groupm)
bys loccode: gen worse_incomeGp_FemaleV15 =(vincome_groupf < 1.5*vincome_groupm) //to increase sample a bit, SEs later
sum vincome_group vincome_groupf vincome_groupm worse_incomeGp_FemaleV worse_incomeGp_FemaleV15


**indicator for loc where female-v-Poverty > male-v-Poverty
bys loccode: egen vpov_rate=mean(m_pov_likelihood) 
bys loccode: egen vpov_ratef=mean(m_pov_likelihood) if mfemale==1
bys loccode: egen vpov_ratem=mean(m_pov_likelihood) if mfemale==0

bys loccode: gen worse_pov_FemaleV =(vpov_ratef > vpov_ratem)
sum vpov_rate vpov_ratef vpov_ratem worse_pov_FemaleV


**baseline beliefs about misconduct?
gen base_belief_overcharge = (c8q3==1)
hist base_belief_overcharge
sum base_belief_overcharge
bys loccode: egen ocbase_belief_overcharge=mean(base_belief_overcharge) 
bys loccode: egen fcbase_belief_overcharge=mean(base_belief_overcharge) if cfemale==1
bys loccode: egen mcbase_belief_overcharge=mean(base_belief_overcharge) if cfemale==0

hist ocbase_belief_overcharge
hist fcbase_belief_overcharge
hist mcbase_belief_overcharge


sum ocbase_belief_overcharge, d
bys loccode: gen under_bbelief = (ocbase_belief_overcharge < 0.388) //less than overall median belief
tab under_bbelief

bys loccode: gen under_bbelief_fc = (fcbase_belief_overcharge < mcbase_belief_overcharge)
tab under_bbelief_fc

**Get unique vender (aka Mkt) ID?
egen universalid = concat(loccode vendor_id)

// drop loccode vendor_id
order ge01 ge02 ge03 ge04

saveold "$dta_loc_repl/01_intermediate/Mkt_fieldData_census", replace






