clear all
cap log close
set more off


//// GENERATE BINS OF RECESSION EXPOSURE ///
use ../data/cops, clear
bysort ori (year): gen diffunemp=unemprt-unemprt[_n-2]
keep if year==2009
gen RANDOM=runiform()
binscatter RANDOM diffunemp, nq(5) nodraw gen(BIN)
keep ori diffunemp BIN
tempfile X
save `X'


/// ATTACH BINS TO DATA ///
use ../data/cops, clear
merge m:1 ori using `X'


/// DATA SETUP ///
egen X=group(bin year)
global cov="logpci unemprt pct*"


/// INTERACT INSTRUMENT WITH BINS ///
forval i=2/5 {
	gen high_post_`i'=high_post*(BIN==`i')
}


***************************************************************************
/// NON-PARAMETRIC ESTIMATES ///
/// REG POLICE/CRIME ON INTERACTIONS BETWEEN INSTRUMENT AND RECESSION BINS //
***************************************************************************


gen XBIN=_n if _n<=5
gen XREC=.
forval i=1/5 {	
	summ diffunemp if BIN==`i'
	replace XREC=r(mean) if _n==`i'
}
	

foreach x in sworn cost {

	gen beta_`x'=.
	gen ub_`x'=.
	gen lb_`x'=.
	
	reghdfe `x'rt high_post high_post_2-high_post_5, absorb(i.id i.X i.id#c.year) vce(cluster id)
	
	replace beta_`x'=_b[high_post] if _n==1
	replace ub_`x'=_b[high_post]+1.96*_se[high_post] if _n==1
	replace lb_`x'=_b[high_post]-1.96*_se[high_post] if _n==1
	
	forval i=2/5 {
		replace beta_`x'=_b[high_post]+_b[high_post_`i'] if _n==`i'
		replace ub_`x'=_b[high_post]+_b[high_post_`i']+1.96*_se[high_post_`i'] if _n==`i'
		replace lb_`x'=_b[high_post]+_b[high_post_`i']-1.96*_se[high_post_`i'] if _n==`i'
	}
	
}



***************************************************************************
/// PARAMETRIC ESTIMATES ///
/// REG POLICE/CRIME ON LINEAR INTERACTION BETWEEN RECESSION AND INSTRUMENT //
***************************************************************************

gen high_post_diffunemp=high_post*diffunemp 

foreach x in sworn cost {

	gen beta_`x'_par=.
	
	reghdfe `x'rt high_post high_post_diffunemp, absorb(i.id i.X i.id#c.year) vce(cluster id)
	replace beta_`x'_par=_b[high_post]+_b[high_post_diffunemp]*diffunemp
	
}



/// PANEL A: FIRST STAGE AND REDUCED FORM ///
sort diffunemp

#delimit ;
scatter beta_sworn XREC, mcolor("33 102 172") msymbol(O) msize(medium) ||
line beta_sworn_par diffunemp if diffunemp>0&diffunemp<10, lcolor("33 102 172") lpattern(dash) ||
scatter beta_cost XREC,  mcolor("178 24 43") msymbol(S) msize(medium) yaxis(2) ||
line beta_cost_par diffunemp if diffunemp>0&diffunemp<10, lcolor("178 24 43") lpattern(dash) yaxis(2) 
scheme(plotplainblind) yline(0)
xlab(,nogrid) xtitle("Change in Unemployment Rate") 
ytitle("Police per 10,000", axis(1)) ytitle("Crime Cost per Capita", axis(2))
title("Panel A: First Stage and Reduced Form")
ylab(-1.5(0.5)1.5,axis(1) nogrid) ylab(-80(20)80,nogrid axis(2)) 
legend(pos(6) cols(2) lab(1 "Police (Bins)") lab(2 "Police (Linear)") 
	lab(3 "Crime (Bins)") lab(4 "Crime (Linear)")) 
nodraw name(a, replace) ;
#delimit cr



/// PANEL B: WALD/IV ESTIMATES ///
sort diffunemp
gen wald=beta_cost/beta_sworn
gen wald_par=beta_cost_par/beta_sworn_par

#delimit ;
scatter wald XREC,  mcolor("178 24 43") msymbol(S) msize(medium) ||
line wald_par diffunemp if diffunemp>0&diffunemp<10, lcolor("178 24 43") lpattern(dash) ||
scatter wald XREC, mcolor(white) msize(vtiny) yaxis(2)
scheme(plotplainblind) yline(0)
xlab(,nogrid) xtitle("Change in Unemployment Rate") 
ytitle("Crime Cost per Capita", axis(1)) ytitle("Crime Cost per Capita", axis(2))
title("Panel B: IV Estimates")
ylab(-80(20)80, axis(1) nogrid) ylab(-80(20)80, axis(2) nogrid)
legend(pos(6) order(1 2) cols(1) lab(1 "Bins") lab(2 "Parametric")) 
nodraw name(b, replace) ;
#delimit cr


graph combine a b, graphregion(color(white))
graph export fig9.pdf, replace






