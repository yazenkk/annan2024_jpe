/*
Generate adminTransactData

Input:
	- repMkt_w_xtics
	- FFaudit
Output:
	- adminTransactData
	
[Confirm: should we include this]
[Remove unneeded comments]

*/


use "$dta_loc_repl/01_intermediate/repMkt_w_xtics", clear
gen belief=1
drop _merge
keep if sample_repMkt==1
bys ge02 ge03: keep if _n==1
drop text* // text_ge* vars used below from FFaudit data

tempfile repMkt_w_VendorXtics
save 	`repMkt_w_VendorXtics'
saveold "$dta_loc_repl/01_intermediate/repMkt_w_VendorXtics", replace


	
use "$dta_loc_repl/00_raw_anon/FFaudit.dta", clear

bys ge02 ge03: gen xx=_N
tab xx
tab login

merge 1:1 ge02 ge03 using `repMkt_w_VendorXtics'
keep if _merge ==3

tab login
gen gender_auditor=.
replace gender_auditor = 1 if (login==11) 
replace gender_auditor = 1 if (login==21) 
replace gender_auditor = 0 if (login==31) 
replace gender_auditor = 0 if (login==41) 
tab gender_auditor


gen female=(ffaq12==2)
replace female=. if missing(ffaq12)
replace gender_auditor =. if missing(female)

gen tarrifpost=(ffaq9==1)
replace tarrifpost=. if missing(ffaq9)

gen otherbus=(ffaq13==1)
replace otherbus=. if missing(ffaq13)

**gender/matching frictions?
gen gmatch=(female==gender_auditor)
replace gmatch=. if missing(female)

**correctly: reshape data from wide to long -- randomization of transactions
reshape long ffaq5_ ffaq6_ ffaq8_ ffaq0_, i(ge02) j(transact)  string

**liquidy shortfalls?
tab ffaq0_ //47% of transactions unsuccessful
tab status //reason: 11% of transactions=no cash in wallet

**fin misconduct or fin-fraud?
egen distrFes = group(ge01)
egen vFes = group(ge02) //within-person?
egen trFes = group(transact) //within-transaction?

**some xtics?
gen vAge= m1q4
gen vMarried=(m1q3==2)
gen vYrsInbus =m2q1a
gen vSizebus =m2q4b

**knowlegeable merchants vs non-k
gen soph_m = (m_deviations==0)
gen soph_c = (c_deviations==0)

*keep ffaudits_id transact ffaq1 ffaq3 ffaq5_ ffaq6_ ffaq8_ gender_auditor female tarrifpost otherbus gmatch trFes trXdateFes
gen fYes_T = (ffaq5_==1)
	replace fYes_T=. if missing(ffaq5_)
gen fAmt_T = ffaq6_
	replace fAmt_T=. if missing(ffaq6_)
	replace fAmt_T=fAmt_T/10 if fAmt_T>10	//an adjustments from the field
gen wTime_T = ffaq8_
	replace wTime_T=. if missing(ffaq8_)
	
**group/ class transactions?
gen tranType = " "
replace tranType = "OTC-base: 01-03" if (transact=="01" | transact=="02" | transact=="03")
replace tranType = "OTC-token: 04-07" if (transact=="04" | transact=="05" | transact=="06" | transact=="07")
replace tranType = "Falsification: 08-10" if (transact=="08" | transact=="09" | transact=="10")
replace tranType = "Open-account: 11-12" if (transact=="11" | transact=="12")

gen round = 1
drop _merge

**misconduct: summaries?
gen sv_fAmt_T = fAmt_T

gen transactK = transact
replace transactK ="01 Cash-in GHS50 - others wallet" if transact=="01"
replace transactK ="02 Cash-in GHS160 - others wallet" if transact=="02"
replace transactK ="03 Cash-in GHS1100 - others wallet" if transact=="03"
replace transactK ="04 Send GHS50 token - others" if transact=="04"
replace transactK ="05 Send GHS1100 token - others" if transact=="05"
replace transactK ="06 Receive GHS50 token" if transact=="06"
replace transactK ="07 Receive GHS1100 token" if transact=="07"
replace transactK ="08 Cash-in GHS50 - own wallet" if transact=="08"
replace transactK ="09 Cash-in GHS160 - own wallet" if transact=="09"
replace transactK ="10 Cash-out GHS50 - own wallet" if transact=="10"
replace transactK ="11 Purchase new SIM card" if transact=="11"
replace transactK ="12 Register new M-Money wallet" if transact=="12"

**QUESTION?
**(intentional) misconduct or (innocent) errors? 
**then should see average = 0 rel to mandated rate, and no asymmetry
gen devAmt = fAmt_T
replace devAmt=0 if fYes_T==0


**Indentif Strategy: Confounds?: intuition
**I] Between results: Fes here capture unob diffs based on loc. / transact Cycles / (robustly) transact Type?
**comparing two M-M transactions carried out within the same day and district (or village-rep's comparable)**


save "$dta_loc_repl/01_intermediate/adminTransactData", replace


**quantifying: "Bias belief vs direct Price Effects"? 
*2. bring in objective misconduct at t0?
**intermediate step- get baseline objective fraud
** Source: Stats?/Commands_Test_f_evaluation_consumers.do

tab fYes_T
gen sv_fAmt_T0 = sv_fAmt_T
replace sv_fAmt_T0=0 if fYes_T==0

** These calculations, unlike merges above, are done using text IDs
bys text_ge01 text_ge02: egen obj_fd_t0 = mean(fYes_T) //continuous, measure mkt=rep.vendor
replace obj_fd_t0 = obj_fd_t0*100 
bys text_ge01 text_ge02: egen obj_fdamt_t0 = mean(sv_fAmt_T0) //continuous, mkt=rep.vendor
pwcorr obj_fd_t0 obj_fdamt_t0, sig

bys text_ge01 text_ge02: keep if _n==1
hist obj_fd_t0, frac
hist obj_fdamt_t0, frac
sum obj_fd_t0 obj_fdamt_t0, d
gen fdH0_t0 = (obj_fd_t0>0) if !missing(obj_fd_t0) //binary measure (above 0%)
gen fdH1_t0 = (obj_fd_t0>20) if !missing(obj_fd_t0) //binary (above median=20% vs endl=14.2%)
gen fdamtH0_t0 = (obj_fdamt_t0>0) if !missing(obj_fdamt_t0)
gen fdamtH1_t0 = (obj_fdamt_t0>0.708) if !missing(obj_fdamt_t0) //(above median=0.708ghS vs endl=0.412ghS)
keep text_ge01 text_ge02 obj_fd_t0 obj_fdamt_t0 fdH* fdamtH*
isid text_ge01 text_ge02

saveold "$dta_loc_repl/01_intermediate/ofdrate_mktadminTransactData", replace

