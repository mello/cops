clear all
cap log close
set more off


***********************************
/// PART 1: SETUP DATA ////
***********************************

/// CONSTRUCT UNEMPLOYMENT BINS ///
use ../data/cops, clear

// MEANS FOR PRE (2005-2007) AND POST (2008-2010) //
gen POST=.
replace POST=0 if year>=2005&year<=2007
replace POST=1 if year>=2008&year<=2010
drop if mi(POST)

// COLLAPSE //
collapse (mean) unemprt, by(ori bin POST)
reshape wide unemprt, i(ori bin) j(POST)

// COMPUTE DELTAS AND BINS FOR DELTAS //
gen DELTA=unemprt1-unemprt0
gen RANDOM=runiform()
binscatter RANDOM DELTA, nq(10) gen(rBIN) nodraw

// STORE AS TEMPFILE ///
keep ori rBIN
tempfile BIN
save `BIN'

/// ATTACH TO PANEL ///
use ../data/cops, clear
merge m:1 ori using `BIN', nogen

/// RECESSION BIN x YEAR EFFECTS //
egen rBINYEAR=group(rBIN year)



***********************************
/// PART 2: REGRESSIONS  ////
***********************************

// SETUP DATA //
global cov="logpci pct*"
egen X=group(bin year)

/// CLEAR OUT ESTSTO ///
eststo clear

// STORE NUMBER OF CITIES //
egen XID=group(ori)
summ XID
local NCITY=r(max)
drop XID


/// REG 1: REG UNEMPLOYMENT RATE ON INSTRUMENT //
eststo: reghdfe unemprt high_post, absorb(i.id i.X i.id#c.year) vce(cluster id)
qui estadd local fStat "-"
qui estadd local ctl "No"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local rbin "No"
qui estadd local ncluster `NCITY'

// REG 2: REG UNEMPLOYMENT RATE ON INSTRUMENT, RECESSION x YEAR EFFECTS ///
eststo: reghdfe unemprt high_post , absorb(i.id i.rBINYEAR i.id#c.year) vce(cluster id)
qui estadd local fStat "-"
qui estadd local ctl "No"
qui estadd local syfe "No"
qui estadd local rbin "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'

// REG 3: IV CRIME ON POLICE //
eststo: reghdfe costrt  (swornrt=high_post), absorb(i.id i.X i.id#c.year) vce(cluster id)
local f=round(e(widstat),.01)
qui estadd local fStat `f'
qui estadd local ctl "No"
qui estadd local syfe "Yes"
qui estadd local rbin "No"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'

// REG 4: IV CRIME ON POLICE, RECESSION x YEAR EFFECTS //
eststo: reghdfe costrt  (swornrt=high_post), absorb(i.id i.rBINYEAR i.id#c.year) vce(cluster id)
local f=round(e(widstat),.01)
qui estadd local fStat `f'
qui estadd local ctl "No"
qui estadd local syfe "No"
qui estadd local rbin "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'


//// ESTAB ///
/// STORE AS .TXT FILE VIA LOG ///
/// UNCOMMENT BELOW TO GET LATEX TABLE ///
log using tab3.txt, text replace
#delimit ;
esttab, star(* .1 ** .05 *** .01) 
keep(high_post swornrt) wrap varwidth(20) se 
stats(fStat ctl syfe rbin trd ncluster N,
label("F-Stat" "Controls" "Size x Year Effects" "Recession Decile x Year Effects" "City Trends"
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment
mtitles("UER x 100" "UER x 100" "IV: Crime" "IV: Crime") ;
#delimit cr
log close


/// ESTAB ///
/// LATEX FILE ///
/*
#delimit ;
esttab using tab3.tex, star(* .1 ** .05 *** .01) 
keep(high_post swornrt) wrap varwidth(20) se 
stats(fStat ctl syfe rbin trd ncluster N,
label("F-Stat" "Controls" "Size x Year Effects" "Recession Decile x Year Effects" "City Trends"
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment replace 
mtitles("UER x 100" "UER x 100" "IV: Crime" "IV: Crime") ;
#delimit cr
*/






