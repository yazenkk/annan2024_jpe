/*
Generate mkt_aiVendorBetter
Input: 
	- Mkt_fieldData_census
Output:
	- mkt_aiVendorBetter
*/

**Xavi - why spillovers?
*either (i) communication (v*-v, c*-c)? or (ii) shopping around (c*-v)?
*dependence on degree of AI?


use "$dta_loc_repl/01_intermediate/Mkt_fieldData_census", clear

**Asymmetric Tnformation Test**
bys ge02: egen mkt_m_corrects2 = mean(m_corrects)
bys ge02: egen mkt_c_corrects2 = mean(c_corrects)

bys ge02: egen mkt_c_fracAnyEduc = mean(cEducAny)
bys ge02: egen mkt_c_avgEducLevel = mean(cEduc)
gen primandlesssEduc = (cEduc<=2) if !missing(cEduc)
bys ge02: egen mkt_c_fracprimandlesssEduc = mean(primandlesssEduc)

bys ge02: keep if _n==1
bys ge02: gen mkt_aigap = mkt_m_corrects2-mkt_c_corrects2
bys ge02: gen mkt_aiVendorBetter = (mkt_m_corrects2>mkt_c_corrects2) if !missing(mkt_aigap)

bys ge02: gen x=_N
rename locality_name locality_nameBase
keep mkt_aigap mkt_aiVendorBetter mkt_c_corrects2 mkt_m_corrects2 ///
	 mkt_c_fracAnyEduc mkt_c_avgEducLevel mkt_c_fracprimandlesssEduc ///
	 text_ge02 locality_nameBase x // loccode ln

// drop if text_ge02 == .

saveold "$dta_loc_repl/01_intermediate/mkt_aiVendorBetter.dta", replace
