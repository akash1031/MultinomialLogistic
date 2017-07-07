PROC IMPORT OUT= WORK.ProductData 
            DATAFILE= "C:\Users\axc160930\Desktop\productdata.xls" 
            DBMS=xls REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

DATA GrocData;
  INFILE 'H:\predictive\project\saltsnck\saltsnck_groc_1114_1165.dat' FIRSTOBS=2 DELIMITER='';
  INPUT IRI_KEY $ 1-8 WEEK $ 9-13 SY $ 14-16 GE $ 17-19 VEND $ 20-25  ITEM $ 26-31  UNITS $ 32-37 DOLLARS $38-46  F $47-51    D $52-53 PR $54;
RUN;

DATA panelGrocData;
  INFILE 'H:\predictive\project\saltsnck\saltsnck_PANEL_GR_1114_1165.dat' FIRSTOBS=2 DELIMITER='';
  INPUT PANID $ 1-8 WEEK $ 9-13 UNITS $ 14-15 OUTLET $ 16-18 DOLLARS $ 19-23 IRI_KEY $ 24-30 COLUPC $31-41  ;
RUN;

PROC IMPORT OUT= WORK.Demographics
            DATAFILE= "H:\predictive\project\saltsnck\ads demo1.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;



data tryme(drop = FAT_CONTENT COOKING_METHOD SALT_SODIUM_CONTENT );
set ProductData;
oz1=scan(L9,-1,' ');
oz2= compress(oz1,"OZ");
oz=oz2*1;
run;

data test;
    set GrocData;
	sep='-';
	NSY = put(input(SY,best2.),z2.);
	NGE = put(input(GE,best2.),z2.);
	NVEND = put(input(VEND,best5.),z5.);
	NITEM = put(input(ITEM,best5.),z5.);
run;

data newGrocData;
set test;
UPC = CATX(sep,NSY,NGE, NVEND, NITEM);
RUN; 

proc sort data = tryme;
BY UPC;
run;

proc sort data = newGrocData;
BY UPC;
run;

data mergedpg; 
  merge newGrocData  tryme;
  by UPC;
run;

data mergedpg;
set mergedpg;
if BRANDS = 0 THEN DELETE;
RUN;

data finalmergedpg(KEEP = UPC IRI_KEY WEEK BRANDS UNITS DOLLARS oz F D PR);
set mergedpg;
if IRI_KEY = " " THEN DELETE;
if WEEK = " " THEN DELETE;
RUN;

data finalmergedpg;
set finalmergedpg;
ppo = (DOLLARS/UNITS)/oz;
if D= "0" then DISPLAY = 0; ELSE DISPLAY = 1;
IF F = "NONE" THEN FEATURE = 0; ELSE FEATURE = 1;
run;

data finalmergedpg;
set finalmergedpg;
NPR = input(PR, 8.);
run;


proc sql; 
  create table tblformdc as
  SELECT  IRI_KEY,WEEK, BRANDS, AVG(ppo) AS BPRICE, AVG(DISPLAY) AS BDISP, AVG(FEATURE) AS BFEAT , AVG(NPR) AS BPRICERED from finalmergedpg 
  group by IRI_KEY, WEEK, BRANDS
  order by IRI_KEY, WEEK, BRANDS;
quit;

proc sql;
select DISTINCT(decision)
from newmdcdata;
quit;



proc transpose data=tblformdc out=wide1 prefix=price;
    by IRI_KEY WEEK ;
    id BRANDS;
    var BPRICE ;
run;
DATA wide1(drop = _NAME_);
set wide1;
run;

proc transpose data=tblformdc out=wide2 prefix=display;
    by IRI_KEY WEEK ;
    id BRANDS;
    var BDISP ;
run;
DATA wide2(drop = _NAME_);
set wide2;
run;

proc transpose data=tblformdc out=wide3 prefix=feat;
    by IRI_KEY WEEK ;
    id BRANDS;
    var BFEAT ;
run;
DATA wide3(drop = _NAME_);
set wide3;
run;

proc transpose data=tblformdc out=wide4 prefix=prred;
    by IRI_KEY WEEK ;
    id BRANDS;
    var BPRICERED ;
run; 
DATA wide4(drop = _NAME_);
set wide4;
run;

proc sort data = wide1;
BY IRI_KEY WEEK;
run;

proc sort data = wide2;
BY IRI_KEY WEEK;
run;
proc sort data = wide3;
BY IRI_KEY WEEK;
run;

proc sort data = wide4;
BY IRI_KEY WEEK;
run;

data wide1234; 
  merge wide1  wide2 wide3 wide4;
  by IRI_KEY WEEK;
run;


PROC IMPORT OUT= WORK.finalmerge 
            DATAFILE= "C:\Users\axc160930\Desktop\finallymerged.xlsx" 
            DBMS=xlsx REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

data Demographics(drop = COUNTY HH_AGE HH_EDU HH_OCC MALE_SMOKE FEM_SMOKE Language Number_of_TVs_Used_by_HH Number_of_TVs_Hooked_to_Cable Year HISP_FLAG HISP_CAT HH_Head_Race__RACE2_ HH_Head_Race__RACE3_ Microwave_Owned_by_HH ZIPCODE FIPSCODE market_based_upon_zipcode IRI_Geography_Number EXT_FACT );
rename Panelist_ID = PANID;
set Demographics;
run;

proc sort data = Demographics;
BY PANID;
run;

proc sort data = finalmerge;
BY PANID;
run;

data finalmergedemo; 
  merge finalmerge Demographics;
  by PANID;
run;

proc means data= finalmergedemo;
var price1 price2 price3 price4 price5 display1 display2 display3 display4 display5 feat1 feat2 feat3 feat4 feat5 prred1 prred2 prred3 prred4 prred5;
run; 

