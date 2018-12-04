clear all
cap log close
set more off



****************************************
/// PART 1: GET FUNDING ESTIMATES  ///
****************************************

use ../data/cops, clear

/// VARIABLE INDICATING GRANTEE IN GIVEN YEAR ///
gen win=gcops>0

/// SIZE x YEAR EFFECTS ///
egen X=group(bin year)

// TREAT x YEAR INTERACTIONS ///
forval y=2004/2014 {
	gen treat_`y'=(rel>=0)*(year==`y')
}
drop treat_2008

/// STORE REGRESSION ESTIMATES ///
gen xyear=_n+2001 if _n<=13
gen beta=0 if _n<=13
gen se=0 if _n<=13
reghdfe win treat_2004-treat_2007 treat_2009-treat_2014, absorb(i.id i.X) vce(cluster id)
forval y=2002/2014 {
	cap replace beta=_b[treat_`y'] if xyear==`y'
	cap replace se=_se[treat_`y'] if xyear==`y'
}

/// SAVE FUNDING ESTIMATES (TEMPFILE) ////
keep xyear beta se
drop if mi(xyear)
ren beta beta_fund
ren se se_fund
tempfile FUND
save `FUND'



****************************************************
/// PART 2: GET ITT ESTIMATES FOR POLICE ///
*****************************************************

use ../data/cops, clear

/// SIZE x YEAR EFFECTS ///
egen X=group(bin year)

// TREAT x YEAR INTERACTIONS ///
forval y=2004/2014 {
	gen treat_`y'=(rel>=0)*(year==`y')
}
drop treat_2008

