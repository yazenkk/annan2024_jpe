/*
Title: followup surveys [Managers + controlVendos], JPE Revision

Input:
	- _project/_xREPUTATION/_submission/JPE/surveys-followups/
		- organized_surveys_cVENDORS_xlsx.xlsx
		- organized_surveys_MANAGERS.xlsx
Output:
	Data:
	- _project/_xREPUTATION/_submission/JPE/surveys-followups/revision_results/
		- vendors_maindata_p
		- vendors_maindata_q
		- vendors_maindata_elas
		- managers_maindata_p
		- managers_maindata_q
	Graphs:
		- vendors_misconduct_hypothesis_graph.gph
		- vendors_inadequateCampaigns_hypotheses_graph
		- vendors_beliefs_prices_graph.eps
		- vendors_pForecast.gph
		- vendors_qForecast.gph
		- vendors_pXqForecast.eps
		- vendors_elasForecast.eps
		- managersXvendors_misconduct_hypothesis_graph.eps
		- managersXvendors_inadequateCampaigns_hypotheses_graph.eps
		- managers_pForecast.gph
		- managers_qForecast.gph
		- managers_pXqForecast.eps		
		
[Confirm how to run statsby command]
*/


********************
*Vendors Perspective
********************
use "$dta_loc_repl/00_raw_anon/organized_surveys_cVENDORS_xlsx", clear

** Figure B.11 -----------------------------------------------------------------
*1. Why pre-experment overcharging? we advance a number of hypothesis 
*[based on focus market group discussions + baseline data descriptives + reviewer suggestions], top 1-4 (out of 9 hyp) are:
*(i) uninformed customers [formally evaluated above - 3 highs]
*(ii=) low vendor commissions so, overcharging is a short-run incentive to rip off consumers
*(ii=) inadequate campaign in rural areas by provider MTN ...[formally evaluated now - why descriptively? + below - sect YY: mtn why not tackle if profitable]
*(ii=) possibly misgueded firm beliefs about pricing...[formally evaluated below - sect YY: v why if not "too" profitable]
*others include: (v) limited competition [survey+data cut] + (vi) perceived cost of misconduct is low [survey], including weak agency relation b/n vendors and provider (r=vii), limited consumer search aka "Ghanaians don't like change" (r=viii) and heterogeneity (r=ix)
**these are all plausbisible, we dont have enough evidence to neither advance nor separate them**
**yet, as shown here and above, the issue of "uninformed consumers", which in itself exacebates the effects from other possible hypothesis and though not the only pluasible hypothesis, is very crucial -- hence the "focus of experiment"

*summarizing approach:
**we recoded the rankings to get a rank of 1 achieve the highest score
**for each hypothesis (column), cal. total ranking (=scores) across all respondents, then plot - scores for each hypothesis*

gr bar (sum) QL1_1-QL1_9, //top 1-4: here: uninformed consumers>>low commissions>limited campaings>misguided vendor beliefs>competition>low perceived cost
foreach var of varlist QL1_1 QL1_2 QL1_3 QL1_4 QL1_5 QL1_6{
	recode `var' 1=9 2=8 3=7 4=6 5=5 9=1 8=2 7=3 6=4, gen(rec_`var')
}
*
graph hbar (sum) rec_QL1_1 - rec_QL1_6, nofill asyvars ///
 blabel(group, position(inside) format(%4.0f) box fcolor(white) lcolor(white)) ytitle("Why Misconduct: Rank scores for possible hypotheses", size(vsmall)) blabel(bar) ///
 legend(pos(4) row(6) stack label(1 "Inadequate campaigns by provider MTN in rural areas") label(2 "Poorly informed consumers - prices and redress channels") label(3 "Possibly misguided vendor beliefs about pricing") label(4 "Low vendor commissions as short-run incentive") label(5 "Limited competition - vendor options and alternatives") label(6 "Low perceived cost of misconduct") size(tiny)) note(" " "{bf:Vendors views}, [N=58 Vendors]")
*gr export "$dta_loc/_project/_xREPUTATION/_submission/JPE/surveys-followups/revision_results/vendors_misconduct_hypothesis_graph.eps", replace
gr save "$output_loc/followup/vendors_misconduct_hypothesis_graph.gph", replace


