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
/// RAW DATA PLOTS BY FIRER/HIRER STATUS //
*****************************************

// GET DATA //
use ../data/cops, clear
merge m:1 ori using `SAMPLE', nogen


// SET UP DATA //
gen treat=high
replace costrt=cost/10000

program define LINEUP
summ `1' if treat==1&year==2008
local TREAT=r(mean)
summ `1' if treat==0&year==2008 
local CONTROL=r(mean)
local DIFF=`TREAT'-`CONTROL'
replace `1'=`1'-`DIFF' if treat==1
end



// PART 1: FIRERS //
preserve 
keep if hirer==0
collapse (mean) swornrt, by(treat year)

LINEUP swornrt

#delimit ;
twoway connected swornrt year if treat==1, 
msymbol(O) mcolor("33 102 172") lcolor("33 102 172") msize(medium) ||
connected swornrt year if treat==0 ,
msymbol(O) mcolor("178 24 43") lcolor("178 24 43")
msymbol(S) msize(medium) lpattern(dash)
scheme(plotplainblind)
legend(cols(1) pos(6) lab(1 "Above Cutoff") lab(2 "Below Cutoff"))
xline(2008.5)
xlab(,nogrid) ylab(19(1)23,nogrid)
xtitle("") ytitle("")
title("Panel A: Predicted Firers", color(black))
nodraw name(a, replace) ;
#delimit cr
restore



// PART 2: HIRERS //
preserve 
keep if hirer==1
collapse (mean) swornrt, by(treat year)

LINEUP swornrt

#delimit ;
twoway connected swornrt year if treat==1, 
msymbol(O) mcolor("33 102 172") lcolor("33 102 172") msize(medium) ||
connected swornrt year if treat==0 ,
msymbol(O) mcolor("178 24 43") lcolor("178 24 43")
msymbol(S) msize(medium) lpattern(dash)
scheme(plotplainblind)
legend(cols(1) pos(6) lab(1 "Above Cutoff") lab(2 "Below Cutoff"))
xline(2008.5)
xlab(,nogrid) ylab(19(1)23 ,nogrid)
xtitle("") ytitle("")
title("Panel B: Predicted Hirers", color(black))
nodraw name(b, replace) ;
#delimit cr
restore

graph combine a b, graphregion(color(white)) xcommon ycommon
graph export fig10.pdf, replace






