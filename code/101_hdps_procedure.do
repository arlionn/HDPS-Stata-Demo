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
* HDPS procedure
*******************************************************************************

* Install github stata package and hdps package
net install github, from("https://haghish.github.io/github/")

github install johntaz/hdps 

* Load cohort data
use "cohort.dta", replace 

* Run HDPS setup to declare data dimensions and key variables
*******************************************************************************
hdps setup (clinical_dim, icd10 ever) 		///
		   (therapy_dim, bnf), 				///
			study(example) 					///
			save(../output) 				///
			patid(patid) 					/// 
			exp(trt) 						///
			out(outcome)

* Apply prevalence filter and select top 100 codes from each dimension
*******************************************************************************
hdps prevalence, top(100) 

* Assess feature recurrence
*******************************************************************************
hdps recurrence 

* Prioritize HDPS covariates using the Bross formula, selecting 50 and 100 vars.
*******************************************************************************
hdps prioritize, method(bross) top(50 100)

*******************************************************************************
* Graphically assess the selected codes
*******************************************************************************
clear all

* Load bias information from prioritize command
use "../output/example_bias_info.dta", replace 

* Generate a data dimension identifier
gen dimension=substr(code,1,2)
encode dimension, gen(dim)
drop dimension 

* Inspect the distribution of bross values for top 100 covariates
hdps graphics abs_log_bias rank if rank<=100, type(bross)
graph export "../output/figs/bross_formula_distribution.png", width(2000) replace

* Inspect covariate prevalence in each of the treatment groups  
hdps graphics pc1 pc0 if rank<=100, type(prevalence) dim(dim) legend(off)

* Vary prevalence limits
hdps graphics pc1 pc0 if rank<=100, type(prevalence) dim(dim) pr(1.5) legend(off) 
hdps graphics pc1 pc0 if rank<=100, type(prevalence) dim(dim) pr(3) legend(off) 

#delimit ;
hdps graphics pc1 pc0 if rank<=100, type(prevalence) 
									dim(dim) 
									legend(order(1 "Clinical" 2 "Therapy")
										   title("Data Dimensions",size(med))
										   cols(3)
										   rows(1)
											)
									ytitle("Prevalence in study drug users")
									xtitle("Prevalence in comparator drug users")
											
;
#delimit cr
graph export "../output/figs/covariate_prevalences.png", width(2000) replace

* Inspect covariate-treatment and covariate-outcome associations 
hdps graphics ce_strength cd_strength if rank<=100 , type(strength) dim(dim) legend(off)

#delimit ;
hdps graphics ce_strength cd_strength if rank<=100, type(strength) 
													dim(dim) 
													legend(
													order(1 "Clinical" 2 "Therapy")
													title("Data Dimensions",size(small))
													cols(3)
													rows(1)
													symxsize(*0.4)
													size(small)
													)
													ylabel(0.2 0.5 1 2 4, labsize(medsmall) angle(horizontal))  
													xlabel(0(0.2)1, labsize(medsmall) angle(horizontal)) 
													xscale(log) 
													yscale(log)
													ytitle("Strength of covariate-treatment association")
													xtitle("Strength of covariate-outcome association")
													
;
#delimit cr
graph export "../output/figs/covariate_associations.png", width(2000) replace
	
