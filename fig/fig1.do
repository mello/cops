clear all
cap log close
set more off


//// WRITE IN DATA FROM JAMES (2013) ///
clear
set obs 20
gen year=_n+1994

gen funds=.
replace funds=1057 if year==1995
replace funds=1128 if year==1996
replace funds=1339 if year==1997
replace funds=1338 if year==1998
replace funds=1201 if year==1999
replace funds=481 if year==2000
replace funds=408 if year==2001
replace funds=385 if year==2002
replace funds=199 if year==2003
replace funds=114 if year==2004
replace funds=10 if year==2005
replace funds=0 if year==2006
replace funds=0 if year==2007
replace funds=20 if year==2008
replace funds=1000 if year==2009
replace funds=298 if year==2010
replace funds=247 if year==2011
replace funds=141 if year==2012
replace funds=155 if year==2013
replace funds=124 if year==2014
replace funds=funds

// PLOT (BAR CHART) ///
#delimit ;
twoway bar funds year, lcolor(white) lwidth(medthick) fcolor("33 102 172") fintensity(50)
scheme(plotplainblind) xlab(,nogrid) ylab(,nogrid) xtitle("Year") ytitle("Millions") ;
#delimit cr
graph export fig1.pdf, replace 
