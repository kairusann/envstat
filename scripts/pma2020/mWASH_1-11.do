/*
** mWASH Data Report
** Last updated: Jan 2, 2015  
** 
** 
** For Nigeria mWASH analsis
** 
*/
clear all
set more off 
capture log close 

cd ..\
use "Data\NGR1_WealthWeightCompleteHH_2Jan2015.dta"

** Keep only completed/consented survey
keep if HHQ_result==1

** State switch
keep if state == "Lagos"
ren wealthquintile_Lagos wealthquintile

******** Number of de jure occupants per household 
gen is_dejure:yesno = 0 if usual_member == 2
replace is_dejure = 1 if usual_member != 2
bysort metainstanceID: egen dejure=total(is_dejure)
replace dejure=1 if dejure < 1

******** Household Tag Generation
egen HHtag = tag(metainstanceID)


******** Base Population 
total dejure if HHtag==1
mat N_tot = e(b)
total dejure if HHtag==1, over(ur)
mat N_ur = e(b)
total dejure if HHtag==1, over(wealthquintile)
mat N_wealth = e(b)

*****************************************************************
**|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||**
*************** WASH 1 Number of Water Sources  *****************
**|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||**
*****************************************************************

******** Number of Sources
egen nsources = cut(number_of_sources), at(1,2,3)
replace nsources = 3 if number_of_sources >= 3

******** Percentage
egen N_tot = total(dejure*HHtag)
egen N_ur = total(dejure*HHtag*(ur==1))
egen N_ru = total(dejure*HHtag*(ur==2))
egen N_wt = total(dejure*HHtag*HHweight)
egen N_ur_wt = total(dejure*HHtag*HHweight*(ur==1))
egen N_ru_wt = total(dejure*HHtag*HHweight*(ur==2))
egen N_poorest_wt = total(dejure*HHtag*HHweight*(wealthquintile==1))
egen N_second_wt = total(dejure*HHtag*HHweight*(wealthquintile==2))
egen N_middle_wt = total(dejure*HHtag*HHweight*(wealthquintile==3))
egen N_fourth_wt = total(dejure*HHtag*HHweight*(wealthquintile==4))
egen N_wealthiest_wt = total(dejure*HHtag*HHweight*(wealthquintile==5))

gen p_tot = 100*dejure*HHtag*HHweight/N_wt
gen p_ur = 100*dejure*HHtag*HHweight*(ur==1)/N_ur_wt
gen p_ru = 100*dejure*HHtag*HHweight*(ur==2)/N_ru_wt
gen p_poorest = 100*dejure*HHtag*HHweight*(wealthquintile==1)/N_poorest_wt
gen p_second = 100*dejure*HHtag*HHweight*(wealthquintile==2)/N_second_wt
gen p_middle = 100*dejure*HHtag*HHweight*(wealthquintile==3)/N_middle_wt
gen p_fourth = 100*dejure*HHtag*HHweight*(wealthquintile==4)/N_fourth_wt
gen p_wealthiest = 100*dejure*HHtag*HHweight*(wealthquintile==5)/N_wealthiest_wt


******** Tabulation
total dejure if HHtag==1, over(nsources)
mat N_source = e(b)

tab ur nsources if is_dejure [aw=HHweight], row

preserve
collapse (sum) p_tot p_ur p_ru p_poorest p_second p_middle p_fourth p_wealthiest, by(nsources)
foreach pvar in p_tot p_ur p_ru p_poorest p_second p_middle p_fourth p_wealthiest {
	replace `pvar' = `pvar'/(1-`pvar'[4]) if `pvar'[4]!=.
}
keep in 1/3
mkmat p_tot p_ur p_ru p_poorest p_second p_middle p_fourth p_wealthiest, matrix(WASH1_p)
restore	

mat WASH1_tot = .,100,100,100,100,100,100,100,100
mat WASH1 = ((N_tot,.,N_ur,N_wealth)\(N_source',WASH1_p))',WASH1_tot'
mat roweq WASH1 = ""
mat coleq WASH1 = ""
mat colnames WASH1= N One Two Three+ Total
mat rownames WASH1=N %Pop Urban Rural Lowest Fourth Middle Second Wealthiest

mat2txt2 WASH1 using "Round 1 indicators\WASH1.csv", com replace format(%12.2f)


*****************************************************************
**|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||**
*************** WASH 2 Drinking Water Sources *******************
**|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||**
*****************************************************************

input str60 watersourcelist
	piped_indoor
	piped_yard
	piped_public
	tubewell
	protected_dug_well
	unprotected_dug_well
	protected_spring
	unprotected_spring
	rainwater
	tanker
	cart
	surface_water
	bottled
	sachet
end

gen water_sources_drinking_final:watersourcelist = water_sources_main_drinking
gen water_sources_other_final:watersourcelist = water_sources_main_other

forvalue i=1/14 {
	replace water_sources_drinking_final = `i' if water_sources_all == watersourcelist[`i']
	replace water_sources_other_final = `i' if water_sources_all == watersourcelist[`i']
}


******** Grouped Main Water Sources 
recode water_sources_drinking_final (1 2 = 1 "Piped into dwelling/yard/plot") /// 
									(3 = 2 "Public tap/standpipe") ///
									(4 = 3 "Tube well or borehole") ///
									(5 = 4 "Protected well") ///
									(7 = 5 "Protected spring") ///
									(9 = 6 "Rainwater") ///
									(13 = 7 "Bottled water") ///
									(6 = 8 "Unprotected well") ///
									(8 = 9 "Unprotected spring") ///
									(10 11 = 10 "Tanker truck/cart with drum") ///
									(12 = 11 "Surface water") ///
									(14 = 12 "Sachet water") /// 
									(. = 13 "Other/Missing"), gen(WASH2_main_drinking)
replace WASH2_main_drinking = . if WASH2_main_drinking < 0

/* Not able to show empty categories!
preserve
collapse (sum) p_ur p_ru p_tot, by(WASH2_main_drinking)
mkmat p_ur p_ru p_tot, mat(WASH2_main_drinking)
restore
*/ 

mat WASH2_main_drinking = 0,0,0,0,0,0,0,0,0,0,0,0,0\ ///
				0,0,0,0,0,0,0,0,0,0,0,0,0\ ///
				0,0,0,0,0,0,0,0,0,0,0,0,0

