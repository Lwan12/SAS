/**************************************************************************************************************************************************
Eli Lilly and Company - GSS (required)                                                                                                             
code name (required)                : /lillyce/prd/ly3009806/i4t_mc_jvcy/csr1/programs/primary/tfl/osi_asm_single_output_parta.sas                      
PROJECT NAME (required)             : I4T-MC-JVCY                                                                             
DESCRIPTION (required)              : To produce OSI PDF file                                                                                         
specifications(required)            :                                         
VALIDATION TYPE (required)          : Peer review                                                                                                  
independent replication (required)  : N/A peer review                                                                                              
ORIGINAL CODE (required)            : N/A, it is original code                                                                                     
COMPONENT CODE MODULES              : None.                                                                                                        
SOFTWARE/VERSION# (required)        : SAS Enterprise Guide 7.1                                                                                     
INFRASTRUCTURE                      : CLUWE                                                                                                        
DATA INPUT                          : /lillyce/prd/ly3009806/i4t_mc_jvcy/csr1/output/shared/tfl/osi/bookmark_osi_jvcy_parta.xlsx                                               
OUTPUT                              : /lillyce/prd/ly3009806/i4t_mc_jvcy/csr1/output/shared/tfl/bimo_item_2_jvcy_parta.pdf  
                                      /lillyce/prd/ly3009806/i4t_mc_jvcy/csr1/primary/tfl/log/osi_asm_single_output_parta.log
                                      /lillyce/prd/ly3009806/i4t_mc_jvcy/csr1/primary/tfl/log/osi_asm_single_output_parta.lst
SPECIAL INSTRUCTIONS                : N/A                                                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------  
-------------------------------------------------------------------------------------------------------------------------------------------------  
DOCUMENTATION AND REVISION HISTORY SECTION (required):                                                                                             
                                                                                                                                                   
       Author &                                                                                                                                    
Ver# Validator            Code History Description                                                                                                 
---- ----------------     -----------------------------------------------------------------------------------------------------------------------  
1.0  Yi He           Original version of this code. 
     Gongxian Jia    Peer review 
**eoh***********************************************************************************************************************************************/
                                                                                                                                                     
 %macro output(name=,outfile1=,excel=);
                                                                                                                                                                                                                                                                                   
/*%let setup=/qa/ly3009806/i4t_mc_jvcy/csr1/programs/setup_osi.sas;                                                                             */
%let setup=/prd/ly3009806/i4t_mc_jvcy/csr1/programs/setup.sas;                                                                             
                                                                                                                                                  
