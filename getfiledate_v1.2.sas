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

option noxwait;

%macro export(pre=);
proc export data=all outfile="\\MST13\Project management\Folder Structure\check_&pre" dbms=xlsx replace;
run;
%mend;

data folder;                                                                                                               
   length nlst nfile nnext $100;                                                                                                                     
   rc=filename('dir',"\\mst13\Project management\Folder Structure\foldername");                                                                                                                     
   dirid=dopen('dir');       
   numsel=dnum(dirid);                                                                                                                                                                                                                                                                 
   do i=1 to numsel;                                                                                                                                 
     nlst=dread(dirid,i);                                                                                                                            
     nfile=scan(nlst, 1, '.');                                                                                                                       
     nnext=upcase(scan(nlst, 2, '.')); 
     foldername=tranwrd(nlst,'(mst13) - Shortcut.lnk',''); 
     output;                                                                                                                                                                                                                                   
   end;                                                                                                                                                                                                                                                                                                 
   rc=dclose(dirid);                                                                                                                                 
run;  

proc sql noprint;
  select foldername into:name separated by '|' from folder;
quit;

%put &name;
/*%let path=\\mst13\G_050_END_4010.PCT001\;*/
%macro check(day=);
%let i=1;

%do %until ("%scan(&name,&i,'|')" = "");
    %let studyid=%scan(&name,&i,'|');
    %let path=\\Mst13\&studyid\;

    %global exit;
    %if %sysfunc(fileexist(&path)) %then %do;
      %let exit=1; 
    %end;          
 
    %else %do;                                                                                                                               
    %put The folder &studyid does not exist.;  
  data nopath;
    length study $200 flag $1 path $20;
    study="&studyid";
    lastdate=.;
    path="Not exist";
    flag='';
    format lastdate yymmdd10.;
  run;
    proc append base=all data=nopath;
    run;
  %end;

    %if &exit=1 %then %do;

      Filename filelist pipe "dir /b /s &path*"; 
     
    data file;                                        
     Infile filelist truncover;
     Input filename $2000.;
     if prxmatch('/\\\$|\~\$/',filename) then delete;
	 if index(filename,'¨p©Ø¨b¨²?¨Z¨c') then delete;
    run; 
  
    data date;
      length study $200;
      set file;
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
      select distinct study,max(moddate) as lastdate format=yymmdd10., '' as path length=20,
      case when  (input("&sysdate.",date9.)-max(moddate))>=&day. then 'Y' else '' end as flag
      from date;
    quit;

	data studyname;
	  set studyname;
	  if study='' then do;study="&studyid";path="this is empty project";end;
	run;

    proc append base=all data=studyname;
    run;

    %let exit=0;
  %end;
  %let i=%eval(&i+1);

  dm 'output; clear;';
  dm 'log; clear;';

/*  %if %sysfunc(MOD(&i,50))=0 %then %do;*/
/*  %export(pre=&i);*/
/*  %end;*/

  data _null_;
    x=sleep(1);
  run;

%end;
%mend check;

%check(day=180);


