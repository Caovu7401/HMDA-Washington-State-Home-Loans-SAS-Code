/*---------------------------------------------------------------------------*/
LIBNAME DATA "/home/u64047063/7.BIG PROJECT (FIX)";
OPTIONS MSTORED SASMSTORE=DATA;
DATA DATA.VALID;
    SET DATA.VALID;
RUN;
/*---------------------------------------------------------------------------*/



/*1.Tạo biến mới Have_co_applican*/
DATA DATA.VALID; 
    set DATA.VALID; 
    length have_co_applicant $ 5;
    if co_applicant_race_name_1 = "No co-applicant" then 
        have_co_applicant = "no"; 
    else 
        have_co_applicant = "yes";
RUN;
/*----------------------------------------------------------------------------------*/



/*2.Tạo biến mới ratio_num_owner_family*/
DATA DATA.VALID;
    set DATA.VALID;
    if num_family_dwelling ne 0 
    then ratio_num_owner_family = num_owner_occupied / num_family_dwelling;
    else ratio_num_owner_family = 0; 
    
    /*Một số ít giá trị ratio có thể >1 do sai lệch thông tin thống kê, ta sẽ đổi lại*/
    if ratio_num_owner_family > 1 then ratio_num_owner_family = 1; 
RUN;
/*----------------------------------------------------------------------------------*/



/*3.Bỏ đi một số biến không còn sử dụng nữa*/
DATA DATA.VALID;
    set DATA.VALID;
    drop co_applicant_race_name_1 co_applicant_ethnicity_name msamd_name 
    co_applicant_sex_name applicant_race_name_1 applicant_ethnicity_name 
    applicant_sex_name num_family_dwelling num_owner_occupied population 
    owner_occupancy_name hoepa_status_name edit_status_name minority_population;
RUN;
/*----------------------------------------------------------------------------------*/



/*4.Lấy các GRP biến liên tục có từ tập train qua*/
DATA DATA.VALID;
	SET DATA.VALID;
	GRP_tract_to_msamd_income=PUT(tract_to_msamd_income, tract_to_msamd_incomeF.);
	GRP_applicant_income=PUT(applicant_income, applicant_incomeF.);
	GRP_ratio_num_owner_family=PUT(ratio_num_owner_family, ratio_num_owner_familyF.);
RUN;
/*----------------------------------------------------------------------------------*/



/*5.Cross 2 biến loan_type và loan_property*/ 
DATA DATA.VALID; 
    SET DATA.VALID; 
    LENGTH loan_type_property $50.; 
    FORMAT loan_type_property $50.;
    INFORMAT loan_type_property $50.;
    
    IF loan_type_name = 'Conventional' AND property_type_name = 'Manufactured housing' THEN 
        loan_type_property = 'Conventional-Manufactured';        
    ELSE IF loan_type_name = 'Conventional' AND property_type_name = 'Multifamily dwelling' THEN 
        loan_type_property = 'Conventional-1_4_family and Multifamily';      
    ELSE IF loan_type_name = 'Conventional' AND property_type_name = 'One-to-four family dwelling' THEN 
        loan_type_property = 'Conventional-1_4_family and Multifamily';
    ELSE IF loan_type_name = 'FHA-insured' THEN loan_type_property = 'FHA-All types of house';
    ELSE IF loan_type_name = 'FSA/RHS-guaranteed' THEN loan_type_property = 'FSA-All types of house';
    ELSE IF loan_type_name = 'VA-guaranteed' THEN loan_type_property = 'VA-All types of house';
RUN;

PROC FORMAT; /* loan_type_property */ 
	VALUE $loan_type_propertyW 'Conventional-1_4_family and Multifamily '= -0.024 
	'Conventional-Manufactured '= -0.828 'FHA-All types of house '= -0.052 
	'FSA-All types of house '= 0.56 'VA-All types of house '= 0.305; RUN;
/*----------------------------------------------------------------------------------*/ 	



