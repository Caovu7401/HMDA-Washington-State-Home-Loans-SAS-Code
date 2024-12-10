/*PHẦN CODE NÀY PHÂN TÍCH VÀ XÂY MÔ HÌNH CHO TẬP TRAIN*/
/*---------------------------------------------------------------------------*/
LIBNAME DATA "/home/u64047063/7.BIG PROJECT (FIX)";
OPTIONS MSTORED SASMSTORE=DATA;
DATA DATA.TRAIN;
    SET DATA.TRAIN;
RUN;
/*---------------------------------------------------------------------------*/



/*1.Tạo biến mới Have_co_applican*/
DATA DATA.TRAIN; 
    set DATA.TRAIN; 
    length have_co_applicant $ 5;
    if co_applicant_race_name_1 = "No co-applicant" then 
        have_co_applicant = "no"; 
    else 
        have_co_applicant = "yes";
RUN;

/*%CHARACT(DATA.TRAIN, have_co_applicant, BEST32.);*/
/*----------------------------------------------------------------------------------*/



/*2.Tạo biến mới ratio_num_owner_family*/
DATA DATA.TRAIN;
    set DATA.TRAIN;
    if num_family_dwelling ne 0 
    then ratio_num_owner_family = num_owner_occupied / num_family_dwelling;
    else ratio_num_owner_family = 0; 
    
    /*Một số ít giá trị ratio có thể >1 do sai lệch thông tin thống kê, ta sẽ đổi lại*/
    if ratio_num_owner_family > 1 then ratio_num_owner_family = 1; 
RUN;
/*----------------------------------------------------------------------------------*/



/*3.Bỏ đi một số biến không còn sử dụng nữa*/
DATA DATA.TRAIN;
    set DATA.TRAIN;
    drop co_applicant_race_name_1 co_applicant_ethnicity_name msamd_name 
    co_applicant_sex_name applicant_race_name_1 applicant_ethnicity_name 
    applicant_sex_name num_family_dwelling num_owner_occupied population 
    owner_occupancy_name hoepa_status_name edit_status_name minority_population;
run;
/*----------------------------------------------------------------------------------*/ 



/*5.Phân chia biến liên tục thành 20 bins*/
/*
%CONT2(DATA.TRAIN, tract_to_msamd_income, 20);
%CONT2(DATA.TRAIN, population, 20); (loại biến này, không đủ IV)     
%CONT2(DATA.TRAIN, minority_population, 20); (loại biến này, không đủ IV)
%CONT2(DATA.TRAIN, applicant_income, 20);
%CONT2(DATA.TRAIN, ratio_num_owner_family, 20); */
/*----------------------------------------------------------------------------------*/



/*----------------------------------------------------------------------------------*/
/*PROC FORMAT*/
PROC FORMAT;
	/* tract_to_msamd_income */
	VALUE tract_to_msamd_incomeF LOW-61.98='[01] LOW-61.98' 
		61.98<-78.68='[02] 61.98<-78.68' 78.68<-112.41='[03] 78.68<-112.41' 
		112.41<-129.25='[04] 112.41<-129.25' 129.25<-145.38='[05] 129.25<-145.38' 
		145.38<-HIGH='[06] 145.38<-HIGH';
RUN;

PROC FORMAT;
	/* applicant_income */
	VALUE applicant_incomeF LOW-35000='[01] LOW-35000'
		35000<-51000='[02] 35000<-51000' 51000<-63000='[03] 51000<-63000' 
		63000<-80000='[04] 63000<-80000' 80000<-HIGH='[05] 80000<-HIGH';
RUN;

PROC FORMAT;
	/* ratio_num_owner_family */
	VALUE ratio_num_owner_familyF 
	LOW-0.663='[01] LOW-0.663' 0.663<-0.714='[02] 0.663<-0.714' 
	0.714<-0.786='[03] 0.714<-0.786' 0.786<-0.838='[04] 0.786<-0.838' 
	0.838<-0.915='[05] 0.838<-0.915' 0.915<-0.958='[06] 0.915<-0.958' 
	0.958<-HIGH='[07] 0.958<-HIGH';
RUN;


/*Thêm các cột đã chia bins vào dữ liệu*/
DATA DATA.TRAIN;
	SET DATA.TRAIN;
	GRP_tract_to_msamd_income = PUT(tract_to_msamd_income, tract_to_msamd_incomeF.);
	GRP_applicant_income = PUT(applicant_income, applicant_incomeF.);
	GRP_ratio_num_owner_family = PUT(ratio_num_owner_family, ratio_num_owner_familyF.);
