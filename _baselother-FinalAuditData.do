/*
Vendors/Customers: estimate locality-level fraud rates(objective), 
then combine with customers estimates(subjective)

Source: 
Input:
	- analyzed_EndlineAuditData
Output:
	- ofdrate_mktAudit_endline
*/

use "$dta_loc_repl/00_raw_anon/analyzed_EndlineAuditData.dta", clear
keep if _merge==3 //get rep vendors
bys ge01 ge02: egen obj_fd = mean(fd) //continuous measure
replace obj_fd = obj_fd*100 
bys ge01 ge02: egen obj_fdamt = mean(fdamt) //continuous
pwcorr obj_fd obj_fdamt, sig

sort ge01 ge02
// br ge0* fd fdamt fYes_T fAmt_T sv_fAmt_T
bys ge01 ge02: keep if _n==1
hist obj_fd, frac
hist obj_fdamt, frac
sum obj_fd obj_fdamt, d
gen fdH0 = (obj_fd>0) if !missing(obj_fd) //binary measure (above 0%)
gen fdH1 = (obj_fd>14.28) if !missing(obj_fd) //binary (above median=14.28%)
gen fdamtH0 = (obj_fdamt>0) if !missing(obj_fdamt)
gen fdamtH1 = (obj_fdamt>0.142) if !missing(obj_fdamt)
keep ge01 ge02 ge03 obj_fd obj_fdamt fdH* fdamtH*
sort ge01 ge02 ge03

saveold "$dta_loc_repl/01_intermediate/ofdrate_mktAudit_endline.dta", replace