** Figure C.2 ------------------------------------------------------------------
*2a...then why MTN hasnt - survey evidence?
gr bar QL2_1 QL2_2 QL2_3 QL2_4 //top 1 (out of 4 reasons): Too costly (+ lack of workable sol that can scale in rural areas[evaluated in sect YY])
foreach var of varlist QL2_1 QL2_2 QL2_3 QL2_4{
	recode `var' 1=4 2=3 4=1 3=2, gen(rec_`var')
}
*
graph hbar (sum) rec_QL2_1 - rec_QL2_4, nofill asyvars ///
 blabel(group, position(inside) format(%4.0f) box fcolor(white) lcolor(white)) ytitle("Why Inadequate Campaigns: Rank scores for reasons", size(vsmall)) blabel(bar) ///
 legend(pos(4) row(6) stack label(1 "Too costly to deliver rural anti-overcharging campaigns") label(2 "MTN is not aware of vendors overcharging in rural areas") label(3 "Too many vendors  to come up with workable solutions at scale") label(4 "MTN do not care") size(tiny)) note(" " "{bf:Vendors views}, [N=58 Vendors]")
*gr export "$dta_loc/_project/_xREPUTATION/_submission/JPE/surveys-followups/revision_results/vendors_inadequateCampaigns_hypotheses_graph.eps", replace
gr save "$output_loc/followup/vendors_inadequateCampaigns_hypotheses_graph.gph", replace


** Figure C.1 ------------------------------------------------------------------
**2b: possibly misguided firm beliefs about pricing...[formal evaluation]
**(a)cVendors subjective beliefs about profit-max prices: QP1 QP2 QP3
tab QP1, miss //most vendors 59% perceive (higher_p, lowQ >> lower_p, highQ), n=58
gen higher_p=(QP1=="1")
gen lower_p=(QP1=="2")
tab higher_p 
tab lower_p
sum higher_p lower_p
ttesti 58 0.59 0.49 58 0.41 0.49 //pval=0.0503
ttest higher_p == lower_p, unpaired //pval=0.0642

graph hbar higher_p lower_p, bar(1, color(black)) bar(2, color(gs8)) nofill asyvars ///
 blabel(group, position(inside) format(%4.2f) box fcolor(white) lcolor(white)) ytitle("Beliefs about Profit-Maximizing Prices: Share indicating higher vs lower price", size(small)) blabel(bar) ///
 legend(pos(7) row(1) stack label(1 "Higher price") label(2 "Lower price"))
gr export "$output_loc/followup/vendors_beliefs_prices_graph.eps", replace



