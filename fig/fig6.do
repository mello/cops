clear all
cap log close
set more off


use ../data/cops, clear


/// DATA SETUP ////
global cov="unemprt logpci pct*"
egen X=group(bin year)


**********************************
// PANEL A: CHANGING BANDWIDTHS //
**********************************

preserve 

foreach x in sworn cost {

	local k=1
	gen bw_`x'=.
	gen beta_`x'=.
	gen ub_`x'=.
	gen lb_`x'=.
	
	foreach b in 4 3 2 1.5 1 0.5 0.25 {
		
		replace bw_`x'=`b' if _n==`k'
		reghdfe `x'rt high_post $cov if abs(rel)<`b', absorb(i.id i.X i.id#c.year) vce(cluster id)
		
		replace beta_`x'=_b[high_post] if _n==`k'
		replace ub_`x'=_b[high_post]+1.96*_se[high_post] if _n==`k'
		replace lb_`x'=_b[high_post]-1.96*_se[high_post] if _n==`k'
		
		local ++k
		
	}
	
}


#delimit ;
twoway connected beta_sworn bw_sworn, msize(medium) 
mcolor("33 102 172") lcolor("33 102 172") msymbol(O) ||
rspike ub_sworn lb_sworn bw_sworn, lcolor("33 102 172") ||
connected beta_cost bw_cost, mcolor("178 24 43") lcolor("178 24 43") 
	yaxis(2) msize(medium) msymbol(S) ||
rspike ub_cost lb_cost bw_cost, lcolor("178 24 43") yaxis(2)
scheme(plotplainblind) xlab(,nogrid) yline(0)
ylab(-1.5(0.5)1.5, nogrid axis(1)) ylab(-75(25)75, nogrid axis(2))
legend(pos(6) order(1 3) cols(1) lab(1 "Police per 10,000 (Left Axis)") 
lab(3 "Crime Cost per Capita (Right Axis)")) 
xtitle("Bandwidth") ytitle("Coefficient on High x Post")
title("Panel A: Changing Bandwidth") 
nodraw name(A, replace) ;
#delimit cr

restore



**********************************
// PANEL B: MOVING CUTOFFS //
**********************************

preserve

foreach x in sworn cost {

	local k=1
	gen perturb_`x'=.
	gen beta_`x'=.
	gen ub_`x'=.
	gen lb_`x'=.
	
	foreach p in -1 -.75 -.5 -.25 0 0.25 0.5 0.75 1 {
	
		replace perturb_`x'=`p' if _n==`k'
	
		gen HIGH_POST=(rel>=`p')*(year>=2009)
		reghdfe `x'rt HIGH_POST $cov, absorb(i.id i.X i.id#c.year) vce(cluster id)
		
		replace beta_`x'=_b[HIGH_POST] if _n==`k'
		replace ub_`x'=_b[HIGH_POST]+1.96*_se[HIGH_POST] if _n==`k'
		replace lb_`x'=_b[HIGH_POST]-1.96*_se[HIGH_POST] if _n==`k'
		
		drop HIGH_POST
		local ++k
		
	}
	
}

replace perturb_cost=perturb_cost+.01
#delimit ;
twoway connected beta_sworn perturb_sworn, msize(medium) mcolor("33 102 172") 
lcolor("33 102 172") msymbol(O) ||
rspike ub_sworn lb_sworn perturb_sworn, lcolor("33 102 172") ||
connected beta_cost perturb_cost, msize(medium) mcolor("178 24 43") 
lcolor("178 24 43") msymbol(S) yaxis(2) ||
rspike ub_cost lb_cost perturb_cost, lcolor("178 24 43") yaxis(2)
scheme(plotplainblind) yline(0)  xlab(,nogrid)
ylab(-1.5(0.5)1.5, nogrid axis(1)) ylab(-100(25)100, nogrid axis(2))
xtitle("Change to Cutoff") ytitle("") ytitle("Coefficient on High x Post", axis(2))
title("Panel B: Placebo Cutoffs")
legend(pos(6) order(1 3) lab(1 "Police per 10,000 (Left Axis)") 
lab(3 "Crime Cost per Capita (Right Axis)"))
nodraw name(B, replace) ;
#delimit cr

restore


graph combine A B, graphregion(color(white))
graph export fig6.pdf, replace