RUN;
/*----------------------------------------------------------------------------------*/




/*6.Phân tích WOE cho các biến cả liên tục lẫn phân loại*/ 
%CHARACT(DATA.TRAIN, GRP_tract_to_msamd_income, BEST32.);
%CHARACT(DATA.TRAIN, GRP_applicant_income, BEST32.); 
%CHARACT(DATA.TRAIN, GRP_ratio_num_owner_family, BEST32.); 

%CHARACT(DATA.TRAIN, have_co_applicant, $30.);
%CHARACT(DATA.TRAIN, hud_median_family_income, $w.);
%CHARACT(DATA.TRAIN, property_type_name, $30.);  /*(Dùng để Cross)*/
/*%CHARACT(DATA.TRAIN, owner_occupancy_name, $50.);*/  /*(loại biến này, không đủ IV)*/
%CHARACT(DATA.TRAIN, loan_type_name, $30.);  /*(Dùng để Cross)*/
%CHARACT(DATA.TRAIN, loan_purpose_name, $30.);
%CHARACT(DATA.TRAIN, lien_status_name, $30.);
/*%CHARACT(DATA.TRAIN, hoepa_status_name, $30.);*/  /*(loại biến này, không đủ IV)*/
/*%CHARACT(DATA.TRAIN, edit_status_name, $30.);*/  /*(loại biến này, không đủ IV)*/
%CHARACT(DATA.TRAIN, agency_abbr, $30.);



%WOECHARACT1(DATA.TRAIN, GRP_tract_to_msamd_income);
%WOECHARACT1(DATA.TRAIN, GRP_applicant_income); 
%WOECHARACT1(DATA.TRAIN, GRP_ratio_num_owner_family); 

%WOECHARACT1(DATA.TRAIN, have_co_applicant);
%WOECHARACT1(DATA.TRAIN, loan_purpose_name);
%WOECHARACT1(DATA.TRAIN, lien_status_name);
%WOECHARACT1(DATA.TRAIN, agency_abbr);
%WOECHARACT1(DATA.TRAIN, hud_median_family_income);
/*----------------------------------------------------------------------------------*/ 



/*8.PROC FORMAT cho toàn bộ các biến*/
/*PROC FORMAT cho các biến đủ tiêu chuẩn*/
PROC FORMAT;
	/* GRP_tract_to_msamd_income */
	VALUE $GRP_tract_to_msamd_incomeW '[01] LOW-61.98 '=-0.326 
		'[02] 61.98<-78.68 '=-0.206 '[03] 78.68<-112.41 '=-0.04 
		'[04] 112.41<-129.25'=0.106 '[05] 129.25<-145.38'=0.164 
		'[06] 145.38<-HIGH '=0.24;
RUN;

PROC FORMAT;
	/* GRP_applicant_income */
	VALUE $GRP_applicant_incomeW '[01] LOW-35000 '=-1.344 
		'[02] 35000<-51000 '=-0.521 '[03] 51000<-63000 '=-0.192 
		'[04] 63000<-80000 '=0.057 '[05] 80000<-HIGH '=0.325;
RUN;

PROC FORMAT; /* GRP_ratio_num_owner_family */ 
	VALUE $GRP_ratio_num_owner_familyW '[01] LOW-0.663 '= -0.221 
	'[02] 0.663<-0.714'= -0.102 '[03] 0.714<-0.786'= -0.04 
	'[04] 0.786<-0.838'= 0.084 '[05] 0.838<-0.915'= 0.156 
	'[06] 0.915<-0.958'= 0.201 '[07] 0.958<-HIGH '= 0.229; 
RUN;

PROC FORMAT; /* have_co_applicant */ 
	VALUE $have_co_applicantW 'no '= -0.127 'yes '= 0.183; RUN;
	
PROC FORMAT; /* loan_purpose_name */ 
	VALUE $loan_purpose_nameW 'Home improvement '= -0.53 'Home purchase '= 0.787 
	'Refinancing '= -0.389; RUN;
	
PROC FORMAT; /* lien_status_name */ 
	VALUE $lien_status_nameW 'Not secured by a lien '= -1.267 
	'Secured by a first lien '= 0.031 'Secured by a subordinate '= -0.274; RUN;
	
PROC FORMAT; /* agency_abbr */ 
	VALUE $agency_abbrW 'CFPB '= 0.079 'FDIC '= 0.634 'FRS '= 0.619 
	'HUD '= -0.163 'NCUA '= 0.059 'OCC '= 0.348; RUN;
