clear all
cap log close
set more off


use ../data/cops, clear


/// SETUP DATA ///
egen X=group(bin year)
global cov="logpci unemprt pct*"


// STORE NUMBER OF CITIES //
egen XID=group(ori)
summ XID
local NCITY=r(max)
drop XID


// MEAN POLICE (FOR ELASTICITY) //
summ swornrt if year==2004&abs(rel)<=1
local mX=round(r(mean),.01)


/// CLEAR OUR ESTO ///
eststo clear


/// REGRESSIONS (LOOP OVER CRIME TYPES) ///
foreach x in vio mur rpt rbt aga prp bur lar vtt {

summ `x'rt if year==2004&abs(rel)<=1
local mY=round(r(mean),.01)

eststo: reghdfe `x'rt $cov (swornrt=high_post), absorb(i.id i.X i.id#c.year) vce(cluster id)

local ELAST=round(_b[swornrt]*(`mX'/`mY'),.01)
local ELAST=substr("`ELAST'",1,5)
qui estadd local mu `mY'
qui estadd local elast `ELAST'
qui estadd local ctl "Yes"
qui estadd local syfe "Yes"
qui estadd local trd "Yes"
qui estadd local ncluster `NCITY'


}


//// ESTAB ///
/// STORE AS .TXT FILE VIA LOG ///
/// UNCOMMENT BELOW TO GET LATEX TABLE ///
log using tab5.txt, text replace
#delimit ;
esttab, star(* .1 ** .05 *** .01) 
keep(swornrt) wrap varwidth(20) se 
stats(mu elast ctl syfe trd ncluster N,
label("Mean" "Elasticity" "Controls" "Size x Year Effects" "City Trends" 
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment 
mtitles("All Violent" "Murder" "Rape" "Robbery" "Assault" 
"All Property" "Burglary" "Larceny" "Auto Theft") ;
#delimit cr
log close


//// ESTAB ///
/// LATEX TABLE ///
/*
#delimit ;
esttab using tab5.tex, star(* .1 ** .05 *** .01) 
keep(swornrt) wrap varwidth(20) se 
stats(mu elast ctl syfe trd ncluster N,
label("Mean" "Elasticity" "Controls" "Size x Year Effects" "City Trends" 
"Clusters (Cities)" "Observations (City-Years)")) 
label fragment replace 
mtitles("All Violent" "Murder" "Rape" "Robbery" "Assault" 
"All Property" "Burglary" "Larceny" "Auto Theft") ;
#delimit cr
*/




