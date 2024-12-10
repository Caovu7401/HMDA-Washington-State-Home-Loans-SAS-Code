/*PHẦN CODE NÀY CHIA DỮ LIỆU THÀNH CÁC FILE TRAIN VÀ VAL*/
/*---------------------------------------------------------------------------*/
/*1.ĐỌC VÀ KIỂM TRA DỮ LIỆU*/
LIBNAME DATA "/home/u64047063/7.BIG PROJECT (FIX)";
OPTIONS MSTORED SASMSTORE=DATA;

PROC IMPORT DATAFILE="/home/u64047063/7.BIG PROJECT (FIX)/Datasets/6_2_HMDA_WA_Home_Loan_FIXED_BINS.csv" 
		OUT=DATA.IMPORT DBMS=CSV REPLACE;
	GETNAMES=YES;
RUN;



/*---------------------------------------------------------------------------*/
/*2.Phân chia điểm dữ liệu Good-Bad*/
DATA DATA.IMPORT;
	SET DATA.IMPORT;

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
/*3.Chỉnh sửa lại định dạng của các biến trong data, chủ yếu là biến phân loại*/
/*Ở đây tập trung vào việc sửa lại các định dạng dữ liệu bị nhiễu, hoặc bị khuyết mất 
ký tự khi chuyển từ file csv qua*/
PROC CONTENTS DATA=DATA.IMPORT;
RUN;



DATA DATA.IMPORT;
	/* Thiết lập độ dài, định dạng và định dạng nhập liệu cho tất cả các biến */
	length agency_abbr $30 applicant_ethnicity_name $30 applicant_race_name_1 $30 
		applicant_sex_name $30 co_applicant_ethnicity_name $30 
		co_applicant_race_name_1 $30 co_applicant_sex_name $30 county_name $30 
		edit_status_name $30 hoepa_status_name $30 lien_status_name $30 
		loan_purpose_name $30 loan_type_name $30 msamd_name $50 
		owner_occupancy_name $50 property_type_name $30;
	format agency_abbr $30. applicant_ethnicity_name $30. 
		applicant_race_name_1 $30. applicant_sex_name $30. 
		co_applicant_ethnicity_name $30. co_applicant_race_name_1 $30. 
		co_applicant_sex_name $30. county_name $30. edit_status_name $30. 
		hoepa_status_name $30. lien_status_name $30. loan_purpose_name $30. 
		loan_type_name $30. msamd_name $50. owner_occupancy_name $50. 
		property_type_name $30.;
	informat agency_abbr $30. applicant_ethnicity_name $30. 
		applicant_race_name_1 $30. applicant_sex_name $30. 
		co_applicant_ethnicity_name $30. co_applicant_race_name_1 $30. 
		co_applicant_sex_name $30. county_name $30. edit_status_name $30. 
		hoepa_status_name $30. lien_status_name $30. loan_purpose_name $30. 
		loan_type_name $30. msamd_name $50. owner_occupancy_name $50. 
		property_type_name $30.;
	set DATA.IMPORT;
RUN;


/*Value counts cho các biến phân loại*/
PROC FREQ data=DATA.IMPORT;
	tables property_type_name owner_occupancy_name msamd_name loan_type_name 
		loan_purpose_name lien_status_name hoepa_status_name edit_status_name 
		county_name co_applicant_sex_name co_applicant_race_name_1 
		co_applicant_ethnicity_name applicant_sex_name applicant_race_name_1 
		applicant_ethnicity_name agency_abbr;
RUN;



/*4.Một số giá trị trong biến bị khuyết mất ký tự, cần sửa lại*/
/*property_type_name*/
PROC FORMAT;
    value $propertyfmt
        "One-to-four family dwelling (o" = "One-to-four family dwelling";
RUN;
DATA DATA.IMPORT;
    set DATA.IMPORT;
    property_type_name = put(property_type_name, $propertyfmt.);
RUN;


/*loan_type_name*/
PROC FORMAT;
    value $loantypefmt
        "FSA/RHS-guara" = "FSA/RHS-guaranteed";
RUN;
DATA DATA.IMPORT;
    set DATA.IMPORT;
    loan_type_name = put(loan_type_name, $loantypefmt.);
RUN;


/*lien_status_name*/
PROC FORMAT;
    value $lienfmt
        "Secured by a subordinat" = "Secured by a subordinate";
RUN;
DATA DATA.IMPORT;
    set DATA.IMPORT;
    lien_status_name = put(lien_status_name, $lienfmt.);
RUN;


/*county_name*/
PROC FORMAT;
    value $countyfmt
        "Grays Harbor Count" = "Grays Harbor County"
        "Pend Oreille Count" = "Pend Oreille County";
RUN;
DATA DATA.IMPORT;
    set DATA.IMPORT;
    county_name = put(county_name, $countyfmt.);
RUN;


/*applicant_race_name_1*/
PROC FORMAT;
    value $racefmt
        "Ameri" = "American Indian"
        "Black" = "Black or Africa"
        "Nativ" = "Native Hawaiian";
RUN;
DATA DATA.IMPORT;
    set DATA.IMPORT;
    applicant_race_name_1 = put(applicant_race_name_1, $racefmt.);
RUN;
/*---------------------------------------------------------------------------*/



DATA DATA.IMPORT;
    set DATA.IMPORT(rename=(num_1_4_family=num_family_dwelling));
RUN;


/*5.Chia dữ liệu thành tập train và val*/
%POP_SPLIT(DATA.IMPORT, DATA.TRAIN, DATA.VALID, 0.7, BAD);