**(b)cVendors predictions of mkt-level te(p,d) of information interventions
***************************************************************************
*QT1_1 (0/1 overcharge?) 
*QT1_2 (amt overcharge?)
*QT1_3 (amt consumer's usage, weekly?)
*QT1_4 (amt vendor's sales, daily?)
*To ease the presentation / exposition: I focus: 0/1 overcgaring (p) and amt consumer demand (q)
*results extend easily to amt overcharging and sales revenues and available upon request...

destring QT1_1, generate(QT1_1num) ignore(%) //trt 1 0/1
destring QT1_2, generate(QT1_2num) ignore(%) //trt 1 amt GHS = 0/1 SAME PREDICTIONS, OK
destring QT1_3, generate(QT1_3num) ignore(%)

replace QT2_1 = "-75%" if QT2_1=="-.75" //data entry error//
replace QT2_3 = "-75%" if QT2_1=="-.75" //data entry error//
destring QT2_1, generate(QT2_1num) ignore(%) //trt 2 0/1
destring QT2_2, generate(QT2_2num) ignore(%) //trt 2 amt GHS = 0/1 SAME PREDICTIONS, OK
destring QT2_3, generate(QT2_3num) ignore(%)

replace QT3_1 = "-75%" if QT3_1=="-.75" //data entry error//
replace QT3_3 = "-75%" if QT3_1=="-.75" //data entry error//
destring QT3_1, generate(QT3_1num) ignore(%) //trt 3 0/1
destring QT3_2, generate(QT3_2num) ignore(%) //trt 3 amt GHS = 0/1 SAME PREDICTIONS, OK
destring QT3_3, generate(QT3_3num) ignore(%)

*??elasticity at individual level???*
gen elas1_num =abs(QT1_3num/QT1_1num)
gen elas2_num =abs(QT2_3num/QT2_1num)
gen elas3_num =abs(QT3_3num/QT3_1num)


******************
*p* in long format
******************
preserve
	keep QT1_1num QT2_1num QT3_1num
	gen id = _n
	reshape long QT, i(id) j(trt) string
	replace trt="1" if trt=="1_1num"
	replace trt="2" if trt=="2_1num"
	replace trt="3" if trt=="3_1num"
	destring trt, replace

	saveold "$dta_loc_repl/01_intermediate/vendors_maindata_p", replace

	use "$dta_loc_repl/01_intermediate/vendors_maindata_p", clear
	statsby, by(trt): ci QT
	label define lbl 1 "Price Transparency" 2 "Monitor & Report" 3 "Joint: PT + MR"
	label value trt lbl
	levelsof trt, local(levels)
	twoway bar mean trt, barw(0.8) bfcolor(green*0.2) ylab(0(-10)-70) yline(0, lp(dash)) || rcap lb ub trt, xlabel(`levels', valuelabel angle(45) labsize(small)) scheme(s1color) legend(off) ytitle("Forecasted treatment effect (%)", size(med)) xtitle("Treatment program") note(" " "{bf:Prices:} Misconduct: 0-1, [N=58 Vendors]" "{bf:Observed Treatment Effects:}" "PT= -62%, MR= -73%, Joint= -72%; [Pooled= -72%]", position(7))
	gr save "$output_loc/followup/vendors_pForecast.gph", replace
restore


******************
*q* in long format
******************
preserve
	keep QT1_3num QT2_3num QT3_3num
	gen id = _n
	reshape long QT, i(id) j(trt) string
	replace trt="1" if trt=="1_3num"
	replace trt="2" if trt=="2_3num"
	replace trt="3" if trt=="3_3num"
	destring trt, replace

	saveold "$dta_loc_repl/01_intermediate/vendors_maindata_q", replace

	statsby, by(trt): ci QT
	label define lbl 1 "Price Transparency" 2 "Monitor & Report" 3 "Joint: PT + MR"
	label value trt lbl
	levelsof trt, local(levels)

	twoway bar mean trt, barw(0.8) bfcolor(green*0.2) ylab(-2(2)10) yline(0, lp(dash)) || rcap lb ub trt, xlabel(`levels', valuelabel angle(45) labsize(small)) scheme(s1color) legend(off) ytitle("Forecasted treatment effect (%)", size(med)) xtitle("Treatment program") note(" " "{bf:Quantities:} Consumer Transactions (weekly), [N=58 Vendors]" "{bf:Observed Treatment Effects:}" "PT= +26%, MR= +58%, Joint= +54%; [Pooled= +45%]", position(7))
	gr save "$output_loc/followup/vendors_qForecast.gph", replace
restore

*vendors: (p,q) combined....
****************************
gr combine "$output_loc/followup/vendors_pForecast.gph" ///
			"$output_loc/followup/vendors_qForecast.gph"
gr export "$output_loc/followup/vendors_pXqForecast.eps", replace
*p details
tab QT1_1num //36% vendors = 0 effect
tab QT2_1num //0% vendors = 0 effect
tab QT3_1num //0% vendors = 0 effect
*q details
tab QT1_3num //95% vendors = 0 effect
tab QT2_3num //91% vendors = 0 effect
tab QT3_3num //85% vendors = 0 effect
*overall -- incorrect forecasts; but correct in direction + trends;  predict large impacts on p (assuring) but doesn't rise to observed very large effect sizes; predict very small to no impacts on q (incorrect and very far from observed) -> incorrectly predicting q'(p)
*hence -- make's sense why they may subjectively believe overcharging (higer p) is better (b/c they can't predict q'(p) well, an ingredient in setting prices or markups)


**ELASTICITY**
******************
*q* in long format
******************
preserve
	keep elas1_num elas2_num elas3_num
	gen id = _n
	reshape long elas, i(id) j(trt) string
	replace trt="1" if trt=="1_num"
	replace trt="2" if trt=="2_num"
	replace trt="3" if trt=="3_num"
	destring trt, replace
	sum elas

	saveold "$dta_loc_repl/01_intermediate/vendors_maindata_elas", replace

	statsby, by(trt): ci elas
	label define lbl 1 "Price Transparency" 2 "Monitor & Report" 3 "Joint: PT + MR"
	label value trt lbl
	levelsof trt, local(levels)

	twoway bar mean trt, barw(0.8) bfcolor(green*0.2)  yline(0, lp(dash)) || rcap lb ub trt, xlabel(`levels', valuelabel angle(45) labsize(small)) scheme(s1color) legend(off) ytitle("Forecasted elasticity", size(med)) xtitle("Treatment program") note(" " "{bf:Elasticity:} % Quantity / % Price, [N=58 Vendors]" "{bf:Observed Elasticity:}" "PT= 0.65, MR= 1.45, Joint= 1.35; [Pooled= 1.13]", position(7))
	gr export "$output_loc/followup/vendors_elasForecast.eps", replace
	gr save "$output_loc/followup/vendors_elasForecast.gph", replace
restore





**********************
*Managers Perspective
**********************
clear all
use "$dta_loc_repl/00_raw_anon/organized_surveys_MANAGERS", clear

*1. Why pre-experment overcharging? we advance a number of hypothesis 
gr bar (sum) QL1_1-QL1_9 //here: top 1-4: uninformed consumers>misguided vendor beliefs>limited campaings>low commissions>competition>low perceived cost
*key 1: vendors top 4 ranking preserved (e.g., uninformed consumers #1), except that misguided beliefs now ranked much higher (#2), all else equal
*key 2: overall rankings invariate to different aggragation approaches: median scores, mean scores
foreach var of varlist QL1_1 QL1_2 QL1_3 QL1_4 QL1_5 QL1_6{
	recode `var' 1=9 2=8 3=7 4=6 5=5 9=1 8=2 7=3 6=4, gen(rec_`var')
}
*
graph hbar (sum) rec_QL1_1 - rec_QL1_6, nofill asyvars ///
 blabel(group, position(inside) format(%4.0f) box fcolor(white) lcolor(white)) ytitle("Why Misconduct: Rank scores for possible hypotheses", size(vsmall)) blabel(bar) ///
 legend(pos(4) row(6) stack label(1 "Inadequate campaigns by provider MTN in rural areas") label(2 "Poorly informed consumers - prices and redress channels") label(3 "Possibly misguided vendor beliefs about pricing") label(4 "Low vendor commissions as short-run incentive") label(5 "Limited competition - vendor options and alternatives") label(6 "Low perceived cost of misconduct") size(tiny)) note(" " "{bf:Managers views}, [N=29 Managers]")
gr export "$output_loc/followup/managers_misconduct_hypothesis_graph.eps", replace
gr save "$output_loc/followup/managers_misconduct_hypothesis_graph.gph", replace

*combine [managers + vendors]: why pre-experiment....
gr combine "$output_loc/followup/managers_misconduct_hypothesis_graph.gph" ///
			"$output_loc/followup/vendors_misconduct_hypothesis_graph.gph"
gr export "$output_loc/followup/managersXvendors_misconduct_hypothesis_graph.eps", replace


*2a...then why MTN hasnt - survey evidence?
gr bar QL2_1 QL2_2 QL2_3 QL2_4 //top 1: Too costly (+ lack of workable sol that can scale in rural areas[evaluated in sect YY])
*key 1: rankings fully preserved, same across vendors and mamagers
foreach var of varlist QL2_1 QL2_2 QL2_3 QL2_4{
	recode `var' 1=4 2=3 4=1 3=2, gen(rec_`var')
}
*
graph hbar (sum) rec_QL2_1 - rec_QL2_4, nofill asyvars ///
 blabel(group, position(inside) format(%4.0f) box fcolor(white) lcolor(white)) ytitle("Why Inadequate Campaigns: Rank scores for reasons", size(vsmall)) blabel(bar) ///
 legend(pos(4) row(6) stack label(1 "Too costly to deliver rural anti-overcharging campaigns") label(2 "MTN is not aware of vendors overcharging in rural areas") label(3 "Too many vendors  to come up with workable solutions at scale") label(4 "MTN do not care") size(tiny)) note(" " "{bf:Managers views}, [N=29 Managers]")
gr export "$output_loc/followup/managers_inadequateCampaigns_hypotheses_graph.eps", replace
gr save "$output_loc/followup/managers_inadequateCampaigns_hypotheses_graph.gph", replace

*combine [managers + vendors]: why MTN hasnt....
gr combine "$output_loc/followup/managers_inadequateCampaigns_hypotheses_graph.gph" ///
			"$output_loc/followup/vendors_inadequateCampaigns_hypotheses_graph.gph"
gr export "$output_loc/followup/managersXvendors_inadequateCampaigns_hypotheses_graph.eps", replace


**2b. why MTN hasnt....Or manager's hasnt [formal evaluation]
**(a) Managers predictions of mkt-level te(p,d) of information interventions
****************************************************************************
*QT1_1 (0/1 overcharge?) 
*QT1_2 (amt overcharge?)
*QT1_3 (amt consumer's usage, weekly?)
*QT1_4 (amt vendor's sales, daily?)
*To ease the presentation / exposition: I focus: 0/1 overcgaring (p) and amt consumer demand (q)
*results extend easily to amt overcharging and sales revenues and available upon request...

destring QT1_1, generate(QT1_1num) ignore(%) //trt 1
destring QT1_3, generate(QT1_3num) ignore(%)

destring QT2_1, generate(QT2_1num) ignore(%) //trt 2
destring QT2_3, generate(QT2_3num) ignore(%)

destring QT3_1, generate(QT3_1num) ignore(%) //trt 3
destring QT3_3, generate(QT3_3num) ignore(%)

******************
*p* in long format
******************
preserve
	keep QT1_1num QT2_1num QT3_1num
	gen id = _n
	reshape long QT, i(id) j(trt) string
	replace trt="1" if trt=="1_1num"
	replace trt="2" if trt=="2_1num"
	replace trt="3" if trt=="3_1num"
	destring trt, replace

	saveold "$dta_loc_repl/01_intermediate/managers_maindata_p", replace

	statsby, by(trt): ci QT
	label define lbl 1 "Price Transparency" 2 "Monitor & Report" 3 "Joint: PT + MR"
	label value trt lbl
	levelsof trt, local(levels)
	twoway bar mean trt, barw(0.8) bfcolor(green*0.2)  yline(0, lp(dash)) || rcap lb ub trt, xlabel(`levels', valuelabel angle(45) labsize(small)) scheme(s1color) legend(off) ytitle("Forecasted treatment effect (%)", size(med)) xtitle("Treatment program") note(" " "{bf:Prices:} Misconduct: 0-1, [N=29 Managers]" "{bf:Observed Treatment Effects:}" "PT= -62%, MR= -73, Joint= -72%; [Pooled= -72%]", position(7))
	gr save "$output_loc/followup/managers_pForecast.gph", replace
restore

******************
*q* in long format
******************
preserve
	keep QT1_3num QT2_3num QT3_3num
	gen id = _n
	reshape long QT, i(id) j(trt) string
	replace trt="1" if trt=="1_3num"
	replace trt="2" if trt=="2_3num"
	replace trt="3" if trt=="3_3num"
	destring trt, replace

	saveold "$dta_loc_repl/01_intermediate/managers_maindata_q", replace

	statsby, by(trt): ci QT
	label define lbl 1 "Price Transparency" 2 "Monitor & Report" 3 "Joint: PT + MR"
	label value trt lbl
	levelsof trt, local(levels)

	twoway bar mean trt, barw(0.8) bfcolor(green*0.2) yline(0, lp(dash)) || rcap lb ub trt, xlabel(`levels', valuelabel angle(45) labsize(small)) scheme(s1color) legend(off) ytitle("Forecasted treatment effect (%)", size(med)) xtitle("Treatment program") note(" " "{bf:Quantities:} Consumer Transactions (weekly), [N=29 Managers]" "{bf:Observed Treatment Effects:}" "PT= +26%, MR= +58%, Joint= +54%; [Pooled= +45%]", position(7))
	gr save "$output_loc/followup/managers_qForecast.gph", replace
restore

*managers: (p,q) combined....
*****************************
gr combine "$output_loc/followup/managers_pForecast.gph" ///
			"$output_loc/followup/managers_qForecast.gph"
gr export "$output_loc/followup/managers_pXqForecast.eps", replace
*p details
tab QT1_1num //52% managers = 0 effect
tab QT2_1num //45% managers = 0 effect
tab QT3_1num //38% managers = 0 effect
*q details
tab QT1_3num //72% managers = 0 effect
tab QT2_3num //65% managers = 0 effect
tab QT3_3num //55% managers = 0 effect
*overall -- systematically incorrect forecasts, in some cases - direction + trends are incorrect /opposite -- for both p and q; (all average forecasts doesn't rise to observed te's very large effect sizes); 
*hence -- make's sense why they haven't explored similar 2 sided information interventions (though could be profitable to provider MTN), why dont know?: perhaps due to lack of past evidence that these programs work. we are confidence this ll open opportunity for takeup and scaleup by MTN




