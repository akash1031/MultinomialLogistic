data rfmtest;
set panelGrocData;
NPANID = input(PANID, 7.);
NDOLLARS = input(DOLLARS, 4.2);
NWEEK = input(WEEK, 4.);
NUNITS = input(UNITS, 1.);
run;

%aaRFM;
%EM_RFM_CONTROL
(
   Mode = T,              
   InData = WORK.rfmtest,            
   CustomerID = NPANID,        
   N_R_Grp = 5,         
   N_F_Grp = 5,         
   N_M_Grp = 5,         
   BinMethod = I,          
   PurchaseDate = NWEEK,      
   PurchaseAmt = NDOLLARS,       
   SetMiss = Y,                                                         
   SummaryFunc = SUM,      
   MostRecentDate = ,    
   NPurchase = ,         
   TotPurchaseAmt = ,    
   MonetizationMap = Y, 
   BinChart = Y,        
   BinTable = Y,        
   OutData = WORK.RFM_TABLE,           
   Recency_Score = recency_score,     
   Frequency_Score = frequency_score,   
   Monetary_Score = monetary_score,    
   RFM_Score = rfm_score           
);

PROC IMPORT OUT= WORK.clusterdata1 
            DATAFILE= "C:\Users\axc160930\Desktop\rfm_demo_merged1.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

proc sql;
create table FC as select 
NPANID, 
case when rfm_score in (111,112,113,121,122,123,131,132,211,212,221,222,311,312,321,411,412,421,422,511,512,521,522  ) then 4
when rfm_score in (133,134,142,143,223,224,232,233,234,242,243,313,322,323,324
332,
333,
342,
423,
424,
432,
523,
531,
532
) then 3
when rfm_score in (244,
145,
155,
144,
334,
335,
343,
353,
433,
434,
435,
443,
453,
533,
534,
542,
543,
553
 ) then 2
 ELSE 1
end as cluster
from clusterdata1;
run;

proc sql;
create table clst1 as
select distinct a.*, b.cluster from clusterdata1 a left join FC b on a.NPANID = b.NPANID; run;

proc tabulate data = clst1 out = graph1;
var rfm_score Combined_Pre_Tax_Income_of_HH Family_Size Type_of_Residential_Possession 
Male_Age_Group Male_Education Female_Age_Group Female_Education Children_Group_Code Marital_Status; 
class cluster;
format cluster;
table cluster = ' ',
n pctn='Market Share' (Combined_Pre_Tax_Income_of_HH Family_Size Type_of_Residential_Possession Male_Age_Group Male_Education
Female_Age_Group Female_Education Children_Group_Code Marital_Status ) * mean = ' '/box = 'Cluster';
run;

proc sql;
select DISTINCT(rfm_score)
from RFM_TABLE;
quit;

proc means data = clst1 n mean var;
class cluster;
run;



proc export 
  data=work.finalmergedpg
  dbms=csv 
  outfile="C:\Users\axc160930\Desktop\finalmergedpg.csv" 
  replace;
run;


PROC CONTENTS DATA = panelGrocData;
run;

PROC PRINT DATA= graph1;
run;