/*6.hud_median_income và county_name*/
/*Bê y nguyên từ tập TRAIN qua*/ 
DATA DATA.VALID;
    set DATA.VALID;
    if county_name = 'Yakima County' then WOE_county_name = -0.642;
    else if county_name in ('Island County', 'Grays Harbor County', 'Clallam County', 
    'Lewis County', 'Kittitas County', 'Lincoln County', 'Ferry County', 'San Juan County', 
    'Mason County', 'Klickitat County', 'Jefferson County', 'Grant County', 'Okanogan County', 
    'Pacific County', 'Whitman County', 'Garfield County', 'Adams County', 'Wahkiakum County') 
    then WOE_county_name = -0.261;
    else if county_name in ('Walla Walla County', 'Columbia County', 'Asotin County', 
    'Cowlitz County', 'Skagit County', 'Spokane County', 'Stevens County', 
    'Pend Oreille County', 'Chelan County', 'Douglas County', 'Franklin County', 'Benton County') 
    then WOE_county_name = -0.089;  
    else if county_name in ('Whatcom County', 'Pierce County', 'Clark County', 'Skamania County', 
    'Thurston County', 'Kitsap County') then WOE_county_name = 0; 
    else if county_name in ('Snohomish County', 'King County') then WOE_county_name = 0.133; 
RUN; 
/*----------------------------------------------------------------------------------*/ 




/*----------------------------------------------------------------------------------*/
/*7.Thêm các giá trị WOE vào dữ liệu*/
DATA DATA.VALID;
	SET DATA.VALID;
	WOE_tract_to_msamd_income=INPUT(PUT(GRP_tract_to_msamd_income, 
		$GRP_tract_to_msamd_incomeW.), COMMA30.);
	WOE_applicant_income=INPUT(PUT(GRP_applicant_income, $GRP_applicant_incomeW.), 
		COMMA30.); 
	WOE_have_co_applicant=INPUT(PUT(have_co_applicant, 
		$have_co_applicantW.), COMMA30.);	
	WOE_loan_purpose_name=INPUT(PUT(loan_purpose_name, $loan_purpose_nameW.), 
		COMMA30.);
	WOE_lien_status_name=INPUT(PUT(lien_status_name, $lien_status_nameW.), 
		COMMA30.);
	WOE_agency_abbr=INPUT(PUT(agency_abbr, $agency_abbrW.), COMMA30.);
	WOE_loan_type_property=INPUT(PUT(loan_type_property, 
		$loan_type_propertyW.), COMMA30.);
	WOE_ratio_num_owner_family=INPUT(PUT(GRP_ratio_num_owner_family, 
		$GRP_ratio_num_owner_familyW.), COMMA30.);
RUN;
/*----------------------------------------------------------------------------------*/



/*8.Tách ra dữ liệu Valid mới*/
DATA NEW_VALID;
	SET DATA.VALID (KEEP=WOE_tract_to_msamd_income 
		WOE_tract_to_msamd_income 
		WOE_applicant_income 
		WOE_ratio_num_owner_family
		WOE_have_co_applicant 
		WOE_county_name
		WOE_loan_purpose_name 
		WOE_lien_status_name 
		WOE_agency_abbr 
		WOE_loan_type_property
		GOOD);
RUN;
/*----------------------------------------------------------------------------------*/



/*9.GÁN ĐIỂM THEO CÁC HỆ SỐ ĐÃ ĐƯỢC ƯỚC LƯỢNG*/
PROC SCORE DATA=NEW_VALID TYPE=PARMS SCORE=NEW_TRAIN_PARAM OUT=NEW_VALID_OUTPUT;
	VAR WOE_tract_to_msamd_income 
		WOE_applicant_income 
		WOE_ratio_num_owner_family 
		WOE_have_co_applicant 
		WOE_loan_purpose_name 
		WOE_lien_status_name 
		WOE_county_name
		WOE_agency_abbr
		WOE_loan_type_property;
RUN;


DATA NEW_VALID_OUTPUT;
	SET NEW_VALID_OUTPUT;
	SCORE=ROUND(EXP(GOOD2)/(1+EXP((GOOD2)))*1000);
RUN;


/*CHẠY MACRO TÍNH TOÁN GINI*/
%NRUNBOOKP(NEW_VALID_OUTPUT, SCORE, GOOD, SCOREF.);