forvalues i = 1/13 {
	egen tmp1 = total(p_ur*(WASH2_main_drinking==`i'))
	egen tmp2 = total(p_ru*(WASH2_main_drinking==`i'))
	egen tmp3 = total(p_tot*(WASH2_main_drinking==`i'))
	mat WASH2_main_drinking[1,`i'] = tmp1[1]
	mat WASH2_main_drinking[2,`i'] = tmp2[1]
	mat WASH2_main_drinking[3,`i'] = tmp3[1]
	drop tmp*
}

mat WASH2_main_drinking = WASH2_main_drinking'

mat WASH2_main_improved = WASH2_main_drinking[1..1,.]+WASH2_main_drinking[2..2,.]+WASH2_main_drinking[3..3,.]+WASH2_main_drinking[4..4,.]+WASH2_main_drinking[5..5,.]+WASH2_main_drinking[6..6,.]+WASH2_main_drinking[7..7,.]
mat WASH2_main_unimproved = WASH2_main_drinking[8..8,.]+WASH2_main_drinking[9..9,.]+WASH2_main_drinking[10..10,.]+WASH2_main_drinking[11..11,.]+WASH2_main_drinking[12..12,.]

mat WASH2_main_N = N_ur,N_tot

mat WASH2_main = WASH2_main_improved\WASH2_main_drinking[1..7,.]\WASH2_main_unimproved\WASH2_main_drinking[8..13,.]\WASH2_main_N

******** Grouped Regular Drinking Sources 

******* Improved Regular Drinking Sources
**     
**  1,2	Piped Water: into dwelling/indoor/yard/plot
**  3	Piped Water: Public tap/standpipe
**  4	Tube well or borehole
**  5	Dug Well: Protected Well
**  7	Water from Spring: Protected Spring
**  9	Rainwater
**

gen improved_drinking_indoor=0
replace improved_drinking_indoor = regexm(water_uses_1,"drinking")|regexm(water_uses_2,"drinking")
gen improved_drinking_tap = 0
replace improved_drinking_tap = regexm(water_uses_3,"drinking")
gen improved_drinking_tube = 0
replace improved_drinking_tube = regexm(water_uses_4,"drinking")
gen improved_drinking_well = 0
replace improved_drinking_well = regexm(water_uses_5,"drinking")
gen improved_drinking_spring = 0 
replace improved_drinking_spring = regexm(water_uses_7,"drinking")
gen improved_drinking_rain = 0 
replace improved_drinking_rain = regexm(water_uses_9,"drinking")
gen improved_drinking_bottled = 0 
replace improved_drinking_bottled = regexm(water_uses_13,"drinking")


******* Unimproved Regular Drinking Sources
**  
**  6		Dug Well: Unprotected Well
**  8		Water from Spring: Unprotected Spring
**  10,11	Tanker Truck/Cart with Small Tank
**  12		Surface water
**

gen unimproved_drinking_well = 0
replace unimproved_drinking_well = regexm(water_uses_6,"drinking")
gen unimproved_drinking_spring = 0 
replace unimproved_drinking_spring = regexm(water_uses_8,"drinking")
gen unimproved_drinking_tank = 0
replace unimproved_drinking_tank = regexm(water_uses_10,"drinking")|regexm(water_uses_11,"drinking")
gen unimproved_drinking_surface = 0 
replace unimproved_drinking_surface = regexm(water_uses_12,"drinking")
gen unimproved_drinking_sachet = 0 
replace unimproved_drinking_sachet = regexm(water_uses_14,"drinking")


gen improved_drinking_sources = 0 
replace improved_drinking_sources = 1 if regexm(water_uses_1,"drinking")|regexm(water_uses_2,"drinking")|regexm(water_uses_3,"drinking")|regexm(water_uses_4,"drinking")|regexm(water_uses_5,"drinking")|regexm(water_uses_7,"drinking")|regexm(water_uses_9,"drinking")|regexm(water_uses_13,"drinking")
gen unimproved_drinking_sources = 0
replace unimproved_drinking_sources = 1 if regexm(water_uses_6,"drinking")|regexm(water_uses_8,"drinking")|regexm(water_uses_10,"drinking")|regexm(water_uses_11,"drinking")|regexm(water_uses_12,"drinking")|regexm(water_uses_14,"drinking")

/*
gen unimproved_sources=0
replace unimproved_sources = 1 if water_uses_6!=""|water_uses_8!=""|water_uses_10!=""|water_uses_11!=""|water_uses_12!=""
gen improved_sources = 0
replace improved_sources=1 if unimproved_sources!=1

******* Bottled Water/Sachet Water as alternative drinking sources
**
**  13,14	Bottled Water/Sachet Water
**


gen improved_drinking_bottle=0
replace improved_drinking_bottle=1 if regexm(water_uses_13,"drinking")|regexm(water_uses_14,"drinking")&improved_sources
gen unimproved_drinking_bottle=0
replace unimproved_drinking_bottle=1 if regexm(water_uses_13,"drinking")|regexm(water_uses_14,"drinking")&unimproved_sources
*/


gen water_uses_drinking=0
forvalue i=1/14{
	replace water_uses_drinking=1 if regexm(water_uses_`i',"drinking")
}

gen regular_others=0
replace regular_others = 1 if water_sources_all=="-99"

** Denominators
egen N_regular = total(water_uses_drinking*dejure*HHtag)
egen N_regular_ur = total(water_uses_drinking*(ur==1)*dejure*HHtag)
egen N_regular_ru = total(water_uses_drinking*(ur==2)*dejure*HHtag)
egen N_regular_wt = total(water_uses_drinking*dejure*HHtag*HHweight)
egen N_regular_ur_wt = total(water_uses_drinking*(ur==1)*dejure*HHtag*HHweight)
egen N_regular_ru_wt = total(water_uses_drinking*(ur==2)*dejure*HHtag*HHweight)

** Percentage 
*********************************************************************************************************
gen p_improved_drinking_sources = 100*dejure*HHtag*HHweight*improved_drinking_sources/N_regular_wt
gen p_improved_drinking_indoor = 100*dejure*HHtag*HHweight*improved_drinking_indoor/N_regular_wt
gen p_improved_drinking_tap = 100*dejure*HHtag*HHweight*improved_drinking_tap/N_regular_wt
gen p_improved_drinking_tube = 100*dejure*HHtag*HHweight*improved_drinking_tube/N_regular_wt
gen p_improved_drinking_well = 100*dejure*HHtag*HHweight*improved_drinking_well/N_regular_wt
gen p_improved_drinking_spring = 100*dejure*HHtag*HHweight*improved_drinking_spring/N_regular_wt
gen p_improved_drinking_rain = 100*dejure*HHtag*HHweight*improved_drinking_rain/N_regular_wt
gen p_improved_drinking_bottle = 100*dejure*HHtag*HHweight*improved_drinking_bottle/N_regular_wt
gen p_unimproved_drinking_sources = 100*dejure*HHtag*HHweight*unimproved_drinking_sources/N_regular_wt
gen p_unimproved_drinking_well = 100*dejure*HHtag*HHweight*unimproved_drinking_well/N_regular_wt
gen p_unimproved_drinking_spring = 100*dejure*HHtag*HHweight*unimproved_drinking_spring/N_regular_wt
gen p_unimproved_drinking_tank = 100*dejure*HHtag*HHweight*unimproved_drinking_tank/N_regular_wt
gen p_unimproved_drinking_surface = 100*dejure*HHtag*HHweight*unimproved_drinking_surface/N_regular_wt
gen p_unimproved_drinking_sachet = 100*dejure*HHtag*HHweight*unimproved_drinking_sachet/N_regular_wt
gen p_regular_others = 100*dejure*HHtag*HHweight*regular_others/N_regular_wt
*********************************************************************************************************
gen p_improved_drinking_sources_ur = 100*dejure*HHtag*HHweight*improved_drinking_sources*(ur==1)/N_regular_ur_wt
gen p_improved_drinking_indoor_ur = 100*dejure*HHtag*HHweight*improved_drinking_indoor*(ur==1)/N_regular_ur_wt
gen p_improved_drinking_tap_ur = 100*dejure*HHtag*HHweight*improved_drinking_tap*(ur==1)/N_regular_ur_wt
gen p_improved_drinking_tube_ur = 100*dejure*HHtag*HHweight*improved_drinking_tube*(ur==1)/N_regular_ur_wt
gen p_improved_drinking_well_ur = 100*dejure*HHtag*HHweight*improved_drinking_well*(ur==1)/N_regular_ur_wt
gen p_improved_drinking_spring_ur = 100*dejure*HHtag*HHweight*improved_drinking_spring*(ur==1)/N_regular_ur_wt
gen p_improved_drinking_rain_ur = 100*dejure*HHtag*HHweight*improved_drinking_rain*(ur==1)/N_regular_ur_wt
gen p_improved_drinking_bottle_ur = 100*dejure*HHtag*HHweight*improved_drinking_bottle*(ur==1)/N_regular_ur_wt
gen p_unimproved_drinking_sources_ur = 100*dejure*HHtag*HHweight*unimproved_drinking_sources*(ur==1)/N_regular_ur_wt
gen p_unimproved_drinking_well_ur = 100*dejure*HHtag*HHweight*unimproved_drinking_well*(ur==1)/N_regular_ur_wt
gen p_unimproved_drinking_spring_ur = 100*dejure*HHtag*HHweight*unimproved_drinking_spring*(ur==1)/N_regular_ur_wt
gen p_unimproved_drinking_tank_ur = 100*dejure*HHtag*HHweight*unimproved_drinking_tank*(ur==1)/N_regular_ur_wt
gen p_unimproved_drinking_surface_ur = 100*dejure*HHtag*HHweight*unimproved_drinking_surface*(ur==1)/N_regular_ur_wt
gen p_unimproved_drinking_sachet_ur = 100*dejure*HHtag*HHweight*unimproved_drinking_sachet*(ur==1)/N_regular_ur_wt
gen p_regular_others_ur = 100*dejure*HHtag*HHweight*regular_others*(ur==1)/N_regular_ur_wt
*********************************************************************************************************
gen p_improved_drinking_sources_ru = 100*dejure*HHtag*HHweight*improved_drinking_sources*(ur==2)/N_regular_ru_wt
gen p_improved_drinking_indoor_ru = 100*dejure*HHtag*HHweight*improved_drinking_indoor*(ur==2)/N_regular_ru_wt
gen p_improved_drinking_tap_ru = 100*dejure*HHtag*HHweight*improved_drinking_tap*(ur==2)/N_regular_ru_wt
gen p_improved_drinking_tube_ru = 100*dejure*HHtag*HHweight*improved_drinking_tube*(ur==2)/N_regular_ru_wt
gen p_improved_drinking_well_ru = 100*dejure*HHtag*HHweight*improved_drinking_well*(ur==2)/N_regular_ru_wt
gen p_improved_drinking_spring_ru = 100*dejure*HHtag*HHweight*improved_drinking_spring*(ur==2)/N_regular_ru_wt
gen p_improved_drinking_rain_ru = 100*dejure*HHtag*HHweight*improved_drinking_rain*(ur==2)/N_regular_ru_wt
gen p_improved_drinking_bottle_ru = 100*dejure*HHtag*HHweight*improved_drinking_bottle*(ur==2)/N_regular_ru_wt
gen p_unimproved_drinking_sources_ru = 100*dejure*HHtag*HHweight*unimproved_drinking_sources*(ur==2)/N_regular_ru_wt
gen p_unimproved_drinking_well_ru = 100*dejure*HHtag*HHweight*unimproved_drinking_well*(ur==2)/N_regular_ru_wt
gen p_unimproved_drinking_spring_ru = 100*dejure*HHtag*HHweight*unimproved_drinking_spring*(ur==2)/N_regular_ru_wt
gen p_unimproved_drinking_tank_ru = 100*dejure*HHtag*HHweight*unimproved_drinking_tank*(ur==2)/N_regular_ru_wt
gen p_unimproved_drinking_surface_ru = 100*dejure*HHtag*HHweight*unimproved_drinking_surface*(ur==2)/N_regular_ru_wt
gen p_unimproved_drinking_sachet_ru = 100*dejure*HHtag*HHweight*unimproved_drinking_sachet*(ur==2)/N_regular_ru_wt
gen p_regular_others_ru = 100*dejure*HHtag*HHweight*regular_others*(ur==2)/N_regular_ru_wt

total p_improved_drinking_sources_ur p_improved_drinking_indoor_ur p_improved_drinking_tap_ur p_improved_drinking_tube_ur p_improved_drinking_well_ur ///
p_improved_drinking_spring_ur p_improved_drinking_rain_ur p_improved_drinking_bottle_ur p_unimproved_drinking_sources_ur p_unimproved_drinking_well_ur ///
p_unimproved_drinking_spring_ur p_unimproved_drinking_tank_ur p_unimproved_drinking_surface_ur p_unimproved_drinking_sachet_ur p_regular_others_ur
mat WASH2_regular = e(b)
total p_improved_drinking_sources_ru p_improved_drinking_indoor_ru p_improved_drinking_tap_ru p_improved_drinking_tube_ru p_improved_drinking_well_ru ///
p_improved_drinking_spring_ru p_improved_drinking_rain_ru p_improved_drinking_bottle_ru p_unimproved_drinking_sources_ru p_unimproved_drinking_well_ru ///
p_unimproved_drinking_spring_ru p_unimproved_drinking_tank_ru p_unimproved_drinking_surface_ru p_unimproved_drinking_sachet_ru p_regular_others_ru
mat WASH2_regular = WASH2_regular\e(b)
total p_improved_drinking_sources p_improved_drinking_indoor p_improved_drinking_tap p_improved_drinking_tube p_improved_drinking_well ///
p_improved_drinking_spring p_improved_drinking_rain p_improved_drinking_bottle p_unimproved_drinking_sources p_unimproved_drinking_well ///
p_unimproved_drinking_spring p_unimproved_drinking_tank p_unimproved_drinking_surface p_unimproved_drinking_sachet p_regular_others
mat WASH2_regular = WASH2_regular\e(b)
**mean N_regular_ur N_regular_ru N_regular
mat WASH2_regular = WASH2_regular'\WASH2_main_N

matrix WASH2_dhs =	77.6,6.1,9.6,45.8,13.1,0.3,0.8,1.8,22.2,4.7,1.2,3.6,4.1,8.6,0.2,70422\ ///
				47.7,0.8,4.7,30,11,0.5,0.5,0.2,52,26.2,4.2,0.6,20.3,0.7,0.3,106541\ ///
				59.6,2.9,6.6,36.3,11.8,0.4,0.6,0.8,40.1,17.6,3,1.8,13.9,3.8,0.3,176963

mat WASH2 = WASH2_dhs',WASH2_main,WASH2_regular
				
matrix colnames WASH2 = "DHS Urban"	"DHS Rural"	"DHS Total"	"PMA Main Urban"	"PMA Main Rural"	"PMA Main Total"	"PMA Regular Urban"	"PMA Regular Rural"	"PMA Regular Total"
matrix rownames WASH2 = "Improved source"	"Piped into dwelling/yard/plot"	"Public tap/standpipe"	"Tube well or borehole"	"Protected well"	"Protected spring"	"Rainwater"	"Bottled water"	"Non-improved source"	"Unprotected well"	"Unprotected spring"	"Tanker truck/cart"	"Surface water"	"Sachet water"	"Other/Missing"	"N"

mat2txt2 WASH2 using "Round 1 indicators\WASH2.csv", com replace format(%12.2f)

*****************************************************************
**|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||**
************* WASH 3 Mangement of child feces  ******************
**|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||**
*****************************************************************

gen N_feces_tmp = 0
replace N_feces_tmp = 1 if (child_feces!="-99") & (child_feces != "-88") & (child_feces != "") & is_dejure
egen N_feces_wt = total(N_feces_tmp*HHweight)
egen N_feces_ur = total((ur==1)*N_feces_tmp)
egen N_feces_ur_wt = total((ur==1)*N_feces_tmp*HHweight)
egen N_feces_ru = total((ur==2)*N_feces_tmp)
egen N_feces_ru_wt = total((ur==2)*N_feces_tmp*HHweight)
egen N_feces = total(N_feces_tmp)
drop N_feces_tmp

matrix WASH3 = 0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0\0,0,0,0,0,0
matrix rownames WASH3 = "Latrine/toilet" "Leave" "Bury" "Dispose in latrine" "Dispose with garbage" "Dispose with waste water" "Manure" "Burn" "N"
matrix colnames WASH3 = "Urban pop under 5" "Rural pop under 5" "All pop under 5" "Urban all" "Rural all" "Total"

matrix WASH3[9,1] = N_feces_ur[1]
matrix WASH3[9,2] = N_feces_ru[1]
matrix WASH3[9,3] = N_feces[1]
matrix WASH3[9,4] = N_ur[1]
matrix WASH3[9,5] = N_ru[1]
matrix WASH3[9,6] = N_tot[1]

input str60 child_feces_str
	latrine_used
	leave
	bury
	latrine_disposal
	garbage
	waste_water
	manure
	burn
end

forvalues i = 1/8 {
	egen tmp1 = total(100*regexm(child_feces,child_feces_str[`i'])*HHweight*(ur==1)/N_feces_ur_wt)
	egen tmp2 = total(100*regexm(child_feces,child_feces_str[`i'])*HHweight*(ur==2)/N_feces_ru_wt)
	egen tmp3 = total(100*regexm(child_feces,child_feces_str[`i'])*HHweight/N_feces_wt)
	egen tmp4 = total(100*regexm(child_feces,child_feces_str[`i'])*HHweight*(ur==1)/N_ur_wt)
	egen tmp5 = total(100*regexm(child_feces,child_feces_str[`i'])*HHweight*(ur==2)/N_ru_wt)
	egen tmp6 = total(100*regexm(child_feces,child_feces_str[`i'])*HHweight/N_wt)
	forvalues j = 1/6 {
		mat WASH3[`i',`j'] = tmp`j'[1]
	}
	drop tmp*
}

mat2txt2 WASH3 using "Round 1 indicators\WASH3.csv", com replace format(%12.2f)

*****************************************************************
**|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||**
******** WASH 4 Handwashing Stations and Conditions   ***********
**|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||**
*****************************************************************

gen haveplace = 0
replace haveplace = 1 if handwashing_place==1 & is_dejure
gen noplace = 0 
replace noplace = 1 if handwashing_place==0 & is_dejure
gen place = 0
replace place = 1 if haveplace==1 | noplace==1

gen hh_place_ur = 0
replace hh_place_ur = 1 if place==1 & ur==1
gen hh_place_ru = 0 
replace hh_place_ru = 1 if place==1 & ur==2

egen N_place_ur_wt = total(hh_place_ur*HHweight)
egen N_place_ru_wt = total(hh_place_ru*HHweight)
egen N_place_tot_wt = total(place*HHweight)


egen N_place_ur = total(hh_place_ur)
egen N_place_ru = total(hh_place_ru)
egen N_place_tot = total(place)

egen haveplace_ur = total((100*haveplace*(ur==1)*HHweight)/N_place_ur_wt)
egen noplace_ur = total((100*noplace*(ur==1)*HHweight)/N_place_ur_wt)

egen haveplace_ru = total((100*haveplace*(ur==2)*HHweight)/N_place_ru_wt)
egen noplace_ru = total((100*noplace*(ur==2)*HHweight)/N_place_ru_wt)

egen haveplace_tot = total((100*haveplace*HHweight)/N_place_tot_wt)
egen noplace_tot = total((100*noplace*HHweight)/N_place_tot_wt)

gen hh_1_4 = 0
replace hh_1_4 = 1 if (dejure >= 1) & (dejure <= 4) & place==1

egen N_1_4 = total(hh_1_4)
egen N_1_4_wt = total(hh_1_4*HHweight)

gen hh_5_9 = 0
replace hh_5_9 = 1 if (dejure >= 5) & (dejure <= 9) & place==1
egen N_5_9 = total(hh_5_9)
egen N_5_9_wt = total(hh_5_9*HHweight)

gen hh_10_14 = 0
replace hh_10_14 = 1 if (dejure >= 10) & (dejure <= 14) & place==1
egen N_10_14 = total(hh_10_14)
egen N_10_14_wt = total(hh_10_14*HHweight)

gen hh_15_inf = 0 
replace hh_15_inf = 1 if (dejure >= 15) & place==1
egen N_15_inf = total(hh_15_inf)
egen N_15_inf_wt = total(hh_15_inf*HHweight)

egen haveplace_1_4 = total((100*haveplace*hh_1_4*HHweight)/N_1_4_wt)
egen noplace_1_4 = total((100*noplace*hh_1_4*HHweight)/N_1_4_wt)

egen haveplace_5_9 = total((100*haveplace*hh_5_9*HHweight)/N_5_9_wt)
egen noplace_5_9 = total((100*noplace*hh_5_9*HHweight)/N_5_9_wt)

egen haveplace_10_14 = total((100*haveplace*hh_10_14*HHweight)/N_10_14_wt)
egen noplace_10_14 = total((100*noplace*hh_10_14*HHweight)/N_10_14_wt)

egen haveplace_15_inf = total((100*haveplace*hh_15_inf*HHweight)/N_15_inf_wt)
egen noplace_15_inf = total((100*noplace*hh_15_inf*HHweight)/N_15_inf_wt)

forvalue i = 1/5 {
	gen place_w`i' = 0
	replace place_w`i' = 1 if (wealthquintile==`i') & place == 1
	egen N_w`i' = total(place_w`i')
	egen N_w`i'_wt = total(place_w`i'*HHweight)
	egen haveplace_w`i' = total((100*haveplace*place_w`i'*HHweight)/N_w`i'_wt)
	egen noplace_w`i' = total((100*noplace*place_w`i'*HHweight)/N_w`i'_wt)
}

mat WASH4a = 0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0
mat rownames WASH4a = "HH 1-4 members" "HH 5-9 members" "HH 10-14 members" "HH 15+ members" "Urban" "Rural" "poorest" "second poorest" "middle" "second wealthiest" "wealthiest" "Total"
mat colnames WASH4a = "N" "Yes has a place" "No place" "Total"

** WASH4a[1,] = c(N_1_4,haveplace_1_4,noplace_1_4,haveplace_1_4+noplace_1_4)
mat WASH4a[1,1] = N_1_4[1]
mat WASH4a[1,2] = haveplace_1_4[1]
mat WASH4a[1,3] = noplace_1_4[1]
mat WASH4a[1,4] = haveplace_1_4[1]+noplace_1_4[1]
** WASH4a[2,] = c(N_5_9,haveplace_5_9,noplace_5_9,haveplace_5_9+noplace_5_9)
mat WASH4a[2,1] = N_5_9[1]
mat WASH4a[2,2] = haveplace_5_9[1]
mat WASH4a[2,3] = noplace_5_9[1]
mat WASH4a[2,4] = haveplace_5_9[1]+noplace_5_9[1]
** WASH4a[3,] = c(N_10_14,haveplace_10_14,noplace_10_14,haveplace_10_14+noplace_10_14)
mat WASH4a[3,1] = N_10_14[1]
mat WASH4a[3,2] = haveplace_10_14[1]
mat WASH4a[3,3] = noplace_10_14[1]
mat WASH4a[3,4] = haveplace_10_14[1]+noplace_10_14[1]
** WASH4a[4,] = c(N_15_inf,haveplace_15_inf,noplace_15_inf,haveplace_15_inf+noplace_15_inf)
mat WASH4a[4,1] = N_15_inf[1]
mat WASH4a[4,2] = haveplace_15_inf[1]
mat WASH4a[4,3] = noplace_15_inf[1]
mat WASH4a[4,4] = haveplace_15_inf[1]+noplace_15_inf[1]

** WASH4a[5,] = c(N_ur,haveplace_ur,noplace_ur,haveplace_ur+noplace_ur)
mat WASH4a[5,1] = N_ur[1]
mat WASH4a[5,2] = haveplace_ur[1]
mat WASH4a[5,3] = noplace_ur[1]
mat WASH4a[5,4] = haveplace_ur[1]+noplace_ur[1]

** WASH4a[6,] = c(N_ru,haveplace_ru,noplace_ru,haveplace_ru+noplace_ru)
mat WASH4a[6,1] = N_ru[1]
mat WASH4a[6,2] = haveplace_ru[1]
mat WASH4a[6,3] = noplace_ru[1]
mat WASH4a[6,4] = haveplace_ru[1]+noplace_ru[1]

** WASH4a[7,] = c(N_w1,haveplace_w1,noplace_w1,haveplace_w1+noplace_w1)
mat WASH4a[7,1] = N_w1[1]
mat WASH4a[7,2] = haveplace_w1[1]
mat WASH4a[7,3] = noplace_w1[1]
mat WASH4a[7,4] = haveplace_w1[1]+noplace_w1[1]

** WASH4a[8,] = c(N_w2,haveplace_w2,noplace_w2,haveplace_w2+noplace_w2)
mat WASH4a[8,1] = N_w2[1]
mat WASH4a[8,2] = haveplace_w2[1]
mat WASH4a[8,3] = noplace_w2[1]
mat WASH4a[8,4] = haveplace_w2[1]+noplace_w2[1]

** WASH4a[9,] = c(N_w3,haveplace_w3,noplace_w3,haveplace_w3+noplace_w3)
mat WASH4a[9,1] = N_w3[1]
mat WASH4a[9,2] = haveplace_w3[1]
mat WASH4a[9,3] = noplace_w3[1]
mat WASH4a[9,4] = haveplace_w3[1]+noplace_w3[1]

** WASH4a[10,] = c(N_w4,haveplace_w4,noplace_w4,haveplace_w4+noplace_w4)
mat WASH4a[10,1] = N_w4[1]
mat WASH4a[10,2] = haveplace_w4[1]
mat WASH4a[10,3] = noplace_w4[1]
mat WASH4a[10,4] = haveplace_w4[1]+noplace_w4[1]

** WASH4a[11,] = c(N_w5,haveplace_w5,noplace_w5,haveplace_w5+noplace_w5)
mat WASH4a[11,1] = N_w5[1]
mat WASH4a[11,2] = haveplace_w5[1]
mat WASH4a[11,3] = noplace_w5[1]
mat WASH4a[11,4] = haveplace_w5[1]+noplace_w5[1]

** WASH4a[12,] = c(N_tot,haveplace_tot,noplace_tot,haveplace_tot+noplace_tot)
mat WASH4a[12,1] = N_tot[1]
mat WASH4a[12,2] = haveplace_tot[1]
mat WASH4a[12,3] = noplace_tot[1]
mat WASH4a[12,4] = haveplace_tot[1]+noplace_tot[1]

***
*** WASH4b is bsaed on handwashing_place_observations 
** a  	Soap is present 
** b	Water source is present: stored water 
** c	Water source is present: tap water 
** d	Handwashing area is near a sanitation facility
/*
replace handwashing_place_observations=regexr(handwashing_place_observations,"4","d")
replace handwashing_place_observations=regexr(handwashing_place_observations,"3","c")
replace handwashing_place_observations=regexr(handwashing_place_observations,"2","b")
replace handwashing_place_observations=regexr(handwashing_place_observations,"1","a")
replace handwashing_place_observations=subinstr(handwashing_place_observations," ","",.)
*/
gen obs_place = 0 
replace obs_place = 1 if handwashing_place_observations != "" & is_dejure

gen obs_place_ur = obs_place*(ur==1)
gen obs_place_ru = obs_place*(ur==2)

egen N_obs_place_ur_wt = total(obs_place_ur*HHweight)
egen N_obs_place_ru_wt = total(obs_place_ru*HHweight)
egen N_obs_place_tot_wt = total(obs_place*HHweight)

egen N_obs_place_ur = total(obs_place_ur)
egen N_obs_place_ru = total(obs_place_ru)
egen N_obs_place_tot = total(obs_place)

gen hh_obs_place_1_4 = 0
replace hh_obs_place_1_4 = 1 if (dejure >= 1) & (dejure <= 4) & obs_place == 1
egen N_obs_place_1_4 = total(hh_obs_place_1_4)
egen N_obs_place_1_4_wt = total(hh_obs_place_1_4*HHweight)

gen hh_obs_place_5_9 = 0 
replace hh_obs_place_5_9 = 1 if (dejure >= 5) & (dejure <= 9) & obs_place == 1
egen N_obs_place_5_9 = total(hh_obs_place_5_9)
egen N_obs_place_5_9_wt = total(hh_obs_place_5_9*HHweight)

gen hh_obs_place_10_14 = 0 
replace hh_obs_place_10_14 = 1 if (dejure >= 10) & (dejure <= 14) & obs_place == 1
egen N_obs_place_10_14 = total(hh_obs_place_10_14)
egen N_obs_place_10_14_wt = total(hh_obs_place_10_14*HHweight)

gen hh_obs_place_15_inf = 0
replace hh_obs_place_15_inf = 1 if (dejure >= 15) & obs_place == 1
egen N_obs_place_15_inf = total(hh_obs_place_15_inf)
egen N_obs_place_15_inf_wt = total(hh_obs_place_15_inf*HHweight)

forvalue i=1/5 {
	gen obs_place_w`i' = 0
	replace obs_place_w`i' = 1 if (wealthquintile==`i') & obs_place == 1
	egen N_obs_place_w`i' = total(obs_place_w`i')
	egen N_obs_place_w`i'_wt = total(obs_place_w`i'*HHweight)
}

gen soap = 0
replace soap = 1 if regexm(handwashing_place_observations,"soap")
gen runningwater = 0
replace runningwater = 1 if regexm(handwashing_place_observations,"tap_water")
gen storedwater = 0
replace storedwater = 1 if regexm(handwashing_place_observations,"stored_water")
gen water = 0
replace water = 1 if runningwater==1 | storedwater==1
gen nearsan = 0
replace nearsan = 1 if regexm(handwashing_place_observations,"near_sanitation")
gen nothing = 0
replace nothing = 1 if regexm(handwashing_place_observations,"-77") | (soap!=1 & water!=1 & obs_place==1)
gen nowater = 0
replace nowater = 1 if water == 0
gen nosoap = 0
replace nosoap = 1 if soap == 0

mat WASH4b = 0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0
mat colnames WASH4b = "N" "Soap no water" "Water no soap" "Soap and Water" "No soap no water" "Total" "Near sanitation" "Soap water near sanitation"
mat rownames WASH4b = "HH 1-4 members" "HH 5-9 members" "HH 10-14 members" "HH 15+ members" "Urban" "Rural" "poorest" "second poorest" "middle" "second wealthiest" "wealthiest" "Total"
mat WASH4b[1,1] = N_obs_place_1_4[1]
egen tmp = total(100*soap*nowater*HHweight*hh_obs_place_1_4/N_obs_place_1_4_wt)
mat WASH4b[1,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*hh_obs_place_1_4/N_obs_place_1_4_wt)
mat WASH4b[1,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*hh_obs_place_1_4/N_obs_place_1_4_wt)
mat WASH4b[1,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*hh_obs_place_1_4/N_obs_place_1_4_wt)
mat WASH4b[1,5] = tmp[1]
drop tmp
mat WASH4b[1,6] = WASH4b[1,2]+WASH4b[1,3]+WASH4b[1,4]+WASH4b[1,5]
egen tmp = total(100*nearsan*HHweight*hh_obs_place_1_4/N_obs_place_1_4_wt)
mat WASH4b[1,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*hh_obs_place_1_4/N_obs_place_1_4_wt)
mat WASH4b[1,8] = tmp[1]
drop tmp

mat WASH4b[2,1] = N_obs_place_5_9[1]
egen tmp = total(100*soap*nowater*HHweight*hh_obs_place_5_9/N_obs_place_5_9_wt)
mat WASH4b[2,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*hh_obs_place_5_9/N_obs_place_5_9_wt)
mat WASH4b[2,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*hh_obs_place_5_9/N_obs_place_5_9_wt)
mat WASH4b[2,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*hh_obs_place_5_9/N_obs_place_5_9_wt)
mat WASH4b[2,5] = tmp[1]
drop tmp
mat WASH4b[2,6] = WASH4b[2,2]+WASH4b[2,3]+WASH4b[2,4]+WASH4b[2,5]
egen tmp = total(100*nearsan*HHweight*hh_obs_place_5_9/N_obs_place_5_9_wt)
mat WASH4b[2,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*hh_obs_place_5_9/N_obs_place_5_9_wt)
mat WASH4b[2,8] = tmp[1]
drop tmp

mat WASH4b[3,1] = N_obs_place_10_14[1]
egen tmp = total(100*soap*nowater*HHweight*hh_obs_place_10_14/N_obs_place_10_14_wt)
mat WASH4b[3,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*hh_obs_place_10_14/N_obs_place_10_14_wt)
mat WASH4b[3,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*hh_obs_place_10_14/N_obs_place_10_14_wt)
mat WASH4b[3,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*hh_obs_place_10_14/N_obs_place_10_14_wt)
mat WASH4b[3,5] = tmp[1]
drop tmp
mat WASH4b[3,6] = WASH4b[3,2]+WASH4b[3,3]+WASH4b[3,4]+WASH4b[3,5]
egen tmp = total(100*nearsan*HHweight*hh_obs_place_10_14/N_obs_place_10_14_wt)
mat WASH4b[3,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*hh_obs_place_10_14/N_obs_place_10_14_wt)
mat WASH4b[3,8] = tmp[1]
drop tmp

mat WASH4b[4,1] = N_obs_place_15_inf[1]
egen tmp = total(100*soap*nowater*HHweight*hh_obs_place_15_inf/N_obs_place_15_inf_wt)
mat WASH4b[4,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*hh_obs_place_15_inf/N_obs_place_15_inf_wt)
mat WASH4b[4,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*hh_obs_place_15_inf/N_obs_place_15_inf_wt)
mat WASH4b[4,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*hh_obs_place_15_inf/N_obs_place_15_inf_wt)
mat WASH4b[4,5] = tmp[1]
drop tmp
mat WASH4b[4,6] = WASH4b[4,2]+WASH4b[4,3]+WASH4b[4,4]+WASH4b[4,5]
egen tmp = total(100*nearsan*HHweight*hh_obs_place_15_inf/N_obs_place_15_inf_wt)
mat WASH4b[4,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*hh_obs_place_15_inf/N_obs_place_15_inf_wt)
mat WASH4b[4,8] = tmp[1]
drop tmp

mat WASH4b[5,1] = N_obs_place_ur[1]
egen tmp = total(100*soap*nowater*HHweight*obs_place_ur/N_obs_place_ur_wt)
mat WASH4b[5,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*obs_place_ur/N_obs_place_ur_wt)
mat WASH4b[5,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*obs_place_ur/N_obs_place_ur_wt)
mat WASH4b[5,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*obs_place_ur/N_obs_place_ur_wt)
mat WASH4b[5,5] = tmp[1]
drop tmp
mat WASH4b[5,6] = WASH4b[5,2]+WASH4b[5,3]+WASH4b[5,4]+WASH4b[5,5]
egen tmp = total(100*nearsan*HHweight*obs_place_ur/N_obs_place_ur_wt)
mat WASH4b[5,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*obs_place_ur/N_obs_place_ur_wt)
mat WASH4b[5,8] = tmp[1]
drop tmp

mat WASH4b[6,1] = N_obs_place_ru[1]
egen tmp = total(100*soap*nowater*HHweight*obs_place_ru/N_obs_place_ru_wt)
mat WASH4b[6,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*obs_place_ru/N_obs_place_ru_wt)
mat WASH4b[6,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*obs_place_ru/N_obs_place_ru_wt)
mat WASH4b[6,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*obs_place_ru/N_obs_place_ru_wt)
mat WASH4b[6,5] = tmp[1]
drop tmp
mat WASH4b[6,6] = WASH4b[6,2]+WASH4b[6,3]+WASH4b[6,4]+WASH4b[6,5]
egen tmp = total(100*nearsan*HHweight*obs_place_ru/N_obs_place_ru_wt)
mat WASH4b[6,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*obs_place_ru/N_obs_place_ru_wt)
mat WASH4b[6,8] = tmp[1]
drop tmp

mat WASH4b[7,1] = N_obs_place_w1[1]
egen tmp = total(100*soap*nowater*HHweight*obs_place_w1/N_obs_place_w1_wt) 
mat WASH4b[7,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*obs_place_w1/N_obs_place_w1_wt)
mat WASH4b[7,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*obs_place_w1/N_obs_place_w1_wt)
mat WASH4b[7,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*obs_place_w1/N_obs_place_w1_wt)
mat WASH4b[7,5] = tmp[1]
drop tmp
mat WASH4b[7,6] = WASH4b[7,2]+WASH4b[7,3]+WASH4b[7,4]+WASH4b[7,5]
egen tmp = total(100*nearsan*HHweight*obs_place_w1/N_obs_place_w1_wt)
mat WASH4b[7,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*obs_place_w1/N_obs_place_w1_wt)
mat WASH4b[7,8] = tmp[1]
drop tmp


mat WASH4b[8,1] = N_obs_place_w2[1]
egen tmp = total(100*soap*nowater*HHweight*obs_place_w2/N_obs_place_w2_wt) 
mat WASH4b[8,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*obs_place_w2/N_obs_place_w2_wt)
mat WASH4b[8,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*obs_place_w2/N_obs_place_w2_wt)
mat WASH4b[8,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*obs_place_w2/N_obs_place_w2_wt)
mat WASH4b[8,5] = tmp[1]
drop tmp
mat WASH4b[8,6] = WASH4b[8,2]+WASH4b[8,3]+WASH4b[8,4]+WASH4b[8,5]
egen tmp = total(100*nearsan*HHweight*obs_place_w2/N_obs_place_w2_wt)
mat WASH4b[8,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*obs_place_w2/N_obs_place_w2_wt)
mat WASH4b[8,8] = tmp[1]
drop tmp


mat WASH4b[9,1] = N_obs_place_w3[1]
egen tmp = total(100*soap*nowater*HHweight*obs_place_w3/N_obs_place_w3_wt) 
mat WASH4b[9,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*obs_place_w3/N_obs_place_w3_wt)
mat WASH4b[9,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*obs_place_w3/N_obs_place_w3_wt)
mat WASH4b[9,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*obs_place_w3/N_obs_place_w3_wt)
mat WASH4b[9,5] = tmp[1]
drop tmp
mat WASH4b[9,6] = WASH4b[9,2]+WASH4b[9,3]+WASH4b[9,4]+WASH4b[9,5]
egen tmp = total(100*nearsan*HHweight*obs_place_w3/N_obs_place_w3_wt)
mat WASH4b[9,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*obs_place_w3/N_obs_place_w3_wt)
mat WASH4b[9,8] = tmp[1]
drop tmp


mat WASH4b[10,1] = N_obs_place_w4[1]
egen tmp = total(100*soap*nowater*HHweight*obs_place_w4/N_obs_place_w4_wt) 
mat WASH4b[10,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*obs_place_w4/N_obs_place_w4_wt)
mat WASH4b[10,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*obs_place_w4/N_obs_place_w4_wt)
mat WASH4b[10,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*obs_place_w4/N_obs_place_w4_wt)
mat WASH4b[10,5] = tmp[1]
drop tmp
mat WASH4b[10,6] = WASH4b[10,2]+WASH4b[10,3]+WASH4b[10,4]+WASH4b[10,5]
egen tmp = total(100*nearsan*HHweight*obs_place_w4/N_obs_place_w4_wt)
mat WASH4b[10,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*obs_place_w4/N_obs_place_w4_wt)
mat WASH4b[10,8] = tmp[1]
drop tmp


mat WASH4b[11,1] = N_obs_place_w5[1]
egen tmp = total(100*soap*nowater*HHweight*obs_place_w5/N_obs_place_w5_wt) 
mat WASH4b[11,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*obs_place_w5/N_obs_place_w5_wt)
mat WASH4b[11,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*obs_place_w5/N_obs_place_w5_wt)
mat WASH4b[11,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*obs_place_w5/N_obs_place_w5_wt)
mat WASH4b[11,5] = tmp[1]
drop tmp
mat WASH4b[11,6] = WASH4b[11,2]+WASH4b[11,3]+WASH4b[11,4]+WASH4b[11,5]
egen tmp = total(100*nearsan*HHweight*obs_place_w5/N_obs_place_w5_wt)
mat WASH4b[11,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*obs_place_w5/N_obs_place_w5_wt)
mat WASH4b[11,8] = tmp[1]
drop tmp


mat WASH4b[12,1] = N_obs_place_tot[1]
egen tmp = total(100*soap*nowater*HHweight*obs_place/N_obs_place_tot_wt) 
mat WASH4b[12,2] = tmp[1]
drop tmp
egen tmp = total(100*water*nosoap*HHweight*obs_place/N_obs_place_tot_wt)
mat WASH4b[12,3] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*HHweight*obs_place/N_obs_place_tot_wt)
mat WASH4b[12,4] = tmp[1]
drop tmp
egen tmp = total(100*nothing*HHweight*obs_place/N_obs_place_tot_wt)
mat WASH4b[12,5] = tmp[1]
drop tmp
mat WASH4b[12,6] = WASH4b[12,2]+WASH4b[12,3]+WASH4b[12,4]+WASH4b[12,5]
egen tmp = total(100*nearsan*HHweight*obs_place/N_obs_place_tot_wt)
mat WASH4b[12,7] = tmp[1]
drop tmp
egen tmp = total(100*soap*water*nearsan*HHweight*obs_place/N_obs_place_tot_wt)
mat WASH4b[12,8] = tmp[1]
drop tmp

** WASH4b[,6] = rowSums(WASH4b[,2:5])
mat WASH4 = WASH4a,WASH4b
mat2txt2 WASH4 using "Round 1 indicators\WASH4.csv", com replace format(%12.2f)

********   WASH 5 -- use of field/bush
*** 
** table bush_use

gen wash5_bush_use = bush_use
replace wash5_bush_use = dejure if bush_use > dejure // Usual member only!

egen tmp = cut(wash5_bush_use), at(-100,0,1,999)
recode tmp (1 = 0 "Yes") (0 = 1 "No") (-100 = 2 "No Response"), gen(wash5_bush) label(wash5_bush)
drop tmp

preserve
collapse (sum) p_tot p_ur p_ru p_poorest p_second p_middle p_fourth p_wealthiest, by(wash5_bush)
decode wash5_bush, gen(wash5_bush2)
mkmat p_tot p_ur p_ru p_poorest p_second p_middle p_fourth p_wealthiest, matrix(wash5_bush) rownames(wash5_bush2)
restore

mat wash5_100 = wash5_bush["Yes",.]+wash5_bush["No",.]+wash5_bush["No_Response",.]

mat wash5_n = N_tot,N_ur,N_wealth
mat coleq wash5_n = ""

gen wash5_1 = 0 if bush_use > 0
replace wash5_1 = 1 if bush_use > 1

total p_tot p_ur p_ru p_poorest p_second p_middle p_fourth p_wealthiest if bush_use > 1
mat wash5_1 = e(b)
total p_tot p_ur p_ru p_poorest p_second p_middle p_fourth p_wealthiest if bush_use/dejure > 0.5
mat wash5_50 = e(b)
total p_tot p_ur p_ru p_poorest p_second p_middle p_fourth p_wealthiest if sanitation_main == 12 | /// 
                                                                          (regexm(sanitation_all,"bush") & sanitation_main==.)
mat wash5_main = e(b)

mat WASH5 = (wash5_n\wash5_bush\wash5_100\wash5_1\wash5_50\wash5_main)'

mat colnames WASH5 = "N" "Yes" "No" "No Response" "Total" "HHpop>1" "HHpop>50%" "Main"
mat rownames WASH5 = Total Urban Rural Poorest Second Middle Fourth Wealthiest

mat2txt2 WASH5 using "Round 1 indicators\WASH5.csv", com replace

********
*** WASH 6 seasonality and reliability

mat WASH6 = 0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0,0
mat colnames WASH6 = "N" "Always" "predictable" "unpredictable" "Total" "N" "All year" "Half year or more" "Less than half the year" "Total"
mat rownames WASH6 = "Piped into dwelling/indoor" "to yard/plot" "Piped Public tap/standpipe" "Tube well or borehole" "Dug Well: Protected Well" "Dug Well: Unprotected Well" "Water from Spring" "Rainwater" "Tanker Truck+Cart" "Surface water" "Bottled Water" "Sachet Water"

* 1		Piped Water: into dwelling/indoor
* 2  	Piped Water: to yard/plot
* 3		Piped Water: Public tap/standpipe
* 4		Tube well or borehole
* 5		Dug Well: Protected Well
* 6		Dug Well: Unprotected Well
* 7		Water from Spring: Protected Spring
* 8		Water from Spring: Unprotected Spring
* 9		Rainwater
* 10	Tanker Truck
* 11	Cart with Small Tank
* 12	Surface water (River / Dam / Lake / Pond / Stream / Canal / Irrigation Channel)
* 13	Bottled Water
* 14	Sachet Water

forvalue i=1/14 {
	replace water_reliability_`i' = 100 if water_reliability_`i'==. | water_reliability_`i' == -99
}

egen water_reliability_7_8_min = rowmin(water_reliability_7 water_reliability_8)
egen water_reliability_10_11_min = rowmin(water_reliability_10 water_reliability_11)

** rel1=reliability==1
forvalue i=1/6 {
	gen rel1_`i' = 0
	replace rel1_`i' = 1 if water_reliability_`i'==1
}

gen rel1_7 = 0
replace rel1_7 = 1 if water_reliability_7_8_min == 1
gen rel1_8 = 0
replace rel1_8 = 1 if water_reliability_9 == 1
gen rel1_9 = 0
replace rel1_9 = 1 if water_reliability_10_11_min == 1
gen rel1_10 = 0
replace rel1_10 = 1 if water_reliability_12 == 1
gen rel1_11 = 0
replace rel1_11 = 1 if water_reliability_13 == 1
gen rel1_12 = 0
replace rel1_12 = 1 if water_reliability_14 == 1

** rel2=reliability==2 
forvalue i=1/6 {
	gen rel2_`i' = 0
	replace rel2_`i' = 1 if water_reliability_`i'==2
}
gen rel2_7 = 0
replace rel2_7 = 1 if water_reliability_7_8_min == 2
gen rel2_8 = 0
replace rel2_8 = 1 if water_reliability_9 == 2
gen rel2_9 = 0
replace rel2_9 = 1 if water_reliability_10_11_min == 2
gen rel2_10 = 0
replace rel2_10 = 1 if water_reliability_12 == 2
gen rel2_11 = 0
replace rel2_11 = 1 if water_reliability_13 == 2
gen rel2_12 = 0
replace rel2_12 = 1 if water_reliability_14 == 2

** rel3=reliability==3 
forvalue i=1/6 {
	gen rel3_`i' = 0
	replace rel3_`i' = 1 if water_reliability_`i'== 3
}
gen rel3_7 = 0
replace rel3_7 = 1 if water_reliability_7_8_min == 3
gen rel3_8 = 0
replace rel3_8 = 1 if water_reliability_9 == 3
gen rel3_9 = 0
replace rel3_9 = 1 if water_reliability_10_11_min == 3
gen rel3_10 = 0
replace rel3_10 = 1 if water_reliability_12 == 3
gen rel3_11 = 0
replace rel3_11 = 1 if water_reliability_13 == 3
gen rel3_12 = 0
replace rel3_12 = 1 if water_reliability_14 == 3

forvalue i=1/12 {
	gen tmp = 0
	replace tmp = 1 if rel1_`i'==1 | rel2_`i'==1 | rel3_`i'==1
	egen N_reliability_`i' = total(tmp*HHtag)
	egen N_reliability_`i'_wt= total(tmp*HHweight*HHtag)
	mat WASH6[`i',1] = N_reliability_`i'[1]
	egen tmp1 = total(100*rel1_`i'*HHweight*HHtag/N_reliability_`i'_wt)
	mat WASH6[`i',2] = tmp1[1]
	drop tmp1
	egen tmp1 = total(100*rel2_`i'*HHweight*HHtag/N_reliability_`i'_wt)
	mat WASH6[`i',3] = tmp1[1]
	drop tmp1
	egen tmp1 = total(100*rel3_`i'*HHweight*HHtag/N_reliability_`i'_wt)
	mat WASH6[`i',4] = tmp1[1]
	drop tmp1
	mat WASH6[`i',5] = WASH6[`i',2]+WASH6[`i',3]+WASH6[`i',4]
	drop tmp
}


****SEASONALITY

* 1  a	Piped Water: into dwelling/indoor
* 2	 b	Piped Water: to yard/plot
* 3	 c	Piped Water: Public tap/standpipe
* 4	 d	Tube well or borehole
* 5	 e	Dug Well: Protected Well
* 6	 f	Dug Well: Unprotected Well
* 7	 g	Water from Spring: Protected Spring
* 8	 h	Water from Spring: Unprotected Spring
* 9	 i	Rainwater
* 10 j	Tanker Truck
* 11 k	Cart with Small Tank
* 12 l	Surface water (River / Dam / Lake / Pond / Stream / Canal / Irrigation Channel)
* 13 m	Bottled Water
* 14 n	Sachet Water


* Due to small numbers reporting their use, we want to combine both types of spring water (protected/unproteced).  
*  We also want to combine tanker and small cart. 
*
*  A household can have both tanker water and cart.  A household can have both protected and unprotected.  
*  In such cases, choose the response which reflects greater availbility. 

forvalue i=1/14 {
	replace water_seasonality_`i' = 100 if water_seasonality_`i'==. | water_seasonality_`i' == -99
}

egen water_seasonality_7_8_min = rowmin(water_seasonality_7 water_seasonality_8)
egen water_seasonality_10_11_min = rowmin(water_seasonality_10 water_seasonality_11)

** season1=seasonality==1
forvalue i=1/6 {
	gen season1_`i' = 0
	replace season1_`i' = 1 if water_seasonality_`i'==1
}

gen season1_7 = 0
replace season1_7 = 1 if water_seasonality_7_8_min == 1
gen season1_8 = 0
replace season1_8 = 1 if water_seasonality_9 == 1
gen season1_9 = 0
replace season1_9 = 1 if water_seasonality_10_11_min == 1
gen season1_10 = 0
replace season1_10 = 1 if water_seasonality_12 == 1
gen season1_11 = 0
replace season1_11 = 1 if water_seasonality_13 == 1
gen season1_12 = 0
replace season1_12 = 1 if water_seasonality_14 == 1

** season2=seasonality==2 
forvalue i=1/6 {
	gen season2_`i' = 0
	replace season2_`i' = 1 if water_seasonality_`i'==2
}
gen season2_7 = 0
replace season2_7 = 1 if water_seasonality_7_8_min == 2
gen season2_8 = 0
replace season2_8 = 1 if water_seasonality_9 == 2
gen season2_9 = 0
replace season2_9 = 1 if water_seasonality_10_11_min == 2
gen season2_10 = 0
replace season2_10 = 1 if water_seasonality_12 == 2
gen season2_11 = 0
replace season2_11 = 1 if water_seasonality_13 == 2
gen season2_12 = 0
replace season2_12 = 1 if water_seasonality_14 == 2

** season3=seasonality==3 
forvalue i=1/6 {
	gen season3_`i' = 0
	replace season3_`i' = 1 if water_seasonality_`i'== 3
}
gen season3_7 = 0
replace season3_7 = 1 if water_seasonality_7_8_min == 3
gen season3_8 = 0
replace season3_8 = 1 if water_seasonality_9 == 3
gen season3_9 = 0
replace season3_9 = 1 if water_seasonality_10_11_min == 3
gen season3_10 = 0
replace season3_10 = 1 if water_seasonality_12 == 3
gen season3_11 = 0
replace season3_11 = 1 if water_seasonality_13 == 3
gen season3_12 = 0
replace season3_12 = 1 if water_seasonality_14 == 3

forvalue i=1/12 {
	gen tmp = 0
	replace tmp = 1 if season1_`i'==1 | season2_`i'==1 | season3_`i'==1
	egen N_seasonality_`i' = total(tmp*HHtag)
	egen N_seasonality_`i'_wt= total(tmp*HHweight*HHtag)
	mat WASH6[`i',6] = N_seasonality_`i'[1]
	egen tmp1 = total(100*season1_`i'*HHweight*HHtag/N_seasonality_`i'_wt)
	mat WASH6[`i',7] = tmp1[1]
	drop tmp1
	egen tmp1 = total(100*season2_`i'*HHweight*HHtag/N_seasonality_`i'_wt)
	mat WASH6[`i',8] = tmp1[1]
	drop tmp1
	egen tmp1 = total(100*season3_`i'*HHweight*HHtag/N_seasonality_`i'_wt)
	mat WASH6[`i',9] = tmp1[1]
	drop tmp1
	mat WASH6[`i',10] = WASH6[`i',7]+WASH6[`i',8]+WASH6[`i',9]
	drop tmp
}

mat2txt2 WASH6 using "Round 1 indicators\WASH6.csv", com replace format(%12.2f)

** WASH 7 - Time spent collecting water

gen main_sources_type=.
replace main_sources_type=1 if water_sources_other_final == 1|water_sources_other_final == 2
replace main_sources_type=2 if water_sources_other_final == 3
replace main_sources_type=3 if water_sources_other_final == 4
replace main_sources_type=4 if water_sources_other_final == 5|water_sources_other_final == 6
replace main_sources_type=5 if water_sources_other_final == 7|water_sources_other_final == 8
replace main_sources_type=6 if water_sources_other_final == 9
replace main_sources_type=7 if water_sources_other_final == 10|water_sources_other_final == 11
replace main_sources_type=8 if water_sources_other_final == 12
replace main_sources_type=9 if water_sources_other_final == 13|water_sources_other_final == 14
label define main_sources_type 1 "Piped Dwelling" 2 "Piped Public" 3 "Tubewell or Borehole" 4 "Dug Well" 5 "Water from Spring" 6 "Rainwater" 7 "Tank" 8 "Surface Water" 9 "Bottle/Sachet"
label value main_sources_type main_sources_type

gen N_female_tot = is_dejure*(FRS_result==1)

egen age_grp = cut(age) if age>0, at(0,18,27,40,140) label
label define age_grp 0 "15-17" 1 "18-26" 2 "27-39" 3 "40+", modify

total N_female_tot
mat N_female_tot = e(b)
total N_female_tot, over(ur)
mat N_female_ur = e(b)
total N_female_tot, over(wealthquintile)
mat N_female_wealth = e(b)
total N_female_tot, over(age_grp)
mat N_female_age = e(b)
/* Not applicable to missing categories 
total N_female_tot, over(main_sources_type)
mat N_female_sources = e(b)
*/
mat N_female_sources = 0,0,0,0,0,0,0,0,0
forvalues i = 1/9 {
	egen tmp = total(N_female_tot*(main_sources_type==`i'))
	mat N_female_sources[1,`i'] = tmp[1]
	drop tmp
}

mat N_female_all = N_female_tot,N_female_ur,N_female_wealth,N_female_age,N_female_sources
mat coleq N_female_all = ""

******** Female Questionnare dinominators
** Urban/Wealth
egen N_female_tot_wt = total(is_dejure*FQweight*(FRS_result==1))
egen N_female_ur_wt = total(is_dejure*FQweight*(ur==1)*(FRS_result==1))
egen N_female_ru_wt = total((ur==2)*is_dejure*FQweight*(FRS_result==1))
egen N_female_wealthiest_wt = total(is_dejure*FQweight*(wealthquintile==5)*(FRS_result==1))
egen N_female_fourth_wt = total(is_dejure*FQweight*(wealthquintile==4)*(FRS_result==1))
egen N_female_middle_wt = total(is_dejure*FQweight*(wealthquintile==3)*(FRS_result==1))
egen N_female_second_wt = total(is_dejure*FQweight*(wealthquintile==2)*(FRS_result==1))
egen N_female_poorest_wt = total(is_dejure*FQweight*(wealthquintile==1)*(FRS_result==1))

** Age
egen N_female_15_17_wt = total(is_dejure*FQweight*(FRS_result==1)*(age_grp==0))
egen N_female_18_26_wt = total(is_dejure*FQweight*(FRS_result==1)*(age_grp==1))
egen N_female_27_39_wt = total(is_dejure*FQweight*(FRS_result==1)*(age_grp==2))
egen N_female_40_wt = total(is_dejure*FQweight*(FRS_result==1)*(age_grp==3))

** gen FQweight = (# of Women that the respondent represents) / (mean ((# of Women that the respondent represents)))
** Water Source
egen N_female_ab_wt = total(is_dejure*FQweight*(FRS_result==1)*((water_sources_other_final==1)|(water_sources_other_final==2)))
egen N_female_c_wt = total(is_dejure*FQweight*(FRS_result==1)*(water_sources_other_final==3))
egen N_female_d_wt = total(is_dejure*FQweight*(FRS_result==1)*(water_sources_other_final==4))
egen N_female_ef_wt = total(is_dejure*FQweight*(FRS_result==1)*((water_sources_other_final==5)|(water_sources_other_final==6)))
egen N_female_gh_wt = total(is_dejure*FQweight*(FRS_result==1)*((water_sources_other_final==7)|(water_sources_other_final==8)))
egen N_female_i_wt = total(is_dejure*FQweight*(FRS_result==1)*(water_sources_other_final==9))
egen N_female_jk_wt = total(is_dejure*FQweight*(FRS_result==1)*((water_sources_other_final==10)|(water_sources_other_final==11)))
egen N_female_l_wt = total(is_dejure*FQweight*(FRS_result==1)*(water_sources_other_final==12))
egen N_female_mn_wt = total(is_dejure*FQweight*(FRS_result==1)*((water_sources_other_final==13)|(water_sources_other_final==14)))

******** Female Questionnaire Percentage to be dissaggregated 

** Urban/Wealth
gen p_female_tot = 100*is_dejure*FQweight*(FRS_result==1)/N_female_tot_wt
gen p_female_urban = 100*is_dejure*FQweight*(ur==1)*(FRS_result==1)/N_female_ur_wt
gen p_female_rural = 100*is_dejure*FQweight*(ur==2)*(FRS_result==1)/N_female_ru_wt
gen p_female_wealthiest = 100*is_dejure*FQweight*(wealthquintile==5)*(FRS_result==1)/N_female_wealthiest_wt
gen p_female_fourth = 100*is_dejure*FQweight*(wealthquintile==4)*(FRS_result==1)/N_female_fourth_wt
gen p_female_middle = 100*is_dejure*FQweight*(wealthquintile==3)*(FRS_result==1)/N_female_middle_wt
gen p_female_second = 100*is_dejure*FQweight*(wealthquintile==2)*(FRS_result==1)/N_female_second_wt
gen p_female_poorest = 100*is_dejure*FQweight*(wealthquintile==1)*(FRS_result==1)/N_female_poorest_wt

******** Age Group
gen p_female_15_17 = 100*is_dejure*FQweight*(FRS_result==1)*(age_grp==0)/N_female_15_17_wt
gen p_female_18_26 = 100*is_dejure*FQweight*(FRS_result==1)*(age_grp==1)/N_female_18_26_wt
gen p_female_27_39 = 100*is_dejure*FQweight*(FRS_result==1)*(age_grp==2)/N_female_27_39_wt
gen p_female_40 = 100*is_dejure*FQweight*(FRS_result==1)*(age_grp==3)/N_female_40_wt

** Water Source
gen p_female_ab = 100*is_dejure*FQweight*(FRS_result==1)*((water_sources_other_final==1)|(water_sources_other_final==2))/N_female_ab_wt
gen p_female_c = 100*is_dejure*FQweight*(FRS_result==1)*(water_sources_other_final==3)/N_female_c_wt
gen p_female_d = 100*is_dejure*FQweight*(FRS_result==1)*(water_sources_other_final==4)/N_female_d_wt
gen p_female_ef = 100*is_dejure*FQweight*(FRS_result==1)*((water_sources_other_final==5)|(water_sources_other_final==6))/N_female_ef_wt
gen p_female_gh = 100*is_dejure*FQweight*(FRS_result==1)*((water_sources_other_final==7)|(water_sources_other_final==8))/N_female_gh_wt
gen p_female_i = 100*is_dejure*FQweight*(FRS_result==1)*(water_sources_other_final==9)/N_female_i_wt
gen p_female_jk = 100*is_dejure*FQweight*(FRS_result==1)*((water_sources_other_final==10)|(water_sources_other_final==11))/N_female_jk_wt
gen p_female_l = 100*is_dejure*FQweight*(FRS_result==1)*(water_sources_other_final==12)/N_female_l_wt
gen p_female_mn = 100*is_dejure*FQweight*(FRS_result==1)*((water_sources_other_final==13)|(water_sources_other_final==14))/N_female_mn_wt


replace collect_water_dry_value = 0 if collect_water_dry == 3| collect_water_dry == 4
replace collect_water_dry_value = collect_water_dry_value*60 if collect_water_dry == 2
replace collect_water_wet_value = 0 if collect_water_wet == 3| collect_water_wet == 4
replace collect_water_wet_value = collect_water_wet_value*60 if collect_water_wet == 2

egen collect_water_dry_time = cut(collect_water_dry_value), at(0,1,6,31,121) label
replace collect_water_dry_time = 4 if collect_water_dry_value > 120 & FRS_result==1
label define collect_water_dry_time 0 "No Time" 1 "1-5min" 2 "6-30min" 3 "30-120min" 4 "2hours+" , modify
egen collect_water_wet_time = cut(collect_water_wet_value), at(0,1,6,31,121) label
replace collect_water_wet_time = 4 if collect_water_wet_value > 120 & FRS_result==1
label define collect_water_wet_time 0 "No Time" 1 "1-5min" 2 "6-30min" 3 "30-120min" 4 "2hours+" , modify

preserve
collapse (sum) p_female_tot p_female_ur p_female_ru p_female_poorest p_female_second p_female_middle p_female_fourth p_female_wealthiest p_female_15_17 p_female_18_26 p_female_27_39 p_female_40 p_female_ab p_female_c p_female_d p_female_ef p_female_gh p_female_i p_female_jk p_female_l p_female_mn, by(collect_water_dry_time)
mkmat p_female_tot p_female_ur p_female_ru p_female_poorest p_female_second p_female_middle p_female_fourth p_female_wealthiest p_female_15_17 p_female_18_26 p_female_27_39 p_female_40 p_female_ab p_female_c p_female_d p_female_ef p_female_gh p_female_i p_female_jk p_female_l p_female_mn, matrix(WASH7_50)
restore
preserve
collapse (sum) p_female_tot p_female_ur p_female_ru p_female_poorest p_female_second p_female_middle p_female_fourth p_female_wealthiest p_female_15_17 p_female_18_26 p_female_27_39 p_female_40 p_female_ab p_female_c p_female_d p_female_ef p_female_gh p_female_i p_female_jk p_female_l p_female_mn, by(collect_water_wet_time)
mkmat p_female_tot p_female_ur p_female_ru p_female_poorest p_female_second p_female_middle p_female_fourth p_female_wealthiest p_female_15_17 p_female_18_26 p_female_27_39 p_female_40 p_female_ab p_female_c p_female_d p_female_ef p_female_gh p_female_i p_female_jk p_female_l p_female_mn, matrix(WASH7_51)
restore

mat WASH7 = N_female_all',(WASH7_50[1..5,.]\WASH7_51[1..5,.])'
mat rownames WASH7 = "Female Total" "Female Urban" "Female Rural" "Female Poorest" "Female Second" "Female Middle" "Female Fourth" "Female Wealthiest" "Female Age 15-17" "Female Age 18-26" "Female Age 27-39" "Female Age 40+" "Piped Water" "Public Tap" "Tubewell or Borehole" "Dug Well" "Water from Spring" "Rainwater" "Tank" "Surface Water" "Bottle/Sachet"
mat colnames WASH7 = "N" "No Time" "1-5min_dry" "6-30min_dry" "31-120min_dry" "2hours+dry" "No Time" "1-5min_wet" "6-30min_wet" "31-120min_dry" "2hours+wet"

mat2txt2 WASH7 using "Round 1 indicators/WASH7.csv", com replace format(%12.2f)


**** WASH9 Animal

**** Disaggregator for Number of Animals
** destring homestead_cows_bull, replace
recode cows_bull_homestead horses_homestead goats_homestead sheep_homestead chickens_homestead pigs_homestead (-99 -88 = .)
egen num_animal = rowtotal(cows_bull_homestead horses_homestead goats_homestead sheep_homestead chickens_homestead pigs_homestead)
egen animal_cut = cut(num_animal), at(0,1,16) label
replace animal_cut = 2 if animal_cut > 15
label define animal_cut 0 "0" 1 "1-15" 2 "15+", modify

** Disaggregator for Household Size
sum dejure, detail
egen HHsize = cut(dejure), at(1,3,6,9) label
replace HHsize = 3 if dejure >= 9
label define HHsize 0 "1-2" 1 "3-5" 2 "6-8" 3 "9+", modify

total dejure if HHtag==1, over(HHsize)
mat N_HHsize = e(b)

** Disaggregator for Floor Type
/*
           1 Earth/sand
           2 Dung
		   
           3 Wood Planks
           4 Palm/Bamboo
		   
           5 Parquet or polished wood
           6 Vinyl/asphalt
           7 Ceramic tile/terazzo
           8 Cement
           9 Woolen/synthetic carpet
          10 Linoleum/rubber carpet
          11 Other
*/

egen floortype = cut(floor), at(0,3,12) label
label define floortype 0 "Natural" 1 "Rudimentary/Completed", modify
label value floortype floortype

total dejure if HHtag==1, over(floortype)
mat N_floor = e(b)


egen N_HHsize1_4_wt = total(dejure*HHtag*HHweight*(HHsize==0))
egen N_HHsize5_9_wt = total(dejure*HHtag*HHweight*(HHsize==1))
egen N_HHsize10_14_wt = total(dejure*HHtag*HHweight*(HHsize==2))
egen N_HHsize15_wt = total(dejure*HHtag*HHweight*(HHsize==3))

egen N_natural_flr_wt = total(dejure*HHtag*HHweight*(floortype==0))
egen N_completed_flr_wt = total(dejure*HHtag*HHweight*(floortype==1))

gen p_HHsize1_4 = 100*dejure*HHtag*HHweight*(HHsize==0)/N_HHsize1_4_wt
gen p_HHsize5_9 = 100*dejure*HHtag*HHweight*(HHsize==1)/N_HHsize5_9_wt
gen p_HHsize10_14 = 100*dejure*HHtag*HHweight*(HHsize==2)/N_HHsize10_14_wt
gen p_HHsize15 = 100*dejure*HHtag*HHweight*(HHsize==3)/N_HHsize15_wt

gen p_natural_flr = 100*dejure*HHtag*HHweight*(floortype==0)/N_natural_flr_wt
gen p_completed_flr = 100*dejure*HHtag*HHweight*(floortype==1)/N_completed_flr_wt

preserve
collapse (sum) p_tot p_ur p_ru p_poorest p_second p_middle p_fourth p_wealthiest p_natural_flr p_completed_flr p_HHsize1_4 p_HHsize5_9 p_HHsize10_14 p_HHsize15, by(animal_cut)
mkmat p_tot p_ur p_ru p_poorest p_second p_middle p_fourth p_wealthiest p_natural_flr p_completed_flr p_HHsize1_4 p_HHsize5_9 p_HHsize10_14 p_HHsize15, matrix(WASH9)
restore
mat WASH9 = ((N_tot,N_ur,N_wealth,N_floor,N_HHsize)\WASH9)'
mat colnames WASH9 = "N" "0 Animal" "1-15 Animal" "15+ Animal"
mat rownames WASH9 = "Total" "Urban" "Rural" "Poorest" "Second" "Middle" "Fourth" "Wealthiest" "Natural" "Rudimentary/Completed" "HH 1_2" "HH 3_5" "HH 6_8" "HH 9+"
mat roweq WASH9 = ""
mat2txt2 WASH9 using "Round 1 indicators/WASH9.csv", com replace format(%12.2f)

**** WASH10 Household Sanitation Facility

** Main Sanitation Facility
replace sanitation_main = -99 if sanitation_all == "-99"
replace sanitation_main = 1 if sanitation_all == "flush_sewer"
replace sanitation_main = 2 if sanitation_all == "flush_septic"
replace sanitation_main = 3 if sanitation_all == "flush_elsewhere"
replace sanitation_main = 4 if sanitation_all == "flush_unknown"
replace sanitation_main = 5 if sanitation_all == "vip"
replace sanitation_main = 6 if sanitation_all == "pit_with_slab"
replace sanitation_main = 7 if sanitation_all == "pit_no_slab"
replace sanitation_main = 8 if sanitation_all == "composting"
replace sanitation_main = 9 if sanitation_all == "bucket"
replace sanitation_main = 10 if sanitation_all == "hanging"
replace sanitation_main = 11 if sanitation_all == "other"
replace sanitation_main = 12 if sanitation_all == "bush"
* temp fix for Kenya dataset
* replace sanitation_main = 6 if sanitation_main == . // pit_with_slab

gen sanitation_main_shared = .
forvalues i = 1/10 {
  replace sanitation_main_shared = shared_san_`i' if sanitation_main == `i'
}
label values sanitation_main_shared sharedsanlist

gen wash10_sanitation_main = .
replace wash10_sanitation_main = 1 if sanitation_main == 1
replace wash10_sanitation_main = 2 if sanitation_main == 2
replace wash10_sanitation_main = 3 if sanitation_main == 8
replace wash10_sanitation_main = 4 if sanitation_main == 5
replace wash10_sanitation_main = 5 if sanitation_main == 6
replace wash10_sanitation_main = 6 if sanitation_main_shared > 1 & sanitation_main > 0 // Any shared facillity - place here if includes only improved facility
replace wash10_sanitation_main = 7 if sanitation_main == 3|sanitation_main == 4
replace wash10_sanitation_main = 8 if sanitation_main == 7
replace wash10_sanitation_main = 9 if sanitation_main == 9|sanitation_main == 10
replace wash10_sanitation_main = 10 if sanitation_main == 11|sanitation_main == 12
**replace wash10_sanitation_main = 6 if sanitation_main_shared > 1 // Any shared facillity - place here if includes all shared facility
label define wash10_sanitation_main 1 "flush_sewer" 2 "flush_septic" 3 "composting" 4 "vip" 5 "pit_with_slab" 6 "any shared" 7 "flush_improperly" /// 
                                    8 "pit_no_slab" 9 "bucket/hanging" 10 "open_defecation"
label values wash10_sanitation_main wash10_sanitation_main

/*
preserve
collapse (sum) p_ur p_ru p_tot if wash10_sanitation_main!=., by(wash10_sanitation_main)
mkmat p_ur p_ru p_tot, mat(WASH10_perc)
restore
*/

mat WASH10_perc =	0,0,0,0,0,0,0,0,0,0\ ///
					0,0,0,0,0,0,0,0,0,0\ ///
					0,0,0,0,0,0,0,0,0,0
					
forvalues i = 1/10 {
	egen tmp1 = total(p_ur*(wash10_sanitation_main==`i'))
	egen tmp2 = total(p_ru*(wash10_sanitation_main==`i'))
	egen tmp3 = total(p_tot*(wash10_sanitation_main==`i'))
	mat WASH10_perc[1,`i'] = tmp1[1]
	mat WASH10_perc[2,`i'] = tmp2[1]
	mat WASH10_perc[3,`i'] = tmp3[1]
	drop tmp*
}

mat WASH10_perc = WASH10_perc'
/*
preserve
logout, clear: tab wash10_sanitation_main ur if wash10_sanitation_main!=-99 [aw=HHweight], column nofreq nolabel
destring t*, force replace
drop t1
drop if t4 == .
mkmat t*, matrix(WASH10_perc)
restore
*/

mat WASH10_imp = WASH10_perc[1..1,.]+WASH10_perc[2..2,.]+WASH10_perc[3..3,.]+WASH10_perc[4..4,.]+WASH10_perc[5..5,.]
mat WASH10_ump = WASH10_perc[6..6,.]+WASH10_perc[7..7,.]+WASH10_perc[8..8,.]+WASH10_perc[9..9,.]+WASH10_perc[10..10,.]

total dejure if HHtag==1 & wash10_sanitation_main!=., over(ur)
mat WASH10_N = e(b)
total dejure if HHtag==1 & wash10_sanitation_main!=.
mat WASH10_N = WASH10_N,e(b)

mat WASH10 = WASH10_imp\WASH10_perc[1..5,.]\WASH10_ump\WASH10_perc[6..10,.]\WASH10_N
mat colnames WASH10 = Urban Rural Total
mat rownames WASH10 = "Improved&Not shared" "Flush to sewer" "Flush to septic" "Composting" "VIP" "Pit with slab" /// 
					"Non-Improved" "Any shared Facilities" "Flush improperly" "Pit no slab" "Bucket/hanging" "Open defecation" "N"

mat2txt2 WASH10 using "Round 1 indicators/WASH10.csv", com replace format(%12.2f)
					
**** WASH11 Time spend on collecting main drinking water
gen water_collection_main = .
forvalue i=1/14 {
	replace water_collection_main = water_collection_`i' if water_sources_drinking_final==`i'
}

egen water_collection_int = cut(water_collection_main) if water_collection_main>=0, at(0,1,30) label
replace water_collection_int = 2 if water_collection_main>29
label define water_collection_int 0 "No Time" 1 "Less than 30min" 2 "30min or longer", modify

preserve
logout, clear: tab water_collection_int ur [iw=HHweight], column nofreq nolabel
drop t1
destring t*, force replace
drop if t4 == .
mkmat t*, matrix(wash11_perc)
restore
total dejure if HHtag==1 & water_collection_int!=., over(ur)
mat wash11_N = e(b)
total dejure if HHtag==1 & water_collection_int!=.
mat wash11_N = wash11_N,e(b)
mat WASH11 = wash11_perc\wash11_N
mat colnames WASH11 = Urban Rural Total
mat rownames WASH11 = "No Time" "Less than 30min" "30min or longer" "Total" "N"
mat2txt2 WASH11 using "Round 1 indicators/WASH11.csv", com replace format(%12.2f)
