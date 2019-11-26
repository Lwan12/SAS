/*******************************************************************************
Program/Macro: adam_blfl.sas
Lang/Vers:     SAS V9.4
Description:   Create variable xxblfl
Author:        Lee Wan
Date:          Sep, 2019
Parameters:    domain:     req - domain name
               indata:     req - input dataset name
               outdata:    req - output dataset name
               date:       req - domain date variable such as vsdt(numeric)
               compvar:    req - if there are more then one record on the same date, you can use visitnum or xxseq to mark one item.
                                 such as visitnum or visitnum|vsseq
  --- Sample 1
  %adam_blfl(domain=vs,indata=vs,outdata=vslfl,date=vsdt,compar=visitnum|vseq);
Modification History:
Rev #      Modified By      Reporting Effort               Date      Description
*******************************************************************************/
option mprint;

%macro adam_blfl(domain=,indata=,outdata=,date=,compvar=,bdate=trtsdt);
%local c;
%let c=1;
proc sql noprint;
  create table &outdata as
  select *,case when a.&date=max(a.&date) 
         %do %until (%scan(&compvar,&c,'|') EQ );
            and a.%scan(&compvar,&c,'|')=max(a.%scan(&compvar,&c,'|'))
            %let c=&c+1;
         %end;
         then 'Y' else '' end as ablfl
  from &indata(where=(&date<=&bdate)) as a
  group by usubjid,&domain.testcd
  union
  select *,'' as ablfl
  from &indata(where=(&date>&bdate))
  order by usubjid,&domain.testcd,&date;
quit;
%mend adam_blfl;