/*----------------------------------------------------------------------------------*/



/*10.Cross 2 biến loan_type và loan_property*/ 
/*%CROSS(DATA.TRAIN, loan_type_name, property_type_name);*/
DATA DATA.TRAIN; 
    SET DATA.TRAIN; 
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

%WOECHARACT1(DATA.TRAIN, loan_type_property);

PROC FORMAT; /* loan_type_property */ 
	VALUE $loan_type_propertyW 'Conventional-1_4_family and Multifamily '= -0.024 
	'Conventional-Manufactured '= -0.828 'FHA-All types of house '= -0.052 
	'FSA-All types of house '= 0.56 'VA-All types of house '= 0.305; RUN;
/*----------------------------------------------------------------------------------*/ 	



/*11.hud_median_income và county_name*/
/*Nhận xét: Vì median_income đại diện cho mức thu nhập từng county, tuy nhiên giá trị 
này sẽ thay đổi theo từng năm. Do đó, ta sẽ "ánh xạ" WOE của median_income sang cho 
county, vì tương quan 2 biến này ~1*/ 
DATA DATA.TRAIN;
    set DATA.TRAIN;
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



/*12.Thêm các giá trị WOE vào dữ liệu*/
DATA DATA.TRAIN;
	SET DATA.TRAIN;
	WOE_tract_to_msamd_income=INPUT(PUT(GRP_tract_to_msamd_income, 
		$GRP_tract_to_msamd_incomeW.), COMMA30.);
	WOE_applicant_income=INPUT(PUT(GRP_applicant_income, $GRP_applicant_incomeW.), 
		COMMA30.);
	WOE_ratio_num_owner_family=INPUT(PUT(GRP_ratio_num_owner_family, $GRP_ratio_num_owner_familyW.), 
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
RUN;
/*----------------------------------------------------------------------------------*/



/*Tách ra dữ liệu mới*/
DATA NEW_TRAIN;
	SET DATA.TRAIN (KEEP = WOE_tract_to_msamd_income WOE_applicant_income 
	WOE_ratio_num_owner_family WOE_have_co_applicant 
	WOE_county_name WOE_loan_purpose_name 
	WOE_lien_status_name WOE_agency_abbr 
	WOE_loan_type_property GOOD); 
RUN;
/*----------------------------------------------------------------------------------*/



/*KIỂM TRA TƯƠNG QUAN (PEARSON) GIỮA CÁC BIẾN WOE*/
PROC CORR DATA=NEW_TRAIN NOPROB NOSIMPLE;
	VAR 
	WOE_tract_to_msamd_income 
	WOE_applicant_income 
	WOE_ratio_num_owner_family
	WOE_have_co_applicant 
	WOE_county_name
	WOE_loan_purpose_name 
	WOE_lien_status_name 
	WOE_agency_abbr 
	WOE_loan_type_property
	GOOD; RUN;



/*TRAINING MÔ HÌNH*/
PROC LOGISTIC DATA=NEW_TRAIN DESCENDING NAMELEN=30 OUTEST=NEW_TRAIN_PARAM;
	MODEL GOOD= 
		WOE_tract_to_msamd_income 
		WOE_applicant_income 
		WOE_ratio_num_owner_family 
		WOE_have_co_applicant 
		WOE_loan_purpose_name 
		WOE_lien_status_name 
		WOE_county_name
		WOE_agency_abbr
		WOE_loan_type_property
		/SELECTION=STEPWISE SLENTRY=0.05 SLSTAY=0.05;
	OUTPUT OUT=NEW_TRAIN_OUTPUT /*TRAIN_OUTPUT*/ PREDICTED=SCORE;
RUN;



DATA NEW_TRAIN_OUTPUT;
	SET NEW_TRAIN_OUTPUT;
	SCORE=ROUND(SCORE*1000);
RUN; 


/*CHIA ĐIỂM THÀNH 20 PHẦN*/
%CONT2(NEW_TRAIN_OUTPUT,SCORE,20); 



PROC FORMAT;/* SCORE */
	VALUE SCOREF LOW-619 = '[01] LOW-619' 619<-696 = '[02] 619<-696' 
	696<-803 = '[03] 696<-803' 803<-882 = '[04] 803<-882' 
	882<-956 = '[05] 882<-956' 956<-HIGH = '[06] 956<-HIGH';
RUN;



/*CHẠY MACRO TÍNH TOÁN GINI*/
%NRUNBOOKP(NEW_TRAIN_OUTPUT, SCORE, GOOD, SCOREF.);






