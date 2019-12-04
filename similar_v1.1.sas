/*****************************************************************************************
 MacroStat(China) Clinical Research Cp., Ltd
 PROGRAM NAME       : check_similar_characters.sas
 PROGRAM TYPE       : Macro
 DESCRIPTION        : Check similar characters in two datasets

 MACRO PARAMETER    :
 -----------------------------------------------------------------------------------------
  Name        Type      Default      Description and Valid Values
 ---------    --------  -----------  ---------------------------------------------------
  olddata     required               location for old data path
  newdata     required               location for new data path
  delete      required               delete no need compare variable
  edit                  0.9          Similarity ratio and if null then do not run the edit algorithm.
  cos                   0.95         Similarity ratio and if null then do not run the cos algorithm.
  -----------------------------------------------------------------------------------------
 SOFTWARE/VERSION#  :SAS/VERSION 9.4
 -----------------------------------------------------------------------------------------
  Program History:
  Ver#  YYYY-MM-DD    Author              Modification History Description
  ----  ------------  -----------------   ------------------------------------------------
  001   2019-09-18    Lee Wan             Create/Structure the macro
*******************************************************************************************
**Example: ;
%let olddata=\\mst13\MST_Standards\SA\Test\Programming\Data\raw;
%let newdata=\\mst13\MST_Standards\SA\Test\Programming;
%let delete  = 'USUBJID' 'VISIT' 'STUDYID';
%let edit    =0.9;
%let cos     =0.95;
*******************************************************************************************/
proc datasets nolist memtype=data library=work kill;;
run;quit;
dm 'output; clear;';
dm 'log; clear;';

*************************************************************************************;
** MUST CHANGE THE FOLLOWING MACRO VARIABLE TO THE CORRECT LOCATION FOR EACH STUDY **;
%let olddata = \\mst13\C_092_ONC_CS1001_301\FAS\Original\Datasets\sdtm\;
%let newdata = \\mst13\C_092_ONC_CS1001_301\FAS\Received\2019-07-01\20190701\SDTM\;
%let delete  = 'USUBJID' 'VISIT' 'STUDYID';
%let edit    =0.95;     *\0-1,closer 1, more similar\*;
%let cos     =0.98;    *\0-1,closer 1, more similar\*;
*************************************************************************************;



*************************************************************************************;
** DO NOT CHANGE THE FOLLOW CODE                                                   **;
*************************************************************************************;
libname old "&olddata." access=readonly;
libname new "&newdata." access=readonly;

**********************************************************************;

%macro reassemble(lib=);

proc sql noprint;
  select distinct memname into:name separated by '|' from sashelp.vcolumn where libname="&lib";
quit;

%put &name;

%let i=1;
%do %until (%scan(&name,&i,'|') = );
  %let sdomain=%scan(&name,&i,'|');
  %if %index(&sdomain,SUPP) %then %do;
  data &sdomain;
    length varname $100 variable $200;
    set &lib..&sdomain;
    varname=qnam;
    variable=qval;
    domain=rdomain;
    if compress(qval,"1234567890T-:NY") = "" then delete;
    keep domain varname variable;
  run;

  proc append base=&lib data=&sdomain;
  run;
  %end;
  %else %if %index(%upcase(&sdomain),REL)=0 %then %do;
  data &sdomain;
    length varname $100 variable $200;
    set &lib..&sdomain;
    array vars _character_;
    do over vars;
      if vars ne '' then do;
        varname=vname(vars);
        variable=vars;
        if compress(vars,"1234567890T-:NY.") ne "" then output;
      end;
    end;
    keep domain varname variable;
  run;

  proc append base=&lib data=&sdomain;
  run;
  %end;
  %let i=&i+1;
%end;
proc sort data=&lib nodupkey;where varname not in (&delete);by domain varname variable;run;
%mend reassemble;

%reassemble(lib=OLD);
%reassemble(lib=NEW);