/// STORE REGRESSION ESTIMATES ///
gen xyear=_n+2001 if _n<=13
gen beta=0 if _n<=13
gen se=0 if _n<=13
reghdfe swornrt treat_2005-treat_2007 treat_2009-treat_2014, absorb(i.id i.X i.id#c.year) vce(cluster id)
forval y=2002/2014 {
	cap replace beta=_b[treat_`y'] if xyear==`y'
	cap replace se=_se[treat_`y'] if xyear==`y'
}

/// SAVE FUNDING ESTIMATES (TEMPFILE) ////
keep xyear beta se
drop if mi(xyear)
ren beta beta_itt
ren se se_itt
tempfile ITT
save `ITT'



*******************************************************
/// PART 3: GET RECURSIVE TOT ESTIMATES FOR POLICE ///
*******************************************************

/* NOTE: THIS SECTION INCLUDES BOOTSTRAP PROCEDURE */
/* TO COMPUTE STANDARD ERRORS */
/* THIS WILL BE TIME CONSUMING TO EXECUTE */
/* STORES A DATASET FOR EACH REPETITION */
/* THEN DELETEs AT END OF EXECUTION */


/// SET NUMBER OF BOOSTRAP REPETITIONS ///
/// IN PAPER, I USE 500 ITERATIONS ///
/// HERE, SETTING N=25 TO SAVE COMPUTING TIME ///
global nRep=25


***************************
/// STEP 1: CREATE DATA ///
***************************

use ../data/cops, clear

/// DUMMY FOR WINNER IN GIVEN YEAR ///
gen funded=(gcops>0)
/// TREAT x YEAR INTERACTIONS ///
forval y=2004/2014 {
	gen treat_`y'=(rel>=0)*(year==`y')
}
drop treat_2008
/// SIZE x YEAR BINS ///
egen X=group(bin year)

/// STORE BAREBONES DATASET as DATA.dta ///
keep id year funded swornrt treat_* X
save DATA, replace



******************************
/// STEP 2: STORE ID LIST ///
*****************************

// STORE UNIQUE LIST OF CITIES AS LIST.dta ///
keep id
duplicates drop
save LIST, replace



*******************************************************
/// STEP 3: (BY HAND) BOOTSTRAP TO GET STANDARD ERRORS 
*******************************************************


/// LOOP OVER REPETITIONS ///

forval j=1/$nRep {


//// CONSTRUCT BOOTSTRAP SAMPLE ////
use LIST, clear
bsample

/// "EXPAND" TO CREATE PANEL ///
gen TEMPID=_n
expand 13
bysort TEMPID: gen year=_n+2001
keep id TEMPID year

/// MERGE WITH DATASET ///
// MAKE DATASET //
merge m:1 id year using DATA, keep(3) nogen


// STORAGE FOR ESTIMATES //
gen xyear=_n+2003 if _n<=11
gen betafund=0 if _n<=11
gen sefund=0 if _n<=11
gen betasworn=0 if _n<=11
gen sesworn=0 if _n<=11

// ITT FUNDING ESTIMATES ///
reghdfe funded treat_2005-treat_2007 treat_2009-treat_2014, absorb(i.TEMPID i.X i.TEMPID#c.year) 
forval y=2002/2014 {
	cap replace betafund=_b[treat_`y'] if xyear==`y'
	cap replace sefund=_se[treat_`y'] if xyear==`y'
}


/// ITT POLICE ESTIMATES ///
reghdfe swornrt treat_2005-treat_2007 treat_2009-treat_2014, absorb(i.TEMPID i.X i.TEMPID#c.year) 
forval y=2002/2014 {
	cap replace betasworn=_b[treat_`y'] if xyear==`y'
	cap replace sesworn=_se[treat_`y'] if xyear==`y'
}


/// STORE RESULTS (INDEXED BY YEAR RELATIVE TO 2009 ////
gen relyear=(xyear-2009)
keep relyear xyear betafund betasworn


// STORE PI (ITT FUNDING EFFECT) AS MACRO ////
forval i=1/5 {
	summ betafund if relyear==`i'
	local Pi`i'=r(mean)
}

// CONSTRUCT TOT BY RESCALING BY PI + PAST ITT ///
/// SEE CELLINI, FERREIRA, ROTHSTEIN (QJE 2010), p.229 ///
gen betatot=.
replace betatot=betasworn if relyear==0
replace betatot=betasworn-`Pi1'*betatot[_n-1] if relyear==1
replace betatot=betasworn-`Pi1'*betatot[_n-1]-`Pi2'*betatot[_n-2] if relyear==2
replace betatot=betasworn-`Pi1'*betatot[_n-1]-`Pi2'*betatot[_n-2]-`Pi3'*betatot[_n-3] if relyear==3
replace betatot=betasworn-`Pi1'*betatot[_n-1]-`Pi2'*betatot[_n-2]-`Pi3'*betatot[_n-3]-`Pi4'*betatot[_n-4] if relyear==4
replace betatot=betasworn-`Pi1'*betatot[_n-1]-`Pi2'*betatot[_n-2]-`Pi3'*betatot[_n-3]-`Pi4'*betatot[_n-4]-`Pi5'*betatot[_n-4] if relyear==5


// RENAME BETA ACCORDIG TO CURRENT ITERATION ///
ren betatot betatot_`j'
keep xyear betatot
drop if mi(xyear)


/// STORE RESULT FOR ITERATION ////
save ITER_`j', replace

}


***************************************
/// COMPUTE SE USING BOOTSTRAP ESTS ///
***************************************

/// WRANGLE TOGETHER (MERGE) ///
use ITER_1, clear
forval j=2/$nRep {
	merge 1:1 xyear using ITER_`j', keep(3) nogen
}

/// COMPUTE SD ///
egen se_recursive=rowsd(betatot_*)

/// STORE RESULT ///
keep xyear se_recursive
save SE, replace


//// DELETE ALL THE ITERATION DATA FILES ////
forval j=1/$nRep {
	rm ITER_`j'.dta
}




*******************************************************
/// STEP 4: COMPUTE RECURSIVE TOT POINT ESTIMATES 
*******************************************************


use DATA, clear

// STORAGE FOR ESTIMATES //
gen xyear=_n+2001 if _n<=13
gen betafund=0 if _n<=13
gen sefund=0 if _n<=13
gen betasworn=0 if _n<=13
gen sesworn=0 if _n<=13

// ITT: FUNDING //
reghdfe funded treat_2005-treat_2007 treat_2009-treat_2014, absorb(i.id i.X i.id#c.year) 
forval y=2002/2014 {
	cap replace betafund=_b[treat_`y'] if xyear==`y'
	cap replace sefund=_se[treat_`y'] if xyear==`y'
}


// ITT: POLICE //
reghdfe swornrt treat_2005-treat_2007 treat_2009-treat_2014, absorb(i.id i.X i.id#c.year) 
forval y=2002/2014 {
	cap replace betasworn=_b[treat_`y'] if xyear==`y'
	cap replace sesworn=_se[treat_`y'] if xyear==`y'
}


/// SAME AS ABOVE ///
keep xyear betafund betasworn
// STORE PI AS MACRO //
gen relyear=xyear-2009
forval i=1/5 {
	summ betafund if relyear==`i'
	local Pi`i'=r(mean)
}
// Construct TOT ESTIMATE //
gen betatot=.
replace betatot=betasworn if relyear==0
replace betatot=betasworn-`Pi1'*betatot[_n-1] if relyear==1
replace betatot=betasworn-`Pi1'*betatot[_n-1]-`Pi2'*betatot[_n-2] if relyear==2
replace betatot=betasworn-`Pi1'*betatot[_n-1]-`Pi2'*betatot[_n-2]-`Pi3'*betatot[_n-3] if relyear==3
replace betatot=betasworn-`Pi1'*betatot[_n-1]-`Pi2'*betatot[_n-2]-`Pi3'*betatot[_n-3]-`Pi4'*betatot[_n-4] if relyear==4
replace betatot=betasworn-`Pi1'*betatot[_n-1]-`Pi2'*betatot[_n-2]-`Pi3'*betatot[_n-3]-`Pi4'*betatot[_n-4]-`Pi5'*betatot[_n-4] if relyear==5


// KEEP, MERGE TO STANDARD ERROR EST, AND SAVE ///
ren betatot beta_tot
keep xyear beta_tot
drop if mi(xyear)
merge 1:1 xyear using SE, nogen
ren se_recursive se_tot
tempfile TOT
save `TOT'

//// REMOVE INTERMEDIARY FILES ///
rm SE.dta
rm DATA.dta
rm LIST.dta






*******************************************************
/// PART 4: MERGE ITT + TOT ESTIMATES ///
*******************************************************

use `FUND', clear
merge 1:1 xyear using `ITT', nogen
merge 1:1 xyear using `TOT', nogen
keep if xyear>=2009




/// STORE TABLE ///
log using tab7.txt, text replace
list
log close











