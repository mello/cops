# cops
Replication Files for More COPS, Less Crime


**************
// DATA //
************

Datasets are in /data and are in stata 12 format. There are 5 datasets provided here. All datasets include FBI ORI codes to identify police agencies. 

1. cops.dta: Main dataset (47,327 city x year observations).

2. grants.dta: Information on all ARRA COPS applicants. 7,167 observations, one for each agency applying for a 2009 hiring grant, with application information and baseline covariates.

3. arra.dta: Information on local ARRA funding (from Federal Procurement Data System) matched to police agencies for 2009-2013 (16,385 city x year observations). 

4. arrests.dta: Violent and property crime arrest rates for the subsample of cities in main sample that report arrests (43,054 city x year observations).

5. spillovers.dta: Dataset for analysis of spillover effects. Includes main dataset + crime information and control variables for additional cities (134,695 city x year observations). 




***************
// FIGURES //
***************

Stata programs to replicate figures are in /fig. Each program is named according to the figure number that it creates (e.g. /fig/fig1.do creates Figure 1 in the paper). Each do-file creates a pdf of the same name (e.g. /fig/fig1.do creates /fig/fig1.pdf)



***************
// TABLES //
***************

Stata programs to replicate tables are in /tab. Each program is named according to the table number that it creates (same as above). Each program creates a .txt file that displays the table contents. Each program also includes code to create LATEX tables. This code is always at the end of the do-file and commented out by default.

NOTE: tab7.do constructs a table comparing ITT and TOT estimates. Standard errors for the recursive TOT estimates are obtained via a manually coded bootstrap procedure. This is a time and memory-intensive program,

One sets the number of bootstrap iterations on line 94 of the do-file. Currently that number is set to 25. Hence, if the code is run as-is, the standard error estimates may differ from those in the paper. For the estimates reported in the paper, I use 500 iterations. The estimates should be very similar (but may differ slightly) when the iterations are re-set to be 500. 



********************
// SOFTWARE NOTES //
********************

Stata programs make extensive use of two packages not included by default. Both are available via ssc install.

1. reghdfe
http://scorreia.com/software/reghdfe/

2. esttab/estout
http://repec.org/bocode/e/estout/esttab.html