%macro check;
proc sql noprint;
  create table test as
  select a.domain,a.varname,a.variable as var,b.variable as col
  from old as a,new as b
  where a.domain=b.domain and a.varname=b.varname;
quit;

/*proc sort data=test nodupkey;by &usbjd var col;run;*/


proc sql noprint;
  select max(length(strip(var))) into:vmax from test;
  select max(length(strip(col))) into:cmax from test;
  select max(length(strip(col)))+max(length(strip(var))) into:max from test;
quit;

%let max=&max;

%put &vmax &cmax;

%if &edit ne %then %do;
data edit;
  set test;
  array vl(&vmax) $1 _temporary_;
  v=1;
  do until(v>length(var));
    vl(v)=substr(var,v,1);
    v=v+1;
  end;

  array cl(&cmax) $1 _temporary_;
  c=1;
  do until(c>length(col));
    cl(c)=substr(col,c,1);
    c=c+1;
  end;

  *edit distance;
  array m{%eval(&vmax+1),%eval(&cmax+1)} _temporary_;
  i=1;j=1;
  m{1,1}=0;
  do until(i>length(var));
    m(i+1,1)=i;
    i=i+1;
  end;
  do until(j>length(col));
    m(1,j+1)=j;
    j=j+1;
  end;

  p=2;q=2;
  do until(p>length(var)+1);
    do until(q>length(col)+1);
      if vl(p-1)=cl(q-1) then flag=0;
      else flag=1;
      m{p,q}=min(m{p-1,q}+1,m{p,q-1}+1,m{p-1,q-1}+flag);
      q=q+1;
    end;
    p=p+1;
    q=2;
  end;
  distant=m{length(var)+1,length(col)+1};
  similar=1-distant/max(length(var),length(col));
  *edit distance end;

/*  diff1=COMPGED(var,col);*/
/*  diff2=1-COMPLEV(var,col)/max(length(var),length(col));*/

  if &edit.<=similar<1;
  keep domain varname var col similar;
run;
%end;

%if &cos ne %then %do;
*cosine similarity;
data cos;
  set test;
  *Create a pool of non-repetitive words in two variables;
  comb=strip(var)||strip(col);
  array word(%eval(&vmax+&cmax)) $1 w1-w&max;
  w=1;
  y=1;
  i=1;
  rep=0;
  do until(y>length(comb));
    word(w)=substr(comb,y,1);
    if w>1 then do;
      do until(i=w);
        if word(w)=word(i) then rep=rep+1;
        i=i+1;
      end;
      i=1;
    end;
    if rep ne 0 then do;word(w)='';rep=0;end;
    else w=w+1;
    y=y+1;
  end;

  *Create a record of the number of letters that appear;
  j=1;
  k=1;
  array cv(%eval(&vmax+&cmax)) v1-v&max;
    do until(word(j)='' and word(j+1)='');
      cv(j)=0;
      do until(k>length(var));
        if word(j)=substr(var,k,1) then cv(j)=cv(j)+1;
        k=k+1;
      end;
      k=1;
      j=j+1;
    end;

  u=1;
  l=1;
  array cc(%eval(&vmax+&cmax)) c1-c&max;
    do until(word(u)='' and word(u+1)='');
      cc(u)=0;
      do until(l>length(col));
        if word(u)=substr(col,l,1) then cc(u)=cc(u)+1;
        l=l+1;
      end;
      l=1;
      u=u+1;
    end;

  *calculate cos;
  cosf=0;cosz1=0;cosz2=0;
  a=1;
  do until(cc(a)=.);
    cosf=cosf+cc(a)*cv(a);
    cosz1=cosz1+cc(a)*cc(a);
    cosz2=cosz2+cv(a)*cv(a);
    a=a+1;
  end;
  cos=round(cosf/(sqrt(cosz1)*sqrt(cosz2)),0.00000001);
  if &cos.<=cos<1;
  keep domain varname col var cos;
 run;
*cosine similarity end;
%end;

proc datasets lib=work noprint;
  save test edit cos/ memtype=data;
run;
quit;
%mend check;

%check;