data testx;
set finalmergedemo;
if price1 ="." then price1 = 0.2531620;
if price2 ="." then price2 = 0.1229173;
if price3 ="." then price3 = 0.2465004;
if price4 ="." then price4 = 0.1721927;
if price5 ="." then price5 = 0.2529072;
if display1 ="." then display1 = 0.2482805;
if display2 ="." then display2 = 0.1242846;
if display3 ="." then display3 = 0.0200605;
if display4 ="." then display4 = 0.0428401;
if display5 ="." then display5 = 0.0595334;
if feat1="." then feat1= 0.0898491 ;
if feat2="." then feat2= 0.0619690;
if feat3="." then feat3= 0.0501762;
if feat4="." then feat4= 0.0324913;
if feat5="." then feat5= 0.0595334;
if prred1="." then prred1 =0.1608833 ;
if prred2="." then prred2 = 0.1730990;
if prred3="." then prred3 = 0.0963525;
if prred4="." then prred4 = 0.1861984;
if prred5="." then prred5 = 0.0150287;
run;

PROC IMPORT OUT= WORK.mdc1 
            DATAFILE= "C:\Users\axc160930\Desktop\mdc1.xlsx" 
            DBMS=xlsx REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;



Data ProductData;
set ProductData;
	NVEND = put(input(VEND,best5.),z5.);
	NITEM = put(input(ITEM,best5.),z5.);
	UPC = CATS(GE, NVEND, NITEM);
run;

data testx;
set testx;
UPC = put(COLUPC, 11.);
run;
	
Data brands(keep= BRANDS UPC);
set ProductData;
if BRANDS = 0 THEN DELETE;
run;



proc sort data= brands;
by UPC;
run;

proc sort data = testx;
by UPC;
run;

data testy; 
  merge testx(in = x) brands(in = y);
  by UPC;
  if x=1;
run;



data mdcdata(keep = pid decision b PANID p d f pr Combined_Pre_Tax_Income_of_HH Family_Size Age_Group_Applied_to_Male_HH Age_Group_Applied_to_Female_HH Children_Group_Code Marital_Status);
set mdc1;
array pvec{5} price1-price5;
array dvec{5} display1-display5;
array fvec{5} feat1-feat5;
array prvec{5} prred1-prred5;
retain pid 0;
pid+1;
do i = 1 to 5;
	b=i;
	p=pvec{i};
	d=dvec{i};
	f=fvec{i};
	pr=prvec{i};
	decision=(BRANDS=i);
	output;
end;
run;

data newmdcdata;
set mdcdata;
b2=0;
b3=0;
b4=0;
b5=0;
if b= 2 then b2= 1;
if b= 3 then b3= 1;
if b= 4 then b4= 1;
if b= 5 then b5= 1;
Combined_Pre_Tax_Income_of_HH2=Combined_Pre_Tax_Income_of_HH*b2;
Combined_Pre_Tax_Income_of_HH3=Combined_Pre_Tax_Income_of_HH*b3;
Combined_Pre_Tax_Income_of_HH4=Combined_Pre_Tax_Income_of_HH*b4;
Combined_Pre_Tax_Income_of_HH5=Combined_Pre_Tax_Income_of_HH*b5;
Family_Size2=Family_Size*b2;
Family_Size3=Family_Size*b3;
Family_Size4=Family_Size*b4;
Family_Size5=Family_Size*b5;
Male_Age_Group2=Age_Group_Applied_to_Male_HH*b2;
Male_Age_Group3=Age_Group_Applied_to_Male_HH*b3;
Male_Age_Group4=Age_Group_Applied_to_Male_HH*b4;
Male_Age_Group5=Age_Group_Applied_to_Male_HH*b5;
Female_Age_Group2=Age_Group_Applied_to_Female_HH*b2;
Female_Age_Group3=Age_Group_Applied_to_Female_HH*b3;
Female_Age_Group4=Age_Group_Applied_to_Female_HH*b4;
Female_Age_Group5=Age_Group_Applied_to_Female_HH*b5;
Children_Group2=Children_Group_Code*b2;
Children_Group3=Children_Group_Code*b3;
Children_Group4=Children_Group_Code*b4;
Children_Group5=Children_Group_Code*b5;
Marital_Status2=Marital_Status*b2;
Marital_Status3=Marital_Status*b3;
Marital_Status4=Marital_Status*b4;
Marital_Status5=Marital_Status*b5;
run;

data newmdcdata;
      set newmdcdata;
      if nmiss(of _all_) = 0 then _include = 1;
      run;
data newmdcdata;
set newmdcdata;
if cmiss(of _all_) then delete;
run;

proc means data=newmdcdata noprint;
      where _include = 1;
      by pid;
      var decision;
      output out=newthree(keep=pid _sum) sum = _sum;
      run;
 data new;
      merge newmdcdata newthree;
      by pid;
      run;


proc mdc data=new;
where _sum ne 0;
model decision = p d f pr b2 b3 b4 b5 Combined_Pre_Tax_Income_of_HH2 Combined_Pre_Tax_Income_of_HH3 Combined_Pre_Tax_Income_of_HH4 Combined_Pre_Tax_Income_of_HH5 Family_Size2 
Family_Size3 Family_Size4 Family_Size5 Male_Age_Group2 Male_Age_Group3 Male_Age_Group4 Male_Age_Group5 Female_Age_Group2 Female_Age_Group3 Female_Age_Group4 
Female_Age_Group5 Children_Group2 Children_Group3 Children_Group4 Children_Group5 Marital_Status2 Marital_Status3 Marital_Status4 Marital_Status5  / type=clogit 
nchoice=5;
id pid;
output out=ssData pred=predicted;
run;
