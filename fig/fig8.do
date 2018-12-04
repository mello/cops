clear all
cap log close
set more off

*************************************
/// STEP 1: CATEGORIZE CITIES ///
*************************************

use ../data/spillovers, clear
// KEEP ARRA YEAR /
keep if year==2009

/// DUMMIES FOR WINNER + LOSER ///
gen winner=(rel>=0)&!mi(rel)
gen loser=!mi(rel)&(rel<0)

/// ANY WINNER IN COUNTY? ///
bysort fips: egen anywinner=max(winner)
/// NON-WINNER BUT WINNER IN COUNTY ///
gen cty_winner=(anywinner==1)&(winner==0)

/// ANY LOSER IN COUNTY? ///
bysort fips: egen anyloser=max(loser)
/// NON-LOSER BUT LOSER IN COUNTY ///
gen cty_loser=(anyloser==1)&(loser==0)&(anywinner==0)

/// DROP NON-APPLICANTS WITHOUT APPLICANT IN COUNTY////
gen other=(winner==0)&(loser==0)&(cty_winner==0)&(cty_loser==0)
drop if other==1

keep ori winner loser cty_winner cty_loser 
tempfile CATEGORY
save `CATEGORY'



*************************************
/// STEP 2: SETUP DATA ///
*************************************

use ../data/spillovers, clear
merge m:1 ori using `CATEGORY', keep(3) nogen


/// GENERATE GROUP INTERACTIONS ////
foreach x in winner loser cty_winner cty_loser {
	forval y=2004/2014 {
		gen `x'_`y'=(`x')*(year==`y')
	}
	// DROP EXCLUDES //
	drop `x'_2004 `x'_2008
}



/// OTHER SETUP DATA ///
global cov="logpci unemprt pct*"
egen X=group(bin year)



*************************************
/// STEP 3: REGRESSIONS ///
*************************************

/// VARS FOR STORAGE STORAGE ///
gen xyear=_n+2003 if _n<=11
foreach x in winner cty_winner cty_loser {
	gen beta_`x'=0 if _n<=11
	gen ub_`x'=0 if _n<=11
	gen lb_`x'=0 if _n<=11
}


/// REG CRIME ON INTERACTIONS ///
reghdfe costrt winner_* cty_winner_* cty_loser_* $cov, absorb(i.id i.X i.id#c.year) vce(cluster id)

/// STORE BETAS ///
forval y=2004/2014 {
	foreach x in winner cty_winner cty_loser {
		cap replace beta_`x'=_b[`x'_`y'] if xyear==`y'
		cap replace ub_`x'=_b[`x'_`y']+1.96*_se[`x'_`y'] if xyear==`y'
		cap replace lb_`x'=_b[`x'_`y']-1.96*_se[`x'_`y'] if xyear==`y'
	}
}


// JITTER X-AXIS //
keep if xyear<=2012
gen xyear_winner=xyear
gen xyear_cty_winner=xyear+0.15
gen xyear_cty_loser=xyear+0.3


// FIGURE //
#delimit ;
twoway connected beta_winner xyear_winner,
	msize(medium) msymbol(O) mcolor("33 102 172") lcolor("33 102 172") ||
rspike ub_winner lb_winner xyear_winner,
	 lcolor("33 102 172")	||
connected beta_cty_winner xyear_cty_winner,
	msize(medium) msymbol(S) mcolor("178 24 43") lcolor("178 24 43") ||
rspike ub_cty_winner lb_cty_winner xyear_cty_winner,
	lcolor("178 24 43")    ||
connected beta_cty_loser xyear_cty_loser,
	msize(medium) msymbol(Dh) mcolor("118 42 131") lcolor("118 42 131") ||
rspike ub_cty_loser lb_cty_loser xyear_cty_loser,
	lcolor("118 42 131")
scheme(plotplainblind) xlab(,nogrid) ylab(,nogrid)
title("")
xtitle("Year") ytitle("Crime Cost Per Capita")
xline(2008.5) yline(0)
legend(order(1 3 5) pos(6) cols(1)
lab(1 "Treated") lab(3 "Non-Applicant with Treated in County") lab(5 "Non-Applicant with Control in County"))  ;
#delimit cr

graph export fig8.pdf, replace












