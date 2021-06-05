*******************************************************************************
* HDPS Package Demo
* -----------------------------------------------------------------------------
* Author: 		John Tazare
* Date created: Apr 2021
* Purpose: 		Run the HDPS command on the simulated datasets
*******************************************************************************

* Change working directory to GitHub repo data folder
cd "-insert-path-to-/HDPS-Stata-Demo/data"

*******************************************************************************
* Investigator analysis using pre-defined covariates
*******************************************************************************
use "cohort.dta", replace

* Create spline terms for age 
mkspline age_c = age , cubic nknots(4)

* Estimate propensity scores using logistic regression
logit trt age_c1 age_c2 age_c3 female ses smoke alc bmicat nsaid_rx cancer hyper 
predict pscore

* Inspect PS distributions
hist pscore, by(trt) name(investigator, replace)
graph export "../output/figs/propensity_score_dist_investigator.png", width(2000) replace

* Generate inverse probability of treatment weights
gen wts = 1/ps if trt == 1
replace wts = 1/(1-ps) if trt == 0

* Estimate treatment effect
logistic outcome i.trt [pw=wts], robust // OR = 1.01

*******************************************************************************
* HDPS analysis using pre-defined and HDPS covariates
*******************************************************************************
* Create post file for effect estimates in output folder called
* 'hdpsResults'

tempname john 
postfile `john' str4(num_vars) float(es ll ul) using "../output/hdpsResults", replace 

* Loop through the 2 sets of HDPS covariates
foreach v in 50 100 {

* Load cohort data
use "cohort.dta", replace

* Merge the HDPS covariates 
merge 1:1 patid using "../output/example_hdps_covariates_top_`v'.dta", assert(match) nogen

* Create spline terms for age 
mkspline age_c = age , cubic nknots(4)

* Increase matrix size (need when adjusting for a large number of covs.)
set matsize 200

* Estimate propensity scores ("d1* d2*" includes the HDPS covariates)
logit trt age_c1 age_c2 age_c3 female ses smoke alc bmicat nsaid_rx cancer hyper d1* d2*
predict pscore

* Inspect PS distributions
hist pscore, by(trt) name(top_`v', replace)
graph export "../output/figs/propensity_score_dist_top_`v'.png", width(2000) replace

* Generate inverse probability of treatment weights
gen wts = 1/ps if trt == 1
replace wts = 1/(1-ps) if trt == 0

* Estimate treatment effect
logistic  outcome i.trt [pw=wts], robust

mat b =r(table)
mat list b
local es = b[1,2]
local ll = b[5,2]
local ul = b[6,2]


post `john' ("`v'") (`es') (`ll') (`ul') 
 
}

postclose `john'   
  

