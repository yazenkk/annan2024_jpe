/*
Interventions at the market-level (generated here)

Input:
	- repMkt
	- sel_9Distr_137Local_List
Output:
	- ONLY_4TrtGroups_9dist
*/


**ONLY: dta for field-Auditors: the 130 repMkts?
use "$dta_loc_repl/01_intermediate/repMkt", clear
tab sample_repMkt, miss
keep if sample_repMkt==1

merge 1:1 ge02 using "$dta_loc_repl/00_raw_anon/sel_9Distr_137Local_List"
keep if _merge==3

// label var ge03 "vendor ID - unique only within locality"
gen vDescribe = m1q0d
label var vDescribe "Describe location -- vendor"
label var sample_repMkt "indicator for randomly selected vendor to represent a locality, 1=Selected, 0=notSelected"

// gen districtID = ge01
// label var districtID "District code/ ID -- unique"


// tostring loccode, gen(loccodex) format(%17.0g)


order ge01 districtName ge02 ln vn ge03 vDescribe sample_repMkt
tab ge01
tab districtName

// randtreat, generate(treatment) replace unequal(1/4 1/4 1/4 1/4) strata(ge01) misfits(wstrata) setseed(12345)
randtreat, generate(treatment) replace unequal(1/4 1/4 1/4 1/4) strata(districtID) misfits(wstrata) setseed(12345)
tab treatment, miss
tab ge01 treatment
save "$dta_loc_repl/01_intermediate/ONLY_4TrtGroups_9dist", replace

