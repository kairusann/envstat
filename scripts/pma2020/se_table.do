cd "C:\Users\Kyle\Dropbox\PMA mWASH analysis"

local is_improved1 HQ20_final=="a"|HQ20_final=="b"|HQ20_final=="c"|HQ20_final=="d"|HQ20_final=="e"|HQ20_final=="g"|HQ20_final=="i"
local is_unimproved1 HQ20_final=="f"|HQ20_final=="h"|HQ20_final=="j"|HQ20_final=="k"|HQ20_final=="l"
local is_bottled_improved1 (HQ20_final=="m"|HQ20_final=="n")&(HQ21_final=="a"|HQ21_final=="b"|HQ21_final=="c"|HQ21_final=="d"|HQ21_final=="e"|HQ21_final=="g"|HQ21_final=="i")
local is_bottled_unimproved1 (HQ20_final=="m"|HQ20_final=="n")&(HQ21_final=="f"|HQ21_final=="h"|HQ21_final=="j"|HQ21_final=="k"|HQ21_final=="l")

local is_improved2 water_main_drinking_final==1|water_main_drinking_final==2|water_main_drinking_final==3|water_main_drinking_final==4|water_main_drinking_final==5|water_main_drinking_final==7|water_main_drinking_final==9
local is_unimproved2 water_main_drinking_final==6|water_main_drinking_final==8|water_main_drinking_final==10|water_main_drinking_final==11|water_main_drinking_final==12
local is_bottled_improved2 (water_main_drinking_final==13|water_main_drinking_final==14)&(water_main_other_final==1|water_main_other_final==2|water_main_other_final==3|water_main_other_final==4|water_main_other_final==5|water_main_other_final==7|water_main_other_final==9)
local is_bottled_unimproved2 (water_main_drinking_final==13|water_main_drinking_final==14)&(water_main_other_final==6|water_main_other_final==8|water_main_other_final==10|water_main_other_final==11|water_main_other_final==12)

local alphabet "abcdefghijklmnopqrstuvwxyz"

tempfile EthiopiaR1_minimal EthiopiaR2_minimal GhanaR1_minimal GhanaR2_minimal KenyaR1_minimal KenyaR2_minimal

** Ghana R1
use "Ghana\Latest data files\GH_CombinedHHQXLSCSV_29May2014_CLEAN_WithLABELS_withwealth.dta", clear
keep if R==1 & HHtag==1

** Water Source
gen HQ20_final = HQ20
replace HQ20_final = HQ19 if !regexm(HQ19," ")
replace HQ20_final = substr(HQ19,1,1) if HQ20_final==""
gen HQ21_final = HQ21
replace HQ21_final = HQ19 if !regexm(HQ19," ")
replace HQ21_final = substr(HQ19,1,1) if HQ21_final==" "

label define improvedlist 0 "Unimproved" 1 "Improved"
gen improved_drinking_water:improvedlist = .
replace improved_drinking_water = 1 if `is_improved1'|`is_bottled_improved1'
replace improved_drinking_water = 0 if `is_unimproved1'|`is_bottled_unimproved1'

** Sanitation Facility
gen HQ28_final = HQ28
replace HQ28_final = HQ27 if !regexm(HQ27," ")
replace HQ28_final = substr(HQ27,1,1) if HQ28_final==" "

gen improved_main_facility:improvedlist = .
replace improved_main_facility = 1 if HQ28_final=="a"|HQ28_final=="b"|HQ28_final=="e"|HQ28_final=="f"|HQ28_final=="h"
replace improved_main_facility = 0 if HQ28_final=="c"|HQ28_final=="d"|HQ28_final=="g"|HQ28_final=="i"|HQ28_final=="j"|HQ28_final=="k"|HQ28_final=="l"

