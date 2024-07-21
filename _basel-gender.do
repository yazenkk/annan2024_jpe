/*
Prepare data by gender

Input: 
	- Mkt_fieldData_census
	- sel_9Distr_137Local_List
Output:
	- pct_female_Mktcensus/Star

*/


**Mkt census: Get percent of femal vendors per locality; competition measure=hhi?
use "$dta_loc_repl/01_intermediate/Mkt_fieldData_census", clear
// gen double localityCode_j=loccode
drop _merge
merge m:1 ge02 using "$dta_loc_repl/00_Raw_anon/sel_9Distr_137Local_List"
keep if _merge==3

**all vendors per locality =137 all here**
bys ge01 ge02 ge03: keep if _n==1

**%of Female v's? Say, at least 3 vendors in locality
bys ge02: egen pct_female = mean(mfemale)
bys ge02: replace pct_female = pct_female*100

bys ge02: gen sN =_N
replace pct_female=. if sN <2
twoway histogram pct_female, frac ytitle("Fraction of localities") xtitle("% Female vendors per locality")
gr export "$output_loc/baseline/pct_female_hist.eps", replace


**Competition, hhi
gen dailyTotMoney2=m2q4b //can use monthly sale: m1q8--correlates very well? 
bys ge02: egen double sumdSales = sum(dailyTotMoney2)
bys ge02: gen double shsqrd = (dailyTotMoney2/sumdSales)^2 
bys ge02: egen double HHI=sum(shsqrd)
*hist HHI //clean later? yes. drop missings etc..

// gen ge01 =districtName
// gen ge02 =localityName 
// gen ge03 =vn
// gen double loccodee= loccode

keep pct_female HHI mfemale sN text_ge01 text_ge02 text_ge03 districtName localityName vn // loccode loccodee
// keep pct_female HHI mfemale loccode sN
*bys loccode: keep if _n==1

saveold "$dta_loc_repl/01_intermediate/pct_female_Mktcensus", replace
saveold "$dta_loc_repl/01_intermediate/pct_female_MktcensusStar", replace
