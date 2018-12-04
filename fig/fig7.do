clear all
cap log close
set more off


use ../data/cops


/// TREAT x YEAR INTERACTIONS //
forval y=2005/2014 {
	gen treat_`y'=(rel>=0)*(year==`y')
}
drop treat_2008

// SIZE x YEAR EFFECTS //
egen X=group(bin year)


// YEAR FOR GRAPH //
gen xyear=_n+2003 if _n<=11


foreach x in vio prp {

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


// JITTER YEARS //
gen xyear_vio=xyear
gen xyear_prp=xyear+0.33
drop if xyear>2012

#delimit ;
twoway connected beta_vio xyear_vio, mcolor("178 24 43") lcolor("178 24 43") 
	msize(medium) msymbol(S) ||
rspike ub_vio lb_vio xyear_vio, lcolor("178 24 43") ||
connected beta_prp xyear_prp, mcolor("118 42 131") lcolor("118 42 131") 
	msymbol(Dh) msize(medium) yaxis(2) ||
rspike ub_prp lb_prp xyear_prp, lcolor("118 42 131") yaxis(2)
scheme(plotplainblind) xlab(2004(2)2012,nogrid) xline(2008.5) yline(0)
xtitle("Year") ytitle("") ylab(-12(4)12,nogrid axis(1)) ylab(-30(10)30,nogrid axis(2))
legend(pos(6) order(1 3) cols(1) lab(1 "Violent (Left Axis)") lab(3 "Property (Right Axis)")) ;
#delimit cr
graph export fig7.pdf, replace





