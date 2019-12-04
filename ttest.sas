/*********************************************************************************************************
Original Reporting Effort:  S:\JNJ-42756493\DATACENTER_NA\BLC2001\DBR_CSR\RE_CSR\
Program Name             : tbmct02_qc.sas 
SAS Version              : 9.2
Short Description        : Program to QC tbmct02
Author                   : Lee Wan
Date                     : 12Dec2017
Input                    : a_in.adbio,a_in.adsl
Output                   : tbmct02_qc.txt
Remarks                  :  
Macro Parameters         :
Macro Sample Call        :
Modification History     :
Rev #   Modified By   Reporting effort                          Date      Description

***********************************************************************************************************/

dm "log; clear; output; clear;";
 
** Kill all the working datasets;
proc datasets nolist memtype=data library=work kill;;
run;
quit;

%let pgm1=tbmct02;
%let pgm2=tbmct03;


proc format;
   picture pctfmt  (round)
                   0.1 <- < 10       = "09.9%)"   (prefix="(")
                   10 - < 100        = "00.0%)"   (prefix="(")
                   100 - high        = "(100.0%)"  (noedit);
run;

***************************************************************************************************;
* Body of program                                                                                  ;
***************************************************************************************************;
data adsl;
  set a_in.adsl;
  where treatfl='Y';
  if RSPINVFL='Y' then RSPINVFL='A';
  if RSPINVFL='N' then RSPINVFL='B';
run;

proc sort data=a_in.adbio out=adbio;where index(paramcd,'RAWAVG') or index(paramcd,'DELTA');by usubjid;run;

data pop;
  merge adbio(in=a) adsl(in=b);
  if a and b;
  by usubjid;
  if trtp='8 mg' then trtpn=1;
  if trtp='6 mg' then trtpn=2;
  if trtp='10 mg (7 d on/7 d off)' then trtpn=3;
  if index(paramcd,'RAWAVG') then paramcd='RAWAVG';
  if index(paramcd,'DELTA') then paramcd='DELTA';
run;

data ana;
  set pop;output;
  trtpn=4;output;
run;
*************************;

proc sort data=ana;by paramcd PARCAT2 trtpn RSPINVFL;run;

proc means data=ana noprint;
 by paramcd parcat2 trtpn RSPINVFL;
 var aval;
 output out=means n=n_ mean=mean std=std median=median_ min=min max=max;
run;

proc sql noprint;
  create table ttest as
  select *
  from ana
  group by paramcd,parcat2,trtpn
  having count(distinct RSPINVFL)=2;
quit;

ods output ttests=pvalue equality=equality;;
proc ttest data=ttest;
  by paramcd parcat2 trtpn;
  var aval;
  class RSPINVFL;
run;

data t;
  merge pvalue equality;
  by paramcd parcat2 trtpn;
  if (PROBF>0.05 and VARIANCES='Equal') or (.<PROBF<0.05 and VARIANCES='Unequal') then output;
run;

data test;
  set t;
  RSPINVFL='A';
run;

data range;
  length N Mean_sd median range $100;
  set means;
  N=strip(put(n_,best.));
  if mean ne . then do;
    if std ne . then
    Mean_SD=strip(put(mean,10.2))||' ('||strip(put(std,10.3))||')';
	else Mean_sd=strip(put(mean,10.2))||' (-)';
  end;
  else Mean_sd='NE (-)';

  median=strip(put(median_,10.2));
  range='('||strip(put(min,10.1))||', '||strip(put(max,10.1))||')';
run;

data p;
  length p $100;
  merge range test;
  by paramcd parcat2 trtpn RSPINVFL;
  
  if PROBT ne . then p=strip(put(PROBT,10.3));
  if .<PROBT<0.001 then p='<.001';

run;

proc transpose data=p out=tran prefix=col;
  by paramcd parcat2;
  id trtpn RSPINVFL;
  var N mean_sd median range P;
run;

data ord;
  set tran;
  if _name_='N' then ord=1;
  if _name_='MEAN_SD' then ord=2;
  if _name_='MEDIAN' then ord=3;
  if _name_='RANGE' then ord=4;
  if _name_='P' then ord=5;
run;

proc sort data=ana out=dummy(keep=paramcd parcat2) nodupkey;by paramcd parcat2;run;

data zero;
  length col1a col1b col2a col2b col3a col3b col4a col4b $100;
  set dummy;
    do ord=1 to 5;
	  col1a='0';col1b='0';col2a='0';col2b='0';col3a='0';col3b='0';col4a='0';col4b='0';output;
	end;
run;

proc sort data=ord;by paramcd parcat2 ord;run;

data final;
  merge zero ord;
  by paramcd parcat2 ord;
  array col(8) col1a col1b col2a col2b col3a col3b col4a col4b;
    do i=1 to 8;
	  if ord ne 1 and col(i)='0' then col(i)='';
	  if ord=1 and col(i)='' then col(i)='0';
	  if col(i)='0.000' then col(i)='<.001';
	end;
  if col1A='' and ord=5 then col1A='NE';
  if col2A='' and ord=5 then col2A='NE';
  if col3A='' and ord=5 then col3A='NE';
  if col4A='' and ord=5 then col4A='NE';
run;

data end;
  set final;
  if PARCAT2='Any FGFR Alteration' then aval=1;
  if PARCAT2='Any Mutation' then aval=2;
  if PARCAT2='FGFR3 R248C' then aval=3;
  if PARCAT2='FGFR3 S249C' then aval=4;
  if PARCAT2='FGFR3 G370C' then aval=5;
  if PARCAT2='FGFR3 Y373C' then aval=6;
  if PARCAT2='Any Fusion' then aval=7;
  if PARCAT2='FGFR2 BICC1' then aval=8;
  if PARCAT2='FGFR2 CASP7' then aval=9;
  if PARCAT2='FGFR3 BAIAP2L1' then aval=10;
  if PARCAT2='FGFR3 TACC3_V1' then aval=11;
  if PARCAT2='FGFR3 TACC3_V3' then aval=12;
run;

proc sort data=end;by aval;run;

data &pgm1._qc;
  set end;
  where paramcd='RAWAVG';
  rename col1a=col1 col1b=col2 col2a=col3 col2b=col4 col3a=col5 col3b=col6 col4a=col7 col4b=col8;
  keep col:;
run;
 
data &pgm2._qc;
  set end;
  where paramcd='DELTA';
  rename col1a=col1 col1b=col2 col2a=col3 col2b=col4 col3a=col5 col3b=col6 col4a=col7 col4b=col8;
  keep col:;
run;
***************************************************************************************************;
* EQC                                                                                              ;
***************************************************************************************************;
data &pgm1.;
  set tablein.&pgm1.;
  where ROW_TYPE not in ('TITLE') and ROW_TEXT ne 'No data to report';
  keep col:;
run;

data &pgm2.;
  set tablein.&pgm2.;
  where ROW_TYPE not in ('TITLE') and ROW_TEXT ne 'No data to report';
  keep col:;
run;

proc printto print="&opath\&pgm1._qc.txt" new;
run;

proc compare base=&pgm1. compare=&pgm1._qc listall criterion=0.00000001 maxprint=(50,32767);
run; 

proc printto;
run;

proc printto print="&opath\&pgm2._qc.txt" new;
run;

proc compare base=&pgm2. compare=&pgm2._qc listall criterion=0.00000001 maxprint=(50,32767);
run; 

proc printto;
run;

***************************************************************************************************;
* Calling macro %ut_saslogcheck to check log                                                       ;
***************************************************************************************************;


%ut_saslogcheck;
