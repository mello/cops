clear all
cap log close
set more off


***********************************
/// PART 1: SETUP DATA ////
***********************************

use ../data/cops, clear

// ATTACH ANNUAL ARRA FUNDING //
merge 1:1 ori year using ../data/arra, keep(1 3)

// NOTE SAMPLE WITH ARRA DATA //
bysort ori: egen ARRASAMPLE=max(_m==3)
drop _m

// ARRA CONTROL: LOG ARRA FUNDING PER CAPITA ///
replace local_nonDoj=0 if mi(local_nonDoj)&ARRASAMPLE==1
gen larrart=log((local_nonDoj+1)/pop)


// OTHER DATA SETUP //
global cov="logpci unemprt pct*"
egen X=group(bin year)



***********************************
/// PART 2: REGRESSIONS ////
***********************************

/// CLEAR OUT ESTSTO ///
eststo clear

// STORE NUM CITIES (ALL) //
egen XID=group(ori)
summ XID
local NCITY=r(max)
drop XID

// STORE NUM CITIES (WITH ARRA DATA) //
egen XID=group(ori) if ARRASAMPLE==1
summ XID
local NCITYARRA=r(max)
drop XID


/// REG 1: CRIME-POLICE FOR FULL SAMPLE ///
eststo: reghdfe costrt $cov (swornrt=high_post), absorb(i.id i.X i.id#c.year) vce(cluster id)
local f=round(e(widstat),.01)
qui estadd local fStat `f'
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local arra "No"
qui estadd local ncluster `NCITY'


/// REG 2: CRIME-POLICE FOR ARRA SAMPLE ///
eststo: reghdfe costrt $cov (swornrt=high_post) if ARRASAMPLE==1, absorb(i.id i.X i.id#c.year) vce(cluster id)
local f=round(e(widstat),.01)
qui estadd local fStat `f'
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local arra "No"
qui estadd local ncluster `NCITYARRA'


/// REG 3: CRIME-POLICE FOR ARRA SAMPLE WITH ARRA CONTROL ///
eststo: reghdfe costrt larrart $cov (swornrt=high_post) if ARRASAMPLE==1, absorb(i.id i.X i.id#c.year) vce(cluster id)
local f=round(e(widstat),.01)
qui estadd local fStat `f'
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local arra "Yes"
qui estadd local ncluster `NCITYARRA'



//// ESTAB ///
/// STORE AS .TXT FILE VIA LOG ///
/// UNCOMMENT BELOW TO GET LATEX TABLE ///
log using tab4.txt, text replace
#delimit ;
esttab, star(* .1 ** .05 *** .01) 
keep(swornrt) wrap varwidth(20) se 
stats(fStat ctl syfe trd arra ncluster N,
label("F-Stat" "Controls" "Size x Year Effects" "City Trends" "ARRA Spending"
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment 
mtitles("Crime" "Crime" "Crime") ;
#delimit cr
log close

/// ESTAB ///
/// LATEX FILE ///
/*
#delimit ;
esttab using tab4.tex, star(* .1 ** .05 *** .01) 
keep(swornrt) wrap varwidth(20) se 
stats(fStat ctl syfe trd arra ncluster N,
label("F-Stat" "Controls" "Size x Year Effects" "City Trends" "ARRA Spending"
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment replace 
mtitles("Crime" "Crime" "Crime") ;
#delimit cr
*/