*** macro setexecpath makes it possible to work both in EG and PC SAS***;                                                                            
%macro setexecpath;                                                                                                                                  
  %global root;                                                                                                                                      
  %let root = %sysfunc(ifc(&SYSSCP. = WIN, //statsclstr/lillyce, /lillyce));                                                                         
  %let setup=&root.&setup;                                                                                                                           
    %include "&setup";                                                                                                                               
%mend setexecpath;  
%setexecpath;  

%let pgmname=&name.;                                                                                                                  
%let outfile=&outfile1.;                                                                                                                            
%let outputtype=TFL; 
                                                                                                                                                     
/* macro thepreproc use proc printto to change the log destination. Please skip this if need log check*/                                             
/*%thePreProc;   */
%let prg=&__snapshot/programs/primary/tfl;
%let log=&__snapshot/programs/primary/tfl/log;
%let adamcustom=&__snapshot/data/analysis/shared/custom;
options sasautos=("&bumlib" "&prg");

proc printto log="&log./&pgmname..log" new;
run;      

proc datasets lib=work kill nolist; quit;   
*********** SET ENVIROMENT PARAMETERS **********************************************************;                                                    
                                                                                                                                                     
options center nodate fmtsearch=(work library) missing=''   source notes nonumber ;                                                                  
options orientation=landscape topmargin=1 in bottommargin=1 in leftmargin=1 in rightmargin=1 in ;                                                    
                                                                                                                                                     
*********** SET INPUT EXCEL FILE CONTAINING LISTING NAMES AND BOOKMARK VIA THE ORDERS SPECIFIED *******************;                                 
                                                                                                                                                     
%let input=&outdir./osi/&excel..xlsx;                                                                                                                        
                                                                                                                                                     
********** INPUT EXCEL FILE IS WITH THE PROGRAM FILE, WHICH IS FINE TO BE CHANGED ********************************;                                  


proc import datafile="&input." out=toc_ replace dbms=xlsx;                                                                                   
run;   
                                                                                                                                                     
**********************************************************************************************************************;                              
**********************************************************************************************************************;                              
*** STOP HERE !!! ****************************************************************************************************;                              
*** PLEASE DO NOT MAKE CHANGES FOR BELOW CODE !!! ********************************************************************;                              
**********************************************************************************************************************;                              
**********************************************************************************************************************;                              
                                                                                                                                                     
data toc1_; set toc_;                                                                                                                                
length nfile $100;                                                                                                                                   
nfile=strip(tranwrd(lowcase(file),'.lst',' '));                                                                                                      
run;                                                                                                                                                 
                                                                                                                                                     
data filelist_(keep=nlst nfile nnext);                                                                                                               
   length nlst nfile nnext $100;                                                                                                                     
   rc=filename('dir',"&outdir.");                                                                                                                     
   dirid=dopen('dir');                                                                                                                               
   numsel=dnum(dirid);                                                                                                                               
                                                                                                                                                     
   do i=1 to numsel;                                                                                                                                 
     nlst=dread(dirid,i);                                                                                                                            
     nfile=scan(nlst, 1, '.');                                                                                                                       
     nnext=upcase(scan(nlst, 2, '.'));                                                                                                               
     if indexw("LST", upcase(nnext)) then output;                                                                                                    
                                                                                                                                                     
   end;                                                                                                                                              
                                                                                                                                                     
   rc=dclose(dirid);                                                                                                                                 
run;                                                                                                                                                 
                                                                                                                                                     
proc sort data=filelist_; by nfile; run;                                                                                                             
proc sort data=toc1_; by nfile; run;                                                                                                                 
                                                                                                                                                     
data file_list_; merge filelist_(in=a) toc1_(in=b ); by nfile;                                                                                       
if a and b;                                                                                                                                          
run;                                                                                                                                                 
                                                                                                                                                     
proc sort data=file_list_; by seq; run;                                                                                                              
                                                                                                                                                     
%let nfile=lsae_osi;                                                                                                                                 
                                                                                                                                                   
%macro read(nfile=, title=, seq=, bookmark=);                                                                                                        
filename lstfile "&outdir./&nfile..lst";                                                                                                              
                                                                                                                                                     
data _tmp1_  ;                                                                                                                                       
   length fst_line $100 site $50;                                                                                                                    
   retain maxlen 0 counting 1 fst_line site ;                                                                                                        
   infile lstfile lrecl=200 pad missover end=eof;                                                                                                    
   input @1 text $char200.;                                                                                                                          
                                                                                                                                                     
   maxlen=max(maxlen,length(trim(text)));                                                                                                            
                                                                                                                                                     
   if _n_=1 then fst_line=substr(text,1,100);                                                                                                        
   if substr(text,2,100)=fst_line then counting+1;                                                                                                   
                                                                                                                                                     
   if index(lowcase(compress(text)), 'site:') then site_line=1;                                                                                      
   pattID = prxparse("/(\d+)/");                                                                                                                     
   call prxsubstr(pattID, text, pos, len);                                                                                                           
   if pos>0 and site_line=1 then site=substr(text,pos,len);                                                                                          
                                                                                                                                                     
run;                                                                                                                                                 
                                                                                                                                                     
filename lstfile clear;                                                                                                                              
                                                                                                                                                     
data _tmp2_; set _tmp1_; by counting;                                                                                                                
if last.counting;                                                                                                                                    
keep site counting;                                                                                                                                  
run;                                                                                                                                                 
                                                                                                                                                     
proc freq data=_tmp2_ noprint;                                                                                                                       
tables site/out=_page1_;                                                                                                                             
run;                                                                                                                                                 

proc sort data=_page1_; by site; run; 
proc sort data=_tmp2_; by site; run; 

data &nfile._page_; merge _page1_(keep=site count rename=(count=_totpage_)) _tmp2_; by site;                                                         
 length title bookmark $200 seq 8.;                                                                                                                  
  title="&title";                                                                                                                                    
  bookmark="&bookmark";                                                                                                                              
  seq=&seq;                                                                                                                                          
run;                                                                                                                                                 

proc sort data=_tmp1_ ; by counting; run;
proc sort data=&nfile._page_; by counting; run;

data &nfile(compress=yes reuse=yes drop=PGID POS LEN NLEN); merge _tmp1_(drop=PATTID POS LEN SITE) &nfile._page_ ; by counting;                      
text=tranwrd(text,"&nfile.rtf","&nfile.pdf");                                                                                                        
if first.counting and counting >=2 then text=substr(text,2);                                                                                         
                                                                                                                                                     
 length pageXofY tpageXofY npageXofY $50;                                                                                                            
  pgID = prxparse("/page (\d+) of (\d+)/");                                                                                                          
  call prxsubstr(pgID, lowcase(text), pos, len);                                                                                                     
  if pos>0 then pageXofY=substr(text,pos,len);                                                                                                       
                                                                                                                                                     
   retain ct;                                                                                                                                        
  if site ne lag(site) then ct=0;                                                                                                                    
  if first.counting then ct+1;                                                                                                                       
                                                                                                                                                     
  if  not missing(pageXofY) then do;                                                                                                                 
   tpageXofY='page '||compress(put(ct,best.))||' of '||compress(put(_TOTPAGE_,best.));                                                               
   nlen=length(tpageXofY);                                                                                                                           
   if len-nlen>0 then npageXofY=repeat(' ',len-nlen-1)||left(tpageXofY);                                                                             
   else if len-nlen=0 then npageXofY=tpageXofY;                                                                                                      
   else if len-nlen<0 then do; npageXofY=tpageXofY; pageXofY=repeat(' ',nlen-len-1)||left(pageXofY); end;                                            
   text=tranwrd(text,pageXofY,npageXofY);                                                                                                            
  end;                                                                                                                                               
                                                                                                                                                     
run;                                                                                                                                                 
                                                                                                                                                     
proc datasets lib=work nolist;                                                                                                                       
delete _tmp1_ _tmp2_ _page1_;                                                                                                                        
quit;                                                                                                                                                
run;                                                                                                                                                 
%mend read;                                                                                                                                          
                                                                                                                                                     
data chk; set file_list_ end=eof;                                                                                                                    
length text $2000 var1 var2 $10000;                                                                                                                   
text='%read(nfile='||strip(nfile)||',title=%str('||strip(title)||'), seq='||strip(put(seq,best.))                                                          
||', bookmark=%str('||strip(bookmark)||'));';                                                                                                              
call execute(text);                                                                                                                                  
                                                                                                                                                     
retain var1 var2;                                                                                                                                    
var1=catx(' ',var1, nfile);                                                                                                                          
var2=catx(' ',var2, strip(nfile)||'_page_');                                                                                                         
                                                                                                                                                     
if eof then call symput('files',var1);                                                                                                               
if eof then call symput('pages',var2);                                                                                                               
                                                                                                                                                     
run;                                                                                                                                                 
                                                                                                                                                     
data all1(compress=yes reuse=yes); set &files; run;                                                                                                  
                                                                                                                                                     
proc sort data=all1 out=all(compress=yes reuse=yes); by site seq bookmark; run;                                                                      
                                                                                                                                                     
data pages1; set &pages; run;                                                                                                                        
                                                                                                                                                     
proc sort data=pages1 out=pages; by site seq bookmark; run;                                                                                          
                                                                                                                                                     
proc sql noprint;                                                                                                                                    
select distinct site into: sites separated by ' ' from pages order by site;                                                                          
select count(distinct site) into: sitesnum from pages;                                                                                               
quit;                                                                                                                                                
run;                                                                                                                                                 
                                                                                                                                                     
proc datasets lib=work nolist;                                                                                                                       
delete &files &pages;                                                                                                                                
delete all1 pages1;                                                                                                                                  
quit;                                                                                                                                                
run;                                                                                                                                                 
                                                                                                                                                     
ODS PATH work.templat(update) sasuser.templat(read)  sashelp.tmplmst(read);                                                                          
                                                                                                                                                     
proc template;                                                                                                                                       
     define style newrtf;                                                                                                                            
       parent=styles.rtf;                                                                                                                            
       style batch from batch /                                                                                                                      
	        font_face="Courier New"                                                                                                                     
            font_size=8pt;                                                                                                                           
       end;                                                                                                                                          
run;                                                                                                                                                 
                                                                                                                                                     
title;                                                                                                                                               
footnote;                                                                                                                                            
                                                                                                                                                     
options center nodate fmtsearch=(work library) missing='' source notes nonumber  ;                                                                   
OPTIONS FORMCHAR="|____|+|___+=|-/\<>*" ;                                                                                                            
                                                                                                                                                     
options orientation=landscape ;                                                                                                                      
options topmargin=1 in bottommargin=1 in leftmargin=0.1 in rightmargin=0.1 in ;                                                                      
options ls=130 ps=47;                                                                                                                                
options label;                                                                                                                                       
                                                                                                                                                     
%macro prt(site=, osi=osi);                                                                                                                          
data _null_; set pages(where=(site="&site")) end=eof; by seq;                                                                                        
 if eof then call symput('site',strip(site));                                                                                                        
 if eof then call symput('seqn',compress(put(seq,best.)));                                                                                           
 if last.seq then call symput('bookmark'||compress(put(seq,best.)), strip(bookmark));                                                                
run;                                                                                                                                                 
                                                                                                                                                     
%do seq =1 %to &seqn;                                                                                                                                
                                                                                                                                                     
%let path=\s&site.\t&&seq;                                                                                                                           
                                                                                                                                                     
ods document name=work.&osi  dir=(path=&path label="&&bookmark&seq.");                                                                               
data _null_;                                                                                                                                         
	   set all(where=(site="&site" and seq=&seq)) ;                                                                                                     
	   by ct;                                                                                                                                           
	   file print notitles;                                                                                                                             
       if first.ct and _n_ >1 then put _page_;                                                                                                       
       put @1 text $varying130. maxlen;                                                                                                              
	run;                                                                                                                                                
ods document close;                                                                                                                                  
%end;                                                                                                                                                
                                                                                                                                                     
%mend prt;                                                                                                                                           
                                                                                                                                                     
%let deno=50;                                                                                                                                        
%let iternum=%sysfunc(ceil(&sitesnum/&deno));                                                                                                        
%let remainder=%sysfunc(mod(&sitesnum, &deno));                                                                                                      
   
options mprint; 
%macro total_site;                                                                                                                                   
ods listing close;                                                                                                                                   
%do iter=1 %to &iternum;                                                                                                                             
                                                                                                                                                     
 %if &iter < &iternum %then %do;                                                                                                                     
  %do i=1 %to &deno;                                                                                                                                 
    %let siten=%eval((&iter-1)*&deno+&i);                                                                                                            
    %let site=%scan(&sites,&siten);                                                                                                                  
    %put NOTE: &siten  &site;                                                                                                                        
    %prt(site=&site, osi=osi&iter);                                                                                                                  
  %end;                                                                                                                                              
 %end;                                                                                                                                               
 %else %if &iter = &iternum %then %do;                                                                                                               
  %do i=1 %to &remainder;                                                                                                                            
    %let siten=%eval((&iter-1)*&deno+&i);                                                                                                            
    %let site=%scan(&sites,&siten);                                                                                                                  
    %put NOTE: &siten  &site;                                                                                                                        
    %prt(site=&site, osi=osi&iter);                                                                                                                  
  %end;                                                                                                                                              
 %end;                                                                                                                                               
%end;                                                                                                                                                
ods listing ;                                                                                                                                        
%mend total_site;                                                                                                                                    
                                                                                                                                                     
%total_site;                                                                                                                                         
                                                                                                                                                     
%macro mvbkmk(osi=osi, osiout=osiout);                                                                                                               
                                                                                                                                                     
ods listing close;                                                                                                                                   
proc document name=work.&osi;                                                                                                                        
list/levels=all details;                                                                                                                             
ods output Properties=osi_list;                                                                                                                      
quit;                                                                                                                                                
run;                                                                                                                                                 
ods listing;                                                                                                                                         
                                                                                                                                                     
data _tmp3_; set osi_list;                                                                                                                           
length string text $200 site seq $100;                                                                                                               
retain text site seq;                                                                                                                                
                                                                                                                                                     
if upcase(type) in ('DIR') and count(path,'\')=1 then do;                                                                                            
 site=substr(substr(path,1,index(path,'#')-1),3);                                                                                                    
 string="dir \work.&osiout.\; make \s"||strip(site)||'; setlabel s'||strip(site)||" 'Investigative Site "||strip(site)                               
 ||"'; dir \s"||strip(site)||';';                                                                                                                    
end;                                                                                                                                                 
else if upcase(type) in ('DIR') and count(path,'\')=2 then do;                                                                                       
 text=label;                                                                                                                                         
 seq=substr(substr(path,index(path,'t')), 1, index(substr(path,index(path,'t')),'#')-1);                                                             
end;                                                                                                                                                 
else if upcase(type) not in ('DIR') then do;                                                                                                         
 string="link \work.&osi"||strip(path)||' to '||strip(seq)||'; setlabel ' ||strip(seq)||" '"||strip(text)||"'; ";                                    
end;                                                                                                                                                 
if upcase(type) not in ('DIR') or count(path,'\')=1;                                                                                                 
run;                                                                                                                                                 
                                                                                                                                                     
data _tmp1_;                                                                                                                                         
length string $200;                                                                                                                                  
string="proc document name=&osiout.(write); "; output;                                                                                               
run;                                                                                                                                                 
                                                                                                                                                     
data _tmp2_;                                                                                                                                         
length string $200;                                                                                                                                  
string='quit;'; output;                                                                                                                              
string='run;'; output;                                                                                                                               
run;                                                                                                                                                 
                                                                                                                                                     
data _null_; set _tmp1_ _tmp3_ _tmp2_;                                                                                                               
call execute(string);                                                                                                                                
run;                                                                                                                                                 
%mend mvbkmk;                                                                                                                                        
                                                                                                                                                     
%macro bookmark;                                                                                                                                     
                                                                                                                                                     
%do iter=1 %to &iternum;                                                                                                                             
 %mvbkmk(osi=osi&iter., osiout=osiout&iter.);                                                                                                        
%end;                                                                                                                                                
%mend;                                                                                                                                               
                                                                                                                                                     
%bookmark;                                                                                                                                           
                                                                                                                                                     
%macro replay;                                                                                                                                       
                                                                                                                                                     
%do iter=1 %to &iternum;                                                                                                                             
 proc document name=work.osiout&iter.;                                                                                                               
  replay ;                                                                                                                                           
  run;                                                                                                                                               
  quit;                                                                                                                                              
%end;                                                                                                                                                
%mend replay;                                                                                                                                        
                                                                                                                                                     
%let outpdf=&outfile..pdf;                                                                                                                           
%let pdffile=&outdir/&outpdf;  

GOPTIONS device=ACTXIMG;	                                                                                                                                                    
ods listing close;                                                                                                                                   
ods pdf file="&pdffile" style=newrtf BOOKMARKGEN=YES BOOKMARKLIST=SHOW;                                                                              
  %replay;                                                                                                                                           
ods pdf close;                                                                                                                                       
ods listing;                                                                                                                                         
                                                                                                                                                     
***;                                                                                                                                                 
***   End of log file output;                                                                                                                        
***;                                                                                                                                                 
                                                                                                                                                     
/*%thePostProc;     */
proc printto log=log; run;                                                                                                                                                       
%ut_saslogcheck(logfile=&log./&pgmname..log,
                outfile=&log./&pgmname..lst);  
%mend ;
%output(name=osi_asm_single_output_parta,outfile1=bimo_item_2_jvcy_parta,excel=bookmark_osi_jvcy_parta);
/*%output(name=osi_asm_single_output,outfile1=bimo_item_2_jvcy_partb,excel=bookmark_osi_jvcy_partb);*/

