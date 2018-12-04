clear all
cap log close
set more off

use ../data/cops, replace


gen treat=(rel>=0)
collapse (mean) swornrt costrt, by(treat year)


program define LINEUP
summ `1' if treat==1&year==2008
local TREAT=r(mean)
summ `1' if treat==0&year==2008 
local CONTROL=r(mean)
local DIFF=`TREAT'-`CONTROL'
replace `1'=`1'-`DIFF' if treat==1
end


LINEUP swornrt
LINEUP costrt



#delimit ;
twoway connected swornrt year if treat==1, 
msymbol(O) mcolor("33 102 172") lcolor("33 102 172") msize(medium) ||
connected swornrt year if treat==0 ,
msymbol(O) mcolor("178 24 43") lcolor("178 24 43")
msymbol(S) msize(medium) lpattern(dash)
scheme(plotplainblind)
legend(cols(1) pos(6) lab(1 "Above Cutoff") lab(2 "Below Cutoff"))
xline(2008.5)
xlab(,nogrid) ylab(19.5(0.5)21.5,nogrid)
xtitle("") ytitle("")
title("Panel A: Police Per 10,000", color(black))
nodraw name(a, replace) ;

#delimit ;
twoway connected costrt year if treat==1, 
msymbol(O) mcolor("33 102 172") lcolor("33 102 172") msize(medium) ||
connected costrt year if treat==0 ,
msymbol(S) mcolor("178 24 43") lcolor("178 24 43") msize(medium) lpattern(dash)
scheme(plotplainblind)
legend(cols(1) pos(6) lab(1 "Above Cutoff") lab(2 "Below Cutoff"))
xline(2008.5)
xlab(,nogrid) ylab(300(50)550,nogrid)
xtitle("") ytitle("")
title("Panel B: Crime Cost Per Capita", color(black))
nodraw name(b, replace) ;


graph combine a b, graphregion(color(white)) ;
graph export fig4.pdf, replace ;

#delimit cr
