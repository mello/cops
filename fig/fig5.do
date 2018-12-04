clear all
cap log close
set more off


use ../data/cops, clear


// YEAR x TREAT INTERACTIONS ///
/// NOTE: HAVE TO LEAVE OUT TWO YEARS TO ALLOW FOR TRENDS ///
forval y=2004/2014 {
	gen treat_`y'=(rel>=0)*(year==`y')
}
drop treat_2008

// SIZE x YEAR EFFECTS //
egen X=group(bin year)


// YEAR FOR FIGURE ///
gen xyear=_n+2003 if _n<=11


/// REGRESSIONS + STORE BETA/SE ///
foreach x in sworn cost {

gen beta_`x'=0 if _n<=11
gen ub_`x'=0 if _n<=11
gen lb_`x'=0 if _n<=11

reghdfe `x'rt treat_2005-treat_2007 treat_2009-treat_2014, absorb(i.id i.X i.id#c.year) vce(cluster id)
forval y=2004/2014 {
	cap replace beta_`x'=_b[treat_`y'] if xyear==`y'
	cap replace ub_`x'=_b[treat_`y']+1.96*_se[treat_`y'] if xyear==`y'
	cap replace lb_`x'=_b[treat_`y']-1.96*_se[treat_`y'] if xyear==`y'
}


}


/// "JITTER" YEARS //
gen xyear_sworn=xyear
gen xyear_cost=xyear+0.33
drop if xyear>2012

#delimit ;
twoway connected beta_sworn xyear_sworn, mcolor("33 102 172") lcolor("33 102 172") 
	msize(medium) msymbol(O) yaxis(1) ||
rspike ub_sworn lb_sworn xyear_sworn, lcolor("33 102 172") yaxis(1) ||
connected beta_cost xyear_cost, mcolor("178 24 43") lcolor("178 24 43") 
	msymbol(S) msize(medium) yaxis(2) ||
rspike ub_cost lb_cost xyear_cost, lcolor("178 24 43") yaxis(2)
scheme(plotplainblind) xlab(2004(2)2012,nogrid) 
ylab(-1.5(0.5)1.5, nogrid axis(1)) ylab(-100(50)100,axis(2) nogrid)
xline(2008.5) yline(0)
xtitle("Year") ytitle("")
legend(pos(6) order(1 3) cols(1) lab(1 "Police per 10,000 (Left Axis)") lab(3 "Crime Cost per Capita (Right Axis)")) ;
#delimit cr
graph export fig5.pdf, replace