** Open Defecation
gen main_bush = HQ28
replace main_bush = HQ27 if HQ28==""|HQ28==" "
forvalues i = 1/11 {
	replace main_bush = "0" if regexm(main_bush,substr("`alphabet'",`i',1))
}
replace main_bush = "1" if regexm(main_bush,substr("`alphabet'",12,1))
destring main_bush, replace
replace main_bush = . if main_bush < 0

svyset EA [pweight=HHweight], strata(strata) singleunit(scaled)
egen num_EA = group(EA)

svy: proportion improved_drinking_water
mat water = r(table)
mat water = water[1..2,1]*100
gen improved_drinking_water_wt = improved_drinking_water*HHweight
xtset num_EA
xtreg improved_drinking_water_wt
mat water = water\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_drinking_water, deff
mat deff = e(Deff)
mat water = water\manual_deff\deff[1,1]

svy: proportion improved_main_facility
mat facility = r(table)
mat facility = facility[1..2,1]*100
gen improved_main_facility_wt = improved_main_facility*HHweight
xtset num_EA
xtreg improved_main_facility_wt
mat facility = facility\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_main_facility, deff
mat deff = e(Deff)
mat facility = facility\manual_deff\deff[1,1]

svy: proportion main_bush
mat bush = r(table)
mat bush = bush[1..2,2]*100
gen main_bush_wt = main_bush*HHweight
xtset num_EA
xtreg main_bush_wt
mat bush = bush\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab main_bush, deff
mat deff = e(Deff)
mat bush = bush\manual_deff\deff[1,1]

mat GhanaR1 = (_N\water\bush)'

keep EA HHweight strata improved_drinking_water improved_main_facility main_bush HHtag
save "`GhanaR1_minimal'",replace

** Ghana R2
use "Ghana\Latest data files\GHR2_WealthWeightAll_4Sep2014.dta", clear
keep if HHQ_result == 1 & HHtag == 1
egen strata = concat(Region ur), punct("-")

** Water Sources
gen water_main_drinking_final:watersourcelist = water_sources_main_drinking
replace water_main_drinking_final = 1 if water_sources_all == "piped_indoor"
replace water_main_drinking_final = 2 if water_sources_all == "piped_yard"
replace water_main_drinking_final = 3 if water_sources_all == "piped_public"
replace water_main_drinking_final = 4 if water_sources_all == "tubewell"
replace water_main_drinking_final = 5 if water_sources_all == "protected_dug_well"
replace water_main_drinking_final = 6 if water_sources_all == "unprotected_dug_well"
replace water_main_drinking_final = 7 if water_sources_all == "protected_spring"
replace water_main_drinking_final = 8 if water_sources_all == "unprotected_spring"
replace water_main_drinking_final = 9 if water_sources_all == "rainwater"
replace water_main_drinking_final = 10 if water_sources_all == "tanker"
replace water_main_drinking_final = 11 if water_sources_all == "cart"
replace water_main_drinking_final = 12 if water_sources_all == "surface_water"
replace water_main_drinking_final = 13 if water_sources_all == "bottled"
replace water_main_drinking_final = 14 if water_sources_all == "sachet"

gen water_main_other_final:watersourcelist = water_sources_main_other
replace water_main_other_final = 1 if water_sources_all == "piped_indoor"
replace water_main_other_final = 2 if water_sources_all == "piped_yard"
replace water_main_other_final = 3 if water_sources_all == "piped_public"
replace water_main_other_final = 4 if water_sources_all == "tubewell"
replace water_main_other_final = 5 if water_sources_all == "protected_dug_well"
replace water_main_other_final = 6 if water_sources_all == "unprotected_dug_well"
replace water_main_other_final = 7 if water_sources_all == "protected_spring"
replace water_main_other_final = 8 if water_sources_all == "unprotected_spring"
replace water_main_other_final = 9 if water_sources_all == "rainwater"
replace water_main_other_final = 10 if water_sources_all == "tanker"
replace water_main_other_final = 11 if water_sources_all == "cart"
replace water_main_other_final = 12 if water_sources_all == "surface_water"
replace water_main_other_final = 13 if water_sources_all == "bottled"
replace water_main_other_final = 14 if water_sources_all == "sachet"

label define improvedlist 0 "Unimproved" 1 "Improved"

gen improved_drinking_water:improvedlist = 1 if `is_improved2'|`is_bottled_improved2'
replace improved_drinking_water = 0 if `is_unimproved2'|`is_bottled_unimproved2'

** Sanitation Facilities
gen sanitation_main_final:sanitationlist = sanitation_main
replace sanitation_main_final = 1 if sanitation_all == "flush_sewer"
replace sanitation_main_final = 2 if sanitation_all == "flush_septic"
replace sanitation_main_final = 3 if sanitation_all == "flush_elsewhere"
replace sanitation_main_final = 4 if sanitation_all == "flush_unknown"
replace sanitation_main_final = 5 if sanitation_all == "vip"
replace sanitation_main_final = 6 if sanitation_all == "pit_with_slab"
replace sanitation_main_final = 7 if sanitation_all == "pit_no_slab"
replace sanitation_main_final = 8 if sanitation_all == "composting"
replace sanitation_main_final = 9 if sanitation_all == "bucket"
replace sanitation_main_final = 10 if sanitation_all == "hanging"
replace sanitation_main_final = 11 if sanitation_all == "other"
replace sanitation_main_final = 12 if sanitation_all == "bush"

gen sanitation_main_shared:sharedsanlist = .
forvalues i = 1/10 {
  replace sanitation_main_shared = shared_san_`i' if sanitation_main_final == `i'
}

gen improved_main_facility:improvedlist = 0 if sanitation_main_shared>1|(sanitation_main_final==3|sanitation_main_final==4|sanitation_main_final==7|sanitation_main_final==9|sanitation_main_final==10|sanitation_main_final==11|sanitation_main_final==12)
replace improved_main_facility = 1 if (sanitation_main_shared==1)&(sanitation_main_final==1|sanitation_main_final==2|sanitation_main_final==5|sanitation_main_final==6|sanitation_main_final==8)

** Main Bush
gen main_bush = 0 if sanitation_main_final < 12
replace main_bush = 1 if sanitation_main_final == 12

svyset EA [pweight=HHweight], strata(strata) singleunit(scaled)
egen num_EA = group(EA)

svy: proportion improved_drinking_water
mat water = r(table)
mat water = water[1..2,1]*100
gen improved_drinking_water_wt = improved_drinking_water*HHweight
xtset num_EA
xtreg improved_drinking_water_wt
mat water = water\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_drinking_water, deff
mat deff = e(Deff)
mat water = water\manual_deff\deff[1,1]

svy: proportion improved_main_facility
mat facility = r(table)
mat facility = facility[1..2,1]*100
gen improved_main_facility_wt = improved_main_facility*HHweight
xtset num_EA
xtreg improved_main_facility_wt
mat facility = facility\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_main_facility, deff
mat deff = e(Deff)
mat facility = facility\manual_deff\deff[1,1]

svy: proportion main_bush
mat bush = r(table)
mat bush = bush[1..2,2]*100
gen main_bush_wt = main_bush*HHweight
xtset num_EA
xtreg main_bush_wt
mat bush = bush\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab main_bush, deff
mat deff = e(Deff)
mat bush = bush\manual_deff\deff[1,1]

mat GhanaR2 = (_N\water\bush)'

keep EA HHweight strata improved_drinking_water improved_main_facility main_bush HHtag
save "`GhanaR2_minimal'", replace
 
** Ghana R1 + R2
use "`GhanaR1_minimal'", clear
append using "`GhanaR2_minimal'"

svyset EA [pweight=HHweight], strata(strata) singleunit(scaled)
svy: proportion improved_drinking_water
mat water = r(table)
mat water = water[1..2,1]*100
gen improved_drinking_water_wt = improved_drinking_water*HHweight
egen num_EA = group(EA)
xtset num_EA
xtreg improved_drinking_water_wt
mat water = water\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_drinking_water, deff
mat deff = e(Deff)
mat water = water\manual_deff\deff[1,1]

svy: proportion improved_main_facility
mat facility = r(table)
mat facility = facility[1..2,1]*100
gen improved_main_facility_wt = improved_main_facility*HHweight
xtset num_EA
xtreg improved_main_facility_wt
mat facility = facility\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_main_facility, deff
mat deff = e(Deff)
mat facility = facility\manual_deff\deff[1,1]

svy: proportion main_bush
mat bush = r(table)
mat bush = bush[1..2,2]*100
gen main_bush_wt = main_bush*HHweight
xtset num_EA
xtreg main_bush_wt
mat bush = bush\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab main_bush, deff
mat deff = e(Deff)
mat bush = bush\manual_deff\deff[1,1]


mat GhanaR12 = (_N\water\bush)'


** Ethiopia R1
use "Ethiopia\Data\ETR1_WealthWeightAll_5May2014.dta", clear
keep if R==1 & HHtag==1

** Drinking Water Sources
gen HQ20_final = HQ20
replace HQ20_final = HQ19 if !regexm(HQ19," ")
replace HQ20_final = substr(HQ19,1,1) if HQ20_final==""
gen HQ21_final = HQ21
replace HQ21_final = HQ19 if !regexm(HQ19," ")
replace HQ21_final = substr(HQ19,1,1) if HQ21_final==" "

local is_improved1 HQ20_final=="a"|HQ20_final=="b"|HQ20_final=="c"|HQ20_final=="d"|HQ20_final=="e"|HQ20_final=="g"|HQ20_final=="i"
local is_unimproved1 HQ20_final=="f"|HQ20_final=="h"|HQ20_final=="j"|HQ20_final=="k"|HQ20_final=="l"
local is_bottled_improved1 (HQ20_final=="m"|HQ20_final=="n")&(HQ21_final=="a"|HQ21_final=="b"|HQ21_final=="c"|HQ21_final=="d"|HQ21_final=="e"|HQ21_final=="g"|HQ21_final=="i")
local is_bottled_unimproved1 (HQ20_final=="m"|HQ20_final=="n")&(HQ21_final=="f"|HQ21_final=="h"|HQ21_final=="j"|HQ21_final=="k"|HQ21_final=="l")

label define improvedlist 0 "Unimproved" 1 "Improved"
gen improved_drinking_water:improvedlist = .
replace improved_drinking_water = 1 if `is_improved1'|`is_bottled_improved1'
replace improved_drinking_water = 0 if `is_unimproved1'|`is_bottled_unimproved1'


** Sanitation Facilities
gen HQ28_final = HQ28
replace HQ28_final = HQ27 if !regexm(HQ27," ")
replace HQ28_final = substr(HQ27,1,1) if HQ28_final==" "

gen sanitation_main_shared:sharedsan = .
forvalues i = 1/10 {
  replace sanitation_main_shared = sharedsan_`i' if HQ28_final == substr("`alphabet'",`i',1)
}

gen improved_main_facility:improvedlist = .
replace improved_main_facility = 1 if (sanitation_main_shared==1)|(HQ28_final=="a"|HQ28_final=="b"|HQ28_final=="e"|HQ28_final=="f"|HQ28_final=="h")
replace improved_main_facility = 0 if (sanitation_main_shared>1)|(HQ28_final=="c"|HQ28_final=="d"|HQ28_final=="g"|HQ28_final=="i"|HQ28_final=="j"|HQ28_final=="k"|HQ28_final=="l")

** Main Bush
gen main_bush = HQ28
replace main_bush = HQ27 if HQ28==""|HQ28==" "
forvalues i = 1/11 {
	replace main_bush = "0" if regexm(main_bush,substr("`alphabet'",`i',1))
}
replace main_bush = "1" if regexm(main_bush,substr("`alphabet'",12,1))
destring main_bush, replace
replace main_bush = . if main_bush < 0


svyset EA [pweight=HHweight], strata(strata) singleunit(scaled)
egen num_EA = group(EA)

svy: proportion improved_drinking_water
mat water = r(table)
mat water = water[1..2,1]*100
gen improved_drinking_water_wt = improved_drinking_water*HHweight
xtset num_EA
xtreg improved_drinking_water_wt
mat water = water\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_drinking_water, deff
mat deff = e(Deff)
mat water = water\manual_deff\deff[1,1]

svy: proportion improved_main_facility
mat facility = r(table)
mat facility = facility[1..2,1]*100
gen improved_main_facility_wt = improved_main_facility*HHweight
xtset num_EA
xtreg improved_main_facility_wt
mat facility = facility\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_main_facility, deff
mat deff = e(Deff)
mat facility = facility\manual_deff\deff[1,1]

svy: proportion main_bush
mat bush = r(table)
mat bush = bush[1..2,2]*100
gen main_bush_wt = main_bush*HHweight
xtset num_EA
xtreg main_bush_wt
mat bush = bush\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab main_bush, deff
mat deff = e(Deff)
mat bush = bush\manual_deff\deff[1,1]

mat EthiopiaR1 = (_N\water\bush)'
keep EA HHweight strata improved_drinking_water improved_main_facility main_bush HHtag
save "`EthiopiaR1_minimal'", replace

** Ethiopia R2
use "Ethiopia\Data\ETR2_WealthWeightCompleteHH_22Jan15.dta", clear
egen HHtag = tag(metainstanceID)
keep if HHQ_result==1 & HHtag==1

egen strata = concat(region ur), punct("_")
ren EA EAold
egen EA=concat(locality EAold), punct("_")

** Drinking Water Sources
gen water_main_drinking_final:watersourcelist = water_sources_main_drinking
replace water_main_drinking_final = 1 if water_sources_all == "piped_indoor"
replace water_main_drinking_final = 2 if water_sources_all == "piped_yard"
replace water_main_drinking_final = 3 if water_sources_all == "piped_public"
replace water_main_drinking_final = 4 if water_sources_all == "tubewell"
replace water_main_drinking_final = 5 if water_sources_all == "protected_dug_well"
replace water_main_drinking_final = 6 if water_sources_all == "unprotected_dug_well"
replace water_main_drinking_final = 7 if water_sources_all == "protected_spring"
replace water_main_drinking_final = 8 if water_sources_all == "unprotected_spring"
replace water_main_drinking_final = 9 if water_sources_all == "rainwater"
replace water_main_drinking_final = 10 if water_sources_all == "tanker"
replace water_main_drinking_final = 11 if water_sources_all == "cart"
replace water_main_drinking_final = 12 if water_sources_all == "surface_water"
replace water_main_drinking_final = 13 if water_sources_all == "bottled"
replace water_main_drinking_final = 14 if water_sources_all == "sachet"

gen water_main_other_final:watersourcelist = water_sources_main_other
replace water_main_other_final = 1 if water_sources_all == "piped_indoor"
replace water_main_other_final = 2 if water_sources_all == "piped_yard"
replace water_main_other_final = 3 if water_sources_all == "piped_public"
replace water_main_other_final = 4 if water_sources_all == "tubewell"
replace water_main_other_final = 5 if water_sources_all == "protected_dug_well"
replace water_main_other_final = 6 if water_sources_all == "unprotected_dug_well"
replace water_main_other_final = 7 if water_sources_all == "protected_spring"
replace water_main_other_final = 8 if water_sources_all == "unprotected_spring"
replace water_main_other_final = 9 if water_sources_all == "rainwater"
replace water_main_other_final = 10 if water_sources_all == "tanker"
replace water_main_other_final = 11 if water_sources_all == "cart"
replace water_main_other_final = 12 if water_sources_all == "surface_water"
replace water_main_other_final = 13 if water_sources_all == "bottled"
replace water_main_other_final = 14 if water_sources_all == "sachet"

label define improvedlist 0 "Unimproved" 1 "Improved"

gen improved_drinking_water:improvedlist = 1 if `is_improved2'|`is_bottled_improved2'
replace improved_drinking_water = 0 if `is_unimproved2'|`is_bottled_unimproved2'

** Sanitation Facilities
gen sanitation_main_final:sanitationlist = sanitation_main
replace sanitation_main_final = 1 if sanitation_all == "flush_sewer"
replace sanitation_main_final = 2 if sanitation_all == "flush_septic"
replace sanitation_main_final = 3 if sanitation_all == "flush_elsewhere"
replace sanitation_main_final = 4 if sanitation_all == "flush_unknown"
replace sanitation_main_final = 5 if sanitation_all == "vip"
replace sanitation_main_final = 6 if sanitation_all == "pit_with_slab"
replace sanitation_main_final = 7 if sanitation_all == "pit_no_slab"
replace sanitation_main_final = 8 if sanitation_all == "composting"
replace sanitation_main_final = 9 if sanitation_all == "bucket"
replace sanitation_main_final = 10 if sanitation_all == "hanging"
replace sanitation_main_final = 11 if sanitation_all == "other"
replace sanitation_main_final = 12 if sanitation_all == "bush"

gen sanitation_main_shared:sharedsanlist = .
forvalues i = 1/10 {
  replace sanitation_main_shared = shared_san_`i' if sanitation_main_final == `i'
}

gen improved_main_facility:improvedlist = 0 if sanitation_main_shared>1|(sanitation_main_final==3|sanitation_main_final==4|sanitation_main_final==7|sanitation_main_final==9|sanitation_main_final==10|sanitation_main_final==11|sanitation_main_final==12)
replace improved_main_facility = 1 if (sanitation_main_shared==1)&(sanitation_main_final==1|sanitation_main_final==2|sanitation_main_final==5|sanitation_main_final==6|sanitation_main_final==8)

** Main Bush
gen main_bush = 0 if sanitation_main_final < 12
replace main_bush = 1 if sanitation_main_final == 12


svyset EA [pweight=HHweight], strata(strata) singleunit(scaled)
egen num_EA = group(EA)

svy: proportion improved_drinking_water
mat water = r(table)
mat water = water[1..2,1]*100
gen improved_drinking_water_wt = improved_drinking_water*HHweight
xtset num_EA
xtreg improved_drinking_water_wt
mat water = water\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_drinking_water, deff
mat deff = e(Deff)
mat water = water\manual_deff\deff[1,1]

svy: proportion improved_main_facility
mat facility = r(table)
mat facility = facility[1..2,1]*100
gen improved_main_facility_wt = improved_main_facility*HHweight
xtset num_EA
xtreg improved_main_facility_wt
mat facility = facility\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_main_facility, deff
mat deff = e(Deff)
mat facility = facility\manual_deff\deff[1,1]

svy: proportion main_bush
mat bush = r(table)
mat bush = bush[1..2,2]*100
gen main_bush_wt = main_bush*HHweight
xtset num_EA
xtreg main_bush_wt
mat bush = bush\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab main_bush, deff
mat deff = e(Deff)
mat bush = bush\manual_deff\deff[1,1]

mat EthiopiaR2 = (_N\water\bush)'
keep EA HHweight strata improved_drinking_water improved_main_facility main_bush HHtag
save "`EthiopiaR2_minimal'", replace



** Ethiopia R1 + R2
use "`EthiopiaR1_minimal'", clear
append using "`EthiopiaR2_minimal'"



svyset EA [pweight=HHweight], strata(strata) singleunit(scaled)
egen num_EA = group(EA)

svy: proportion improved_drinking_water
mat water = r(table)
mat water = water[1..2,1]*100
gen improved_drinking_water_wt = improved_drinking_water*HHweight
xtset num_EA
xtreg improved_drinking_water_wt
mat water = water\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_drinking_water, deff
mat deff = e(Deff)
mat water = water\manual_deff\deff[1,1]

svy: proportion improved_main_facility
mat facility = r(table)
mat facility = facility[1..2,1]*100
gen improved_main_facility_wt = improved_main_facility*HHweight
xtset num_EA
xtreg improved_main_facility_wt
mat facility = facility\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_main_facility, deff
mat deff = e(Deff)
mat facility = facility\manual_deff\deff[1,1]

svy: proportion main_bush
mat bush = r(table)
mat bush = bush[1..2,2]*100
gen main_bush_wt = main_bush*HHweight
xtset num_EA
xtreg main_bush_wt
mat bush = bush\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab main_bush, deff
mat deff = e(Deff)
mat bush = bush\manual_deff\deff[1,1]

mat EthiopiaR12 = (_N\water\bush)'

** Kenya R1
use "Kenya\Data\KER1_WealthWeightCompleteHH_29Aug2014_ECRecode.dta", clear
keep if HHQ_result==1 & HHtag==1

gen water_main_drinking_final:watersourcelist = water_sources_main_drinking
replace water_main_drinking_final = 1 if water_sources_all == "piped_indoor"
replace water_main_drinking_final = 2 if water_sources_all == "piped_yard"
replace water_main_drinking_final = 3 if water_sources_all == "piped_public"
replace water_main_drinking_final = 4 if water_sources_all == "tubewell"
replace water_main_drinking_final = 5 if water_sources_all == "protected_dug_well"
replace water_main_drinking_final = 6 if water_sources_all == "unprotected_dug_well"
replace water_main_drinking_final = 7 if water_sources_all == "protected_spring"
replace water_main_drinking_final = 8 if water_sources_all == "unprotected_spring"
replace water_main_drinking_final = 9 if water_sources_all == "rainwater"
replace water_main_drinking_final = 10 if water_sources_all == "tanker"
replace water_main_drinking_final = 11 if water_sources_all == "cart"
replace water_main_drinking_final = 12 if water_sources_all == "surface_water"
replace water_main_drinking_final = 13 if water_sources_all == "bottled"
replace water_main_drinking_final = 14 if water_sources_all == "sachet"

gen water_main_other_final:watersourcelist = water_sources_main_other
replace water_main_other_final = 1 if water_sources_all == "piped_indoor"
replace water_main_other_final = 2 if water_sources_all == "piped_yard"
replace water_main_other_final = 3 if water_sources_all == "piped_public"
replace water_main_other_final = 4 if water_sources_all == "tubewell"
replace water_main_other_final = 5 if water_sources_all == "protected_dug_well"
replace water_main_other_final = 6 if water_sources_all == "unprotected_dug_well"
replace water_main_other_final = 7 if water_sources_all == "protected_spring"
replace water_main_other_final = 8 if water_sources_all == "unprotected_spring"
replace water_main_other_final = 9 if water_sources_all == "rainwater"
replace water_main_other_final = 10 if water_sources_all == "tanker"
replace water_main_other_final = 11 if water_sources_all == "cart"
replace water_main_other_final = 12 if water_sources_all == "surface_water"
replace water_main_other_final = 13 if water_sources_all == "bottled"
replace water_main_other_final = 14 if water_sources_all == "sachet"

label define improvedlist 0 "Unimproved" 1 "Improved"

gen improved_drinking_water:improvedlist = 1 if `is_improved2'|`is_bottled_improved2'
replace improved_drinking_water = 0 if `is_unimproved2'|`is_bottled_unimproved2'

gen sanitation_main_final:sanitationlist = sanitation_main
replace sanitation_main_final = 1 if sanitation_all == "flush_sewer"
replace sanitation_main_final = 2 if sanitation_all == "flush_septic"
replace sanitation_main_final = 3 if sanitation_all == "flush_elsewhere"
replace sanitation_main_final = 4 if sanitation_all == "flush_unknown"
replace sanitation_main_final = 5 if sanitation_all == "vip"
replace sanitation_main_final = 6 if sanitation_all == "pit_with_slab"
replace sanitation_main_final = 7 if sanitation_all == "pit_no_slab"
replace sanitation_main_final = 8 if sanitation_all == "composting"
replace sanitation_main_final = 9 if sanitation_all == "bucket"
replace sanitation_main_final = 10 if sanitation_all == "hanging"
replace sanitation_main_final = 11 if sanitation_all == "other"
replace sanitation_main_final = 12 if sanitation_all == "bush"

gen sanitation_main_shared:sharedsanlist = .
forvalues i = 1/10 {
  replace sanitation_main_shared = shared_san_`i' if sanitation_main_final == `i'
}

gen improved_main_facility:improvedlist = 0 if sanitation_main_shared>1|(sanitation_main_final==3|sanitation_main_final==4|sanitation_main_final==7|sanitation_main_final==9|sanitation_main_final==10|sanitation_main_final==11|sanitation_main_final==12)
replace improved_main_facility = 1 if (sanitation_main_shared==1)&(sanitation_main_final==1|sanitation_main_final==2|sanitation_main_final==5|sanitation_main_final==6|sanitation_main_final==8)

** Main Bush
gen main_bush = 0 if sanitation_main_final < 12
replace main_bush = 1 if sanitation_main_final == 12


svyset EA [pweight=HHweight], strata(strata) singleunit(scaled)
egen num_EA = group(EA)

svy: proportion improved_drinking_water
mat water = r(table)
mat water = water[1..2,1]*100
gen improved_drinking_water_wt = improved_drinking_water*HHweight
xtset num_EA
xtreg improved_drinking_water_wt
mat water = water\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_drinking_water, deff
mat deff = e(Deff)
mat water = water\manual_deff\deff[1,1]

svy: proportion improved_main_facility
mat facility = r(table)
mat facility = facility[1..2,1]*100
gen improved_main_facility_wt = improved_main_facility*HHweight
xtset num_EA
xtreg improved_main_facility_wt
mat facility = facility\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_main_facility, deff
mat deff = e(Deff)
mat facility = facility\manual_deff\deff[1,1]

svy: proportion main_bush
mat bush = r(table)
mat bush = bush[1..2,2]*100
gen main_bush_wt = main_bush*HHweight
xtset num_EA
xtreg main_bush_wt
mat bush = bush\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab main_bush, deff
mat deff = e(Deff)
mat bush = bush\manual_deff\deff[1,1]

mat KenyaR1 = (_N\water\bush)'
keep EA HHweight strata improved_drinking_water improved_main_facility main_bush HHtag
save "`KenyaR1_minimal'", replace
 
** Kenya R2
use13 C:\Users\Kyle\Dropbox\PMA2020_KENYA\Data\Round2\PreliminaryData\KER2_WealthWeightAll_22Jan2015.dta, clear
egen HHtag = tag(metainstanceID)

keep if HHQ_result==1 & HHtag==1

gen water_main_drinking_final:watersourcelist = water_sources_main_drinking
replace water_main_drinking_final = 1 if water_sources_all == "piped_indoor"
replace water_main_drinking_final = 2 if water_sources_all == "piped_yard"
replace water_main_drinking_final = 3 if water_sources_all == "piped_public"
replace water_main_drinking_final = 4 if water_sources_all == "tubewell"
replace water_main_drinking_final = 5 if water_sources_all == "protected_dug_well"
replace water_main_drinking_final = 6 if water_sources_all == "unprotected_dug_well"
replace water_main_drinking_final = 7 if water_sources_all == "protected_spring"
replace water_main_drinking_final = 8 if water_sources_all == "unprotected_spring"
replace water_main_drinking_final = 9 if water_sources_all == "rainwater"
replace water_main_drinking_final = 10 if water_sources_all == "tanker"
replace water_main_drinking_final = 11 if water_sources_all == "cart"
replace water_main_drinking_final = 12 if water_sources_all == "surface_water"
replace water_main_drinking_final = 13 if water_sources_all == "bottled"
replace water_main_drinking_final = 14 if water_sources_all == "sachet"

gen water_main_other_final:watersourcelist = water_sources_main_other
replace water_main_other_final = 1 if water_sources_all == "piped_indoor"
replace water_main_other_final = 2 if water_sources_all == "piped_yard"
replace water_main_other_final = 3 if water_sources_all == "piped_public"
replace water_main_other_final = 4 if water_sources_all == "tubewell"
replace water_main_other_final = 5 if water_sources_all == "protected_dug_well"
replace water_main_other_final = 6 if water_sources_all == "unprotected_dug_well"
replace water_main_other_final = 7 if water_sources_all == "protected_spring"
replace water_main_other_final = 8 if water_sources_all == "unprotected_spring"
replace water_main_other_final = 9 if water_sources_all == "rainwater"
replace water_main_other_final = 10 if water_sources_all == "tanker"
replace water_main_other_final = 11 if water_sources_all == "cart"
replace water_main_other_final = 12 if water_sources_all == "surface_water"
replace water_main_other_final = 13 if water_sources_all == "bottled"
replace water_main_other_final = 14 if water_sources_all == "sachet"

label define improvedlist 0 "Unimproved" 1 "Improved"

gen improved_drinking_water:improvedlist = 1 if `is_improved2'|`is_bottled_improved2'
replace improved_drinking_water = 0 if `is_unimproved2'|`is_bottled_unimproved2'

gen sanitation_main_final:sanitationlist = sanitation_main
replace sanitation_main_final = 1 if sanitation_all == "flush_sewer"
replace sanitation_main_final = 2 if sanitation_all == "flush_septic"
replace sanitation_main_final = 3 if sanitation_all == "flush_elsewhere"
replace sanitation_main_final = 4 if sanitation_all == "flush_unknown"
replace sanitation_main_final = 5 if sanitation_all == "vip"
replace sanitation_main_final = 6 if sanitation_all == "pit_with_slab"
replace sanitation_main_final = 7 if sanitation_all == "pit_no_slab"
replace sanitation_main_final = 8 if sanitation_all == "composting"
replace sanitation_main_final = 9 if sanitation_all == "bucket"
replace sanitation_main_final = 10 if sanitation_all == "hanging"
replace sanitation_main_final = 11 if sanitation_all == "other"
replace sanitation_main_final = 12 if sanitation_all == "bush"

gen sanitation_main_shared:sharedsanlist = .
forvalues i = 1/10 {
  replace sanitation_main_shared = shared_san_`i' if sanitation_main_final == `i'
}

gen improved_main_facility:improvedlist = 0 if sanitation_main_shared>1|(sanitation_main_final==3|sanitation_main_final==4|sanitation_main_final==7|sanitation_main_final==9|sanitation_main_final==10|sanitation_main_final==11|sanitation_main_final==12)
replace improved_main_facility = 1 if (sanitation_main_shared==1)&(sanitation_main_final==1|sanitation_main_final==2|sanitation_main_final==5|sanitation_main_final==6|sanitation_main_final==8)

** Main Bush
gen main_bush = 0 if sanitation_main_final < 12
replace main_bush = 1 if sanitation_main_final == 12


svyset EA [pweight=HHweight], strata(strata) singleunit(scaled)
egen num_EA = group(EA)

svy: proportion improved_drinking_water
mat water = r(table)
mat water = water[1..2,1]*100
gen improved_drinking_water_wt = improved_drinking_water*HHweight
xtset num_EA
xtreg improved_drinking_water_wt
mat water = water\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_drinking_water, deff
mat deff = e(Deff)
mat water = water\manual_deff\deff[1,1]

svy: proportion improved_main_facility
mat facility = r(table)
mat facility = facility[1..2,1]*100
gen improved_main_facility_wt = improved_main_facility*HHweight
xtset num_EA
xtreg improved_main_facility_wt
mat facility = facility\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_main_facility, deff
mat deff = e(Deff)
mat facility = facility\manual_deff\deff[1,1]

svy: proportion main_bush
mat bush = r(table)
mat bush = bush[1..2,2]*100
gen main_bush_wt = main_bush*HHweight
xtset num_EA
xtreg main_bush_wt
mat bush = bush\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab main_bush, deff
mat deff = e(Deff)
mat bush = bush\manual_deff\deff[1,1]

mat KenyaR2 = (_N\water\bush)'
keep EA HHweight strata improved_drinking_water improved_main_facility main_bush HHtag
save "`KenyaR2_minimal'", replace

** Kenya R1 + R2
use "`KenyaR1_minimal'", clear
append using "`KenyaR2_minimal'"



svyset EA [pweight=HHweight], strata(strata) singleunit(scaled)
egen num_EA = group(EA)

svy: proportion improved_drinking_water
mat water = r(table)
mat water = water[1..2,1]*100
gen improved_drinking_water_wt = improved_drinking_water*HHweight
xtset num_EA
xtreg improved_drinking_water_wt
mat water = water\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_drinking_water, deff
mat deff = e(Deff)
mat water = water\manual_deff\deff[1,1]

svy: proportion improved_main_facility
mat facility = r(table)
mat facility = facility[1..2,1]*100
gen improved_main_facility_wt = improved_main_facility*HHweight
xtset num_EA
xtreg improved_main_facility_wt
mat facility = facility\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_main_facility, deff
mat deff = e(Deff)
mat facility = facility\manual_deff\deff[1,1]

mat KenyaR12 = (_N\water\bush)'


** Uganda R1
use "Uganda\Data\UGR1_WealthWeightAll_18Jul2014.dta", clear
keep if HHQ_result==1 & HHtag==1
egen strata = concat(DHSregion ur), punct("-")

gen water_main_drinking_final:watersourcelist = water_sources_main_drinking
replace water_main_drinking_final = 1 if water_sources_all == "piped_indoor"
replace water_main_drinking_final = 2 if water_sources_all == "piped_yard"
replace water_main_drinking_final = 3 if water_sources_all == "piped_public"
replace water_main_drinking_final = 4 if water_sources_all == "tubewell"
replace water_main_drinking_final = 5 if water_sources_all == "protected_dug_well"
replace water_main_drinking_final = 6 if water_sources_all == "unprotected_dug_well"
replace water_main_drinking_final = 7 if water_sources_all == "protected_spring"
replace water_main_drinking_final = 8 if water_sources_all == "unprotected_spring"
replace water_main_drinking_final = 9 if water_sources_all == "rainwater"
replace water_main_drinking_final = 10 if water_sources_all == "tanker"
replace water_main_drinking_final = 11 if water_sources_all == "cart"
replace water_main_drinking_final = 12 if water_sources_all == "surface_water"
replace water_main_drinking_final = 13 if water_sources_all == "bottled"
replace water_main_drinking_final = 14 if water_sources_all == "sachet"

gen water_main_other_final:watersourcelist = water_sources_main_other
replace water_main_other_final = 1 if water_sources_all == "piped_indoor"
replace water_main_other_final = 2 if water_sources_all == "piped_yard"
replace water_main_other_final = 3 if water_sources_all == "piped_public"
replace water_main_other_final = 4 if water_sources_all == "tubewell"
replace water_main_other_final = 5 if water_sources_all == "protected_dug_well"
replace water_main_other_final = 6 if water_sources_all == "unprotected_dug_well"
replace water_main_other_final = 7 if water_sources_all == "protected_spring"
replace water_main_other_final = 8 if water_sources_all == "unprotected_spring"
replace water_main_other_final = 9 if water_sources_all == "rainwater"
replace water_main_other_final = 10 if water_sources_all == "tanker"
replace water_main_other_final = 11 if water_sources_all == "cart"
replace water_main_other_final = 12 if water_sources_all == "surface_water"
replace water_main_other_final = 13 if water_sources_all == "bottled"
replace water_main_other_final = 14 if water_sources_all == "sachet"

label define improvedlist 0 "Unimproved" 1 "Improved"

gen improved_drinking_water:improvedlist = 1 if `is_improved2'|`is_bottled_improved2'
replace improved_drinking_water = 0 if `is_unimproved2'|`is_bottled_unimproved2'

gen sanitation_main_final:sanitationlist = sanitation_main
replace sanitation_main_final = 1 if sanitation_all == "flush_sewer"
replace sanitation_main_final = 2 if sanitation_all == "flush_septic"
replace sanitation_main_final = 3 if sanitation_all == "flush_elsewhere"
replace sanitation_main_final = 4 if sanitation_all == "flush_unknown"
replace sanitation_main_final = 5 if sanitation_all == "vip"
replace sanitation_main_final = 6 if sanitation_all == "pit_with_slab"
replace sanitation_main_final = 7 if sanitation_all == "pit_no_slab"
replace sanitation_main_final = 8 if sanitation_all == "composting"
replace sanitation_main_final = 9 if sanitation_all == "bucket"
replace sanitation_main_final = 10 if sanitation_all == "hanging"
replace sanitation_main_final = 11 if sanitation_all == "other"
replace sanitation_main_final = 12 if sanitation_all == "bush"

gen sanitation_main_shared:sharedsanlist = .
forvalues i = 1/10 {
  replace sanitation_main_shared = shared_san_`i' if sanitation_main_final == `i'
}

gen improved_main_facility:improvedlist = 0 if sanitation_main_shared>1|(sanitation_main_final==3|sanitation_main_final==4|sanitation_main_final==7|sanitation_main_final==9|sanitation_main_final==10|sanitation_main_final==11|sanitation_main_final==12)
replace improved_main_facility = 1 if (sanitation_main_shared==1)&(sanitation_main_final==1|sanitation_main_final==2|sanitation_main_final==5|sanitation_main_final==6|sanitation_main_final==8)

** Main Bush
gen main_bush = 0 if sanitation_main_final < 12
replace main_bush = 1 if sanitation_main_final == 12


svyset EA [pweight=HHweight], strata(strata) singleunit(scaled)
egen num_EA = group(EA)

svy: proportion improved_drinking_water
mat water = r(table)
mat water = water[1..2,1]*100
gen improved_drinking_water_wt = improved_drinking_water*HHweight
xtset num_EA
xtreg improved_drinking_water_wt
mat water = water\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_drinking_water, deff
mat deff = e(Deff)
mat water = water\manual_deff\deff[1,1]

svy: proportion improved_main_facility
mat facility = r(table)
mat facility = facility[1..2,1]*100
gen improved_main_facility_wt = improved_main_facility*HHweight
xtset num_EA
xtreg improved_main_facility_wt
mat facility = facility\e(g_avg)\e(rho)
mat manual_deff = 1+(e(g_avg)-1)*e(rho)
svy: tab improved_main_facility, deff
mat deff = e(Deff)
mat facility = facility\manual_deff\deff[1,1]

mat UgandaR1 = (_N\water\bush)'

mat Final_Table = GhanaR1\GhanaR2\GhanaR12\EthiopiaR1\EthiopiaR2\EthiopiaR12\KenyaR1\KenyaR2\KenyaR12\UgandaR1
mat rownames Final_Table = "Ghana R1" "Ghana R2" "Ghana R1+R2" "Ethiopia R1" "Ethiopia R2" "Ethiopia R1+R2" "Kenya R1" "Kenya R2" "Kenya R1+R2" "Uganda R1"
mat colnames Final_Table = "Sample Size(Households)" "Point estimate" "Standard Error" "Average EA size" "ICC" "Deff(manual)" "Deff(Stata)" "Point estimate" "Standard Error" "Average EA size" "ICC" "Deff(manual)" "Deff(Stata)"

mat2txt2 Final_Table using SE_table_extended.csv, replace comma format(%12.2f)
