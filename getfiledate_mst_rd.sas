/*****************************************************************************************
 MacroStat(China) Clinical Research Cp., Ltd
 PROGRAM NAME       : getfiledate.sas
 PROGRAM TYPE       : Macro
 DESCRIPTION        : Create Macro list
 Input data         : all study name
 Output data        : XLSX file with study name and latest date

 MACRO PARAMETER    :
 -----------------------------------------------------------------------------------------
  Name        Type      Default      Description and Valid Values
 ---------    --------  -----------  ---------------------------------------------------
  -----------------------------------------------------------------------------------------
 SOFTWARE/VERSION#  :SAS/VERSION 9.4
 -----------------------------------------------------------------------------------------
  Program History:
  Ver#  YYYY-MM-DD    Author              Modification History Description
  ----  ------------  -----------------   ------------------------------------------------
  001   2019-09-19    Lee Wan             Create/Structure the macro
*******************************************************************************************
**Please run the program in \\10.0.55.98
*******************************************************************************************/
proc datasets nolist memtype=data library=work kill;;
run;quit;
dm 'output; clear;';
dm 'log; clear;';

proc import datafile="\\MST13\Project management\Folder Structure\Naming Convention and Project Information.xlsx" 
             out=list(keep=Name_on_Server__Region_Client_Th rename=Name_on_Server__Region_Client_Th=name) REPLACE;
			 sheet='Project Name on Server';
run;
			 
proc sql noprint;
  select distinct name into:name separated by '|' from list;
quit;

%macro check(day=);
%let i=1;

%do %until (%scan(&name,&i,'|') = );
    %let studyid=%scan(&name,&i,'|');
	%let path=\\Mst13\&studyid\;

    %global exit;
    %if %sysfunc(fileexist(&path)) %then %do;
      %let exit=1; 
    %end;                                                                                             
    %else                                                                                                                                 
    %put The folder &studyid does not exist.;  

    %if &exit=1 %then %do;

	    Filename filelist pipe "dir /b /s &path*"; 
		 
		data file;                                        
		 Infile filelist truncover;
		 Input filename $2000.;
		 if prxmatch('/\\\$|\~\$/',&path) then delete;
		run; 

		data date;
		  length study $200;
		  set path;
		  rcs = filename("fileref", filename);
		  fid=fopen('fileref');
		  if fid=0 then delete;
		  moddate=input(scan(finfo(fid,'Last Modified'),1,':'),date9.);
		  study="&studyid";
		  rc = fclose(fid);
		  rcc = filename("fileref");
		  format moddate yymmdd10.;
		run;

		proc sql noprint;
		  create table studyname as
		  select distinct study,max(moddate) as lastdate
		  from date
		  group by study
		  having (input("&sysdate.",date9.)-max(moddate))>=&day.;
		quit;

		proc append base=all data=studyname;
		run;

		%let exit=0;
	%end;
	%let i=&i+1;
%end;
%mend check;

%check(day=180);

proc export data=all outfile="\\MST13\Project management\Folder Structure\check" dbms=xlsx replace;
run;
