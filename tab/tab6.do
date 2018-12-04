clear all
cap log close
set more off


*********************************
// PART 1: SETUP DATA ///
*********************************

/// START WITH PANEL ///
use ../data/cops, clear
/// ATTACH WITH ARRESTS (CUT SAMPLE) ///
merge 1:1 ori year using ../data/arrests, keep(3) nogen


/// OTHER DATA SETUP ///
egen X=group(bin year)
global cov="logpci unemprt pct*"



*********************************
// PART 2: REGRESSIONS  ///
*********************************

/// CLEAR OUT ESTSTO ///
eststo clear


/// STORE NUMBER OF CITIES ///
egen XID=group(ori)
summ XID
local NCITY=r(max)
drop XID


/// STORE MEAN POLICE ///
summ swornrt if year==2004&abs(rel)<=1
local mX=round(r(mean),.01)


//// REG 1: VIOLENT-POLICE ///
summ viort if year==2004&abs(rel)<=1
local mY=round(r(mean),.01)
eststo: reghdfe viort $cov (swornrt=high_post), absorb(i.id i.X i.id#c.year) vce(cluster id)

local E=round(_b[swornrt]*(`mX'/`mY'),.01)
local E=substr("`E'",1,5)
qui estadd local mu `mY'
qui estadd local elast `E'
qui estadd local fstat "-"
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'


/// REG 2: VIOLENT ARRESTS-POLICE ///
summ aviort if year==2004&abs(rel)<=1
local mY=round(r(mean),.01)
eststo: reghdfe aviort $cov (swornrt=high_post), absorb(i.id i.X i.id#c.year) vce(cluster id)

local E=round(_b[swornrt]*(`mX'/`mY'),.01)
local E=substr("`E'",1,5)
qui estadd local mu `mY'
qui estadd local elast `E'
qui estadd local fstat "-"
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'


/// REG 3: PROPERTY-POLICE ///
summ prprt if year==2004&abs(rel)<=1
local mY=round(r(mean),.01)
eststo: reghdfe prprt $cov (swornrt=high_post), absorb(i.id i.X i.id#c.year) vce(cluster id)

local E=round(_b[swornrt]*(`mX'/`mY'),.01)
local E=substr("`E'",1,5)
qui estadd local mu `mY'
qui estadd local elast `E'
qui estadd local fstat "-"
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'



/// REG 4: PROPERTY ARRESTS-POLICE ///
summ aprprt if year==2004&abs(rel)<=1
local mY=round(r(mean),.01)
eststo: reghdfe aprprt $cov (swornrt=high_post), absorb(i.id i.X i.id#c.year) vce(cluster id)

local E=round(_b[swornrt]*(`mX'/`mY'),.01)
local E=substr("`E'",1,5)
qui estadd local mu `mY'
qui estadd local elast `E'
qui estadd local fstat "-"
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'



/// ESTAB ///
/// STORE AS .TXT VIA LOG FILE ///
/// UNCOMMENT BELOW TO GET LATEX FILE ///
log using tab6.txt, text replace
#delimit ;
esttab, star(* .1 ** .05 *** .01) 
keep(swornrt) wrap varwidth(20) se 
stats(mu elast ctl syfe trd ncluster N,
label("Mean" "Elasticity" "Controls" "Size x Year Effects" "City Trends" 
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment 
mtitles("Violent Crimes" "Violent Arrests" "Property Crimes" "Property Arrests") ;
#delimit cr
log close




/// ESTAB ///
/// LATEX FILE ///
/*
#delimit ;
esttab using tab6.tex, star(* .1 ** .05 *** .01) 
keep(swornrt) wrap varwidth(20) se 
stats(mu elast ctl syfe trd ncluster N,
label("Mean" "Elasticity" "Controls" "Size x Year Effects" "City Trends" 
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment replace 
mtitles("Violent Crimes" "Violent Arrests" "Property Crimes" "Property Arrests") ;
#delimit cr
*/





