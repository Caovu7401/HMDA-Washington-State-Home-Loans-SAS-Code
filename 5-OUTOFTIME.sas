/*Phần dữ liệu Out of time năm 2017 đã được tiền xử lý các giá trị nhiễu hoặc không khớp 
với định dạng cũ, phần dưới đây gồm code thao tác với dữ liệu đã được xử lý gọn*/
/*---------------------------------------------------------------------------*/
LIBNAME DATA "/home/u64047063/7.BIG PROJECT (FIX)";
OPTIONS MSTORED SASMSTORE=DATA;
DATA DATA.OOT;
    SET DATA.OOT;
RUN;
/*---------------------------------------------------------------------------*/



/*1.Phân chia điểm dữ liệu Good-Bad*/
DATA DATA.OOT;
	SET DATA.OOT;

	IF DENIED=0 THEN
		DO;
			GOOD=1;
			BAD=0;
		END;
	ELSE IF DENIED=1 THEN
		DO;
			GOOD=0;
			BAD=1;
		END;
RUN;
/*---------------------------------------------------------------------------*/



/*2.Tạo thêm biến mới Have_co_applicant*/
DATA DATA.OOT; 
    set DATA.OOT; 
    length have_co_applicant $ 5;
    if co_applicant_race_name_1 = "No co-applicant" then 
        have_co_applicant = "no"; 
    else 
        have_co_applicant = "yes";
RUN;
/*---------------------------------------------------------------------------*/



/*3.Lấy các GRP biến liên tục có từ tập train qua*/
DATA DATA.OOT;
	SET DATA.OOT;
	GRP_tract_to_msamd_income=PUT(tract_to_msamd_income, tract_to_msamd_incomeF.);
	GRP_applicant_income=PUT(applicant_income, applicant_incomeF.);
	GRP_ratio_num_owner_family=PUT(ratio_num_owner_family, ratio_num_owner_familyF.);
RUN;
/*----------------------------------------------------------------------------------*/




/*4.hud_median_income và county_name*/
/*Bê y nguyên từ tập TRAIN qua*/ 
DATA DATA.OOT;
    set DATA.OOT;
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



/*5.PROC FORMAT cho loan_type_property */ 
PROC FORMAT; /* loan_type_property */ 
	VALUE $loan_type_propertyW 'Conventional-1_4_family and Multifamily '= -0.024 
	'Conventional-Manufactured '= -0.828 'FHA-All types of house '= -0.052 
	'FSA-All types of house '= 0.56 'VA-All types of house '= 0.305; RUN;
/*----------------------------------------------------------------------------------*/ 




/*----------------------------------------------------------------------------------*/
/*6.Thêm các giá trị WOE vào dữ liệu*/
DATA DATA.OOT;
	SET DATA.OOT;
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



/*7.Tách ra dữ liệu Valid mới*/
DATA NEW_OOT;
	SET DATA.OOT (KEEP=WOE_tract_to_msamd_income 
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



/*8.GÁN ĐIỂM THEO CÁC HỆ SỐ ĐÃ ĐƯỢC ƯỚC LƯỢNG*/
PROC SCORE DATA=NEW_OOT TYPE=PARMS SCORE=NEW_TRAIN_PARAM OUT=NEW_OOT_OUTPUT;
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



DATA NEW_OOT_OUTPUT;
	SET NEW_OOT_OUTPUT;
	SCORE=ROUND(EXP(GOOD2)/(1+EXP((GOOD2)))*1000);
RUN;



/*CHẠY MACRO TÍNH TOÁN GINI*/
%NRUNBOOKP(NEW_OOT_OUTPUT, SCORE, GOOD, SCOREF.);







