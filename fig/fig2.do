clear all
cap log close
set more off

use ../data/grants, clear
keep if SAMPLE==1

gen funded=(cops>0)
#delimit ;
egen scorebin=cut(rel),
	 at(-4.0,-3.75,-3.5,-3.25,-3.0,-2.75,-2.5,-2.25,-2.0,
		-1.75,-1.5,-1.25,-1.0,-0.75,-0.5,-0.25,0.0,
		0.25,0.5,0.75,1.0,1.25,1.5,1.75,2.0,
		2.25,2.5,2.75,3.0,3.25,3.5,3.75,4.0) ;
#delimit cr
drop if mi(scorebin)

bysort scorebin: egen mrel=mean(rel)
bysort scorebin: egen mfunded=mean(fund)


#delimit ;
hist rel, bin(50) freq
	fcolor("33 102 172") lcolor(white) lwidth(thick)
	scheme(plotplainblind)
	xlabel(-4(1)4)
	ytitle("Number of Applicants", axis(1))
	ytitle("Fraction Funded", axis(2))
	xtitle("Application Score")
	addplot(connected mfunded mrel, msymbol(O) mcolor(black) msize(medium)
	lwidth(medthick) lcolor(black) lpattern(solid) yaxis(2)) 
	xlab(,nogrid) ylab(,nogrid) xtitle("Score Around Cutoff")
	legend(pos(6) cols(1) lab(1 "Number of Applicants (Left Axis)")
	lab(2 "Fraction Funded (Right Axis)")) ;
#delimit cr
graph export fig2.pdf, replace 


