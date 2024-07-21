/*
Master file for _annan_MRIxrev01_May.21.2023.pdf
Date: 7/21/2024

*/

** Initialize
clear all
set graphics off
global myseed 100001
set seed $myseed // from scripts: demand, revenues
global bootstrap_reps 1000


** set globals
if c(username) == "yazenkashlan" {
	global dta_loc_repl "/Users/yazenkashlan/Library/CloudStorage/OneDrive-Personal/Documents/personal/Berk/03_Work/Francis/Replication/data_final"
	global do_loc 		"/Users/yazenkashlan/Documents/GitHub/annan2024_misconduct"
	global output_loc 	"/Users/yazenkashlan/Documents/GitHub/annan2024_misconduct/output"
}
if c(username) == "______" {
	** enter local do file locations
	global dta_loc ""
	global do_loc "" 
	global output_loc ""
}

** install programs
// do "$do_loc/01_programs"

** baseline data prep
do "$do_loc/_basel-Commands_Test_goodstuff" // generate Mkt_fieldData_census
do "$do_loc/_basel-gender" 					// generate pct_female_Mktcensus[Star]
do "$do_loc/_basel-repMkt" 					// generate repMkt_w[_xtics]

** treatment assigmnent
do "$do_loc/_basel-interventions1" 		// generate ONLY_4TrtGroups_9dist
do "$do_loc/_basel-interventions2" 		// generate interventionsTomake_list_local

** combine
do "$do_loc/_basel2-adminTransactData" 	// generate [ofdrate_]mktadminTransactData
do "$do_loc/_basel2-combine" 			// combine customer/merchant + int + mkt census (commented out sqreg and gen. item=y)
do "$do_loc/_basel2-mkt_ai" 		 	// generate mkt_aiVendorBetter
do "$do_loc/_baselother-FinalAuditData" // generate ofdrate_mktAudit_endline


version 10
do "$do_loc/_followups-organized_surveys"
version 18

** Main analysis
do "$do_loc/_BalanceTest_stratadummies.do" // quick
do "$do_loc/Beliefs_Mar.19.2023.do" // 1-ish minute
do "$do_loc/Demand_Mar.19.2023.do" // 5-ish minutes?
do "$do_loc/Misconduct_Mar.19.2023.do" // 5-ish minutes?
do "$do_loc/Revenues_Mar.19.2023.do" // 3-ish minutes?
do "$do_loc/Shocks_Mar.19.2023.do" // 2-ish minutes


