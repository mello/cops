clear all
cap log close
set more off


*****************************************
/// PREDICTED FIRER/HIRER STATUS //
*****************************************

/// GET 2008-2010 CHANGE IN POLICE ///
use ../data/cops, clear
bysort ori (year): gen logdiff=swornrt-swornrt[_n-2]
keep if year==2010

keep ori logdiff
tempfile TEMP
save `TEMP'


/// ATTACH CHANGES TO DATA ///
use ../data/cops, clear
keep if year==2008
merge 1:1 ori using `TEMP', nogen


/// ADJUST DIFF SO ONLY CONTROLS USED IN REGRESSION
gen logdiff_control=logdiff if high==0


/// REGRESSION ////
reg logdiff_control unemprt logpci pctblack pcthisp pctyoungmale i.bin 
predict deltahat


/// SPLIT THE SAMPLE ///
summ deltahat, d
gen hirer=(deltahat>r(p50))


/// STORE ///
keep ori hirer 
qui compress
tempfile SAMPLE
save `SAMPLE'



*****************************************
/// REGRESSIONS //
*****************************************

// READ DATA + ATTACH SAMPLE SPLIT DUMMY //
use ../data/cops, clear
merge m:1 ori using `SAMPLE', nogen


// DATA SETUP //
global cov="logpci unemprt pct*"
egen X=group(bin year)



******************************************
/// PART 1: USE FULLY INTERACTED MODEL ///
/// TO T-TEST COEFFICIENT DIFFERENCE   ///
******************************************

/// CONSTRUCT FULLY INTERACTED DATA ///
egen X_int=group(hirer bin year)

gen firer=(hirer==0)
gen swornrt_firer=swornrt*firer
gen swornrt_hirer=swornrt*hirer
gen high_post_firer=high_post*firer
gen high_post_hirer=high_post*hirer

local cov=""
foreach x in logpci unemprt pctblack pcthisp pctyoungmale {
	gen `x'_firer=`x'*firer
	local cov="`cov'"+" `x'_firer"
	gen `x'_hirer=`x'*hirer
	local cov="`cov'"+" `x'_hirer"
}


/// ESTIMATE MODEL ///
reghdfe costrt `cov' (swornrt_firer swornrt_hirer = high_post_firer high_post_hirer), ///
absorb(i.id i.X_int i.id#c.year) vce(cluster id)

// TEST EQUALITY AND STORE P-VALUE ///
test swornrt_firer=swornrt_hirer
local pDiff=round(r(p),.01)



*********************************************
/// PART 2: SEPARATE REGRESSIONS BY GROUP ///
/// (FOR REGRESSION TABLE) ///
*********************************************

/// CLEAR OUT ESTSTO ///
eststo clear



//// FIRERS ONLY ////
preserve
keep if hirer==0


egen XID=group(ori)
summ XID
local NCITY=r(max)
drop XID

summ swornrt if year==2004&abs(rel)<=1
local mX=round(r(mean),.01)
summ costrt if year==2004&abs(rel)<=1
local mY=round(r(mean),.01)


// GET FS COEFFICIENT ///
reghdfe swornrt high_post $cov, absorb(i.id i.X i.id#c.year) vce(cluster id)
local bfs=round(_b[high_post],.01)


// IV REGRESSION ///
eststo: reghdfe costrt $cov (swornrt=high_post), absorb(i.id i.X i.id#c.year) vce(cluster id)
local E=round(_b[swornrt]*(`mX'/`mY'),.01)
local fstat=round(e(widstat),.01)
qui estadd local pval "-"
qui estadd local mu `mY'
qui estadd local elast `E'
qui estadd local fbeta `bfs'
qui estadd local ff `fstat'
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'
restore



/// HIRERS ONLY ///
preserve
keep if hirer==1


egen XID=group(ori)
summ XID
local NCITY=r(max)
drop XID

summ swornrt if year==2004&abs(rel)<=1
local mX=round(r(mean),.01)
summ costrt if year==2004&abs(rel)<=1
local mY=round(r(mean),.01)


// GET FS COEFFICIENT ///
reghdfe swornrt high_post $cov, absorb(i.id i.X i.id#c.year) vce(cluster id)
local bfs=round(_b[high_post],.01)


// IV REGRESSION ///
eststo: reghdfe costrt $cov (swornrt=high_post), absorb(i.id i.X i.id#c.year) vce(cluster id)
local E=round(_b[swornrt]*(`mX'/`mY'),.01)
local fstat=round(e(widstat),.01)
qui estadd local pval `pDiff'
qui estadd local mu `mY'
qui estadd local elast `E'
qui estadd local fbeta `bfs'
qui estadd local ff `fstat'
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'
restore



/// ESTAB ///
//// ESTAB ///
/// STORE AS .TXT FILE VIA LOG ///
/// UNCOMMENT BELOW TO GET LATEX TABLE ///
log using tab8.txt, text replace
#delimit ;
esttab, star(* .1 ** .05 *** .01) 
keep(swornrt) wrap varwidth(20) se 
stats(pval mu elast fbeta ff ctl syfe trd ncluster N,
label("P-Val of Difference" "Mean" "Elasticity" "First Stage Beta" "F-Stat" "Controls" "Size x Year Effects" "City Trends" 
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment
mtitles("Predicted Firers" "Predicted Hirers") ;
#delimit cr
log close


/// ESTAB ///
/// LATEX FILE ///
/*
#delimit ;
esttab using tab8.tex, star(* .1 ** .05 *** .01) 
keep(swornrt) wrap varwidth(20) se 
stats(pval mu elast fbeta ff ctl syfe trd ncluster N,
label("P-Val of Difference" "Mean" "Elasticity" "First Stage Beta" "F-Stat" "Controls" "Size x Year Effects" "City Trends" 
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment replace 
mtitles("Predicted Firers" "Predicted Hirers") ;
#delimit cr
*/






