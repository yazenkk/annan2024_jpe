/*
Interventions at the customer level (merged here)

Input:
	- repMkt
	- _CM_all_2_18
	- ONLY_4TrtGroups_9dist
	
Output:
	- interventionsTomake_list_local
	
*/




**ONLY: dta for office-Officers: intervention seeders/planters
**launch to: only repVendors + only nearby-local? [all-global?] customers?
use "$dta_loc_repl/01_intermediate/repMkt.dta", clear
keep if sample_repMkt==1
keep ge02 ge03 
merge 1:m ge02 ge03 using  "$dta_loc_repl/00_raw_anon/_CM_all_2_18.dta"
*merge 1:m loccode using  "_CM_all_2_18.dta"
keep if _merge==3

bys loccode vendor_id: gen x=_N
tab x

**let's check? very good...
*bys loccode vendor_id: keep if _n==1
*br
keep ge02 ge03 ge04 custcode cn c1q0b c1q8a c1q8b
tempfile ONLY_repMkt
save 	`ONLY_repMkt'


use "$dta_loc_repl/01_intermediate/ONLY_4TrtGroups_9dist", clear
merge 1:m ge02 ge03 using `ONLY_repMkt', gen(_mrep)
bys ge02 ge03: gen xx=_N
tab xx //1-25 customers; only nearby customers that surround repMkt (not all in locality possibly)
sum xx
tab treatment //ctr=185c, pt=272, mr=257, joint=276

**label vendor side??
// label var vendor_id "vendor ID - unique only within locality"
label var vn "vendor name"

**label customer side??
gen customer_id = custcode
label var customer_id "customer ID - unique only within locality"
label var cn "customer name, nearby"
gen cDescribe = c1q0b
label var cDescribe "Describe location -- customer nearby"

**get things in strings for CAPI
*tostring loccode, gen(loccodex) format(%17.0g)


order ge01 districtName ge02 ln ///
	vn ge03 vDescribe ///
	cn customer_id cDescribe treatment

gen intervention =""
replace intervention="Control" if treatment==0
replace intervention="PriceTransparency, PT" if treatment==1
replace intervention="MKtMonitoring, MM" if treatment==2
replace intervention="joint: PT+MM" if treatment==3
label var intervention "intervention or treatment type to implement"

keep ge01 districtName ge02 ln ///
	vn ge03 vDescribe ///
	cn customer_id ge04 cDescribe treatment intervention 
	
** save
saveold "$dta_loc_repl/01_intermediate/interventionsTomake_list_local", replace

