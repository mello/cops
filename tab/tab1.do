clear all
cap log close
set more off


use ../data/grants, clear

/// KEEP IN SAMPLE ///
keep if SAMPLE==1


/// SETUP VARIABLE LIST ///
gen pop10=(pop/10000)
label var pop10 "Population (Ten Thousands)"
label var unempr "Unemployment Rate"
replace income=income/10000
label var income "Family Income (Ten Thousands)"
label var pct_black "Percent Black"
label var pct_hispanic "Percent Hispanic"
label var pct_youngmale "Percent Young Male"
label var swornrt "Police Per 10,000"
label var viort "Violent Crimes Per 10,000"
label var prprt "Property Crimes Per 10,000"
gen costrt=((67794*viort)+(4064*prprt))/10000
label var costrt "Crime Cost Per Capita"
gen copsrt=cops/pop10
label var copsrt "Officers Funded Per 10,000"
gen fundrt=copsd/pop
label var fundrt "Funding Per Capita"


/// VARIABLE LIST ///
global VARS="pop10 unempr income pct_black pct_hispanic pct_youngmale swornrt viort prprt costrt copsrt fundrt"


/// CONSTRUCT GROUPS FOR USE WITH TABSTAT, BY() ///
cap drop CAT
gen CAT=""
replace CAT="Above Cutoff" if rel>=0
replace CAT="Below Cutoff" if rel<0

/// CONSTRUCT ESTPOST ///
estpost tabstat $VARS, by(CAT) statistics(mean sd) columns(statistics) listwise


//// ESTAB ///
/// STORE AS .TXT FILE VIA LOG ///
/// UNCOMMENT BELOW TO GET LATEX TABLE ///
log using tab1.txt, text replace
#delimit ;
esttab, replace main(mean) aux(sd) 
nostar unstack nonote nonumber label nomtitles noobs  ;
#delimit cr
log close


/// ESTAB ///
/// LATEX FILE ///
/*
#delimit ;
esttab using tab1.tex, replace main(mean) aux(sd) 
nostar unstack nonote nonumber label nomtitles noobs  ;
#delimit cr
*/


