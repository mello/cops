clear all
cap log close
set more off

use ../data/grants, clear

/// SAMPLE ONLY ///
keep if SAMPLE==1

/// SETUP DATA ///
gen costrt=(6779*viort+4064*prprt)/10000
// TRUNCATE POP FOR FIGURE //
summ pop, d
replace pop=r(p99) if pop>r(p99)
replace pop=pop/10000

/// LABELS ///
label var pop "Population"
label var swornrt "Police Per 10,000"
label var costrt "Crime Cost Per Capita"
label var unempr "Unemployment Rate"

 
/// LOOP OVER COVARIATES TO CREATE FIGURES (WITH RD ESTIMATES ///
foreach x in pop swornrt costrt unempr {

	/// STORE TITLE ///
	local TITLE: variable label `x'
	
	/// GET RD ESTIMATE ///
	rd `x' rel
	local b=round(_b[lwald],.01)
	local se=round(_se[lwald],.01)
	
	lpoly `x' rel if rel<0, gen(x0 y0) nodraw bw(0.5)
	lpoly `x' rel if rel>=0, gen(x1 y1) nodraw bw(0.5)
	
	
	#delimit ;
	hist rel, freq fcolor("33 102 172") lcolor(white) lwidth(medthick) bin(50)
	addplot(line y0 x0, lwidth(medthick) lcolor(black) yaxis(2) lpattern(solid) ||
			line y1 x1, lwidth(medthick) lcolor(black) yaxis(2) lpattern(solid))
	scheme(plotplainblind) 
	legend(pos(6) order(2) lab(2 "RD Estimate: `b' (`se')"))
	xtitle("Score Around Cutoff") ytitle("", axis(1)) ytitle("", axis(2))
	title("`TITLE'")
	xlab(,nogrid) ylab(,nogrid) 
	nodraw name(`x', replace) ;
	#delimit cr
	
	drop x0 y0 x1 y1 
	// drop random bin mX mY
	
}

graph combine pop swornrt costrt unempr, graphregion(color(white))
graph export fig3.pdf, replace 

	
	
	
	
