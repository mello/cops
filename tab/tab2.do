clear all
cap log close
set more off


use ../data/cops, clear


/// SETUP DATA ///
egen X=group(bin year)
global cov="logpci unemprt pct*"

// NUMBER OF CITIES (FOR REG TABLE) ///
egen XID=group(ori)
summ XID
local NCITY=r(max)
drop XID


/// CLEAR OUT ESTSTO ///
eststo clear


/// REG 1: FIRST STAGE ///

// STORE MEAN //
summ swornrt if year==2004&abs(rel)<=1
local mX=round(r(mean),.01)

// EST ///
eststo: reghdfe swornrt high_post $cov, absorb(i.id i.X i.id#c.year) vce(cluster id)
test high_post
local f=round(r(F),.01)
qui estadd local mu `mX'
qui estadd local elast "-"
qui estadd local fstat `f'
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'


/// REG 2: REDUCED FORM ///

// STORE MEAN //
summ costrt if year==2005&abs(rel)<=1
local mY=round(r(mean),.01)

// EST //
eststo: reghdfe costrt high_post $cov, absorb(i.id i.X i.id#c.year) vce(cluster id)
qui estadd local mu `mY'
qui estadd local elast "-"
qui estadd local fstat "-"
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'


// REG 3: OLS CRIME-POLICE ///

eststo: reghdfe costrt swornrt  $cov, absorb(i.id i.X i.id#c.year) vce(cluster id)
local E=round(_b[swornrt]*(`mX'/`mY'),.01)
qui estadd local mu `mY'
qui estadd local elast `E'
qui estadd local fstat "-"
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'


/// REG 4: IV CRIME-POLICE ///

eststo: reghdfe costrt $cov (swornrt=high_post), absorb(i.id i.X i.id#c.year) vce(cluster id)
local E=round(_b[swornrt]*(`mX'/`mY'),.01)
qui estadd local mu `mY'
qui estadd local elast `E'
qui estadd local fstat "-"
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'


//// ESTAB ///
/// STORE AS .TXT FILE VIA LOG ///
/// UNCOMMENT BELOW TO GET LATEX TABLE ///
log using tab2.txt, text replace
#delimit ;
esttab, star(* .1 ** .05 *** .01) 
keep(high_post swornrt) wrap varwidth(20) se 
stats(mu elast fstat ctl syfe trd ncluster N,
label("Mean" "Elasticity" "F-Stat" "Controls" "Size x Year Effects" "City Trends" 
"Clusters (Cities)" "Observations (City-Years)")) 
label 
mtitles("Police" "Crime" "OLS: Crime" "IV: Crime") ;
#delimit cr
log close


/// ESTAB ///
/// LATEX FILE ///
/*
#delimit ;
esttab using tab2.tex, star(* .1 ** .05 *** .01) 
keep(high_post swornrt) wrap varwidth(20) se 
stats(mu elast fstat ctl syfe trd ncluster N,
label("Mean" "Elasticity" "F-Stat" "Controls" "Size x Year Effects" "City Trends" 
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment replace 
mtitles("Police" "Crime" "OLS: Crime" "IV: Crime") ;
#delimit cr
*/



