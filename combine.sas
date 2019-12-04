/*******************************************************************************
Program/Macro: combine.sas
Lang/Vers:     SAS V9.4
Description:   Combines multiple RTF output into one single RTF file with
               hyper-linked Table of Contents (TOC)
Author:        Lee Wan
Date:          May, 2019
Output:        An RTF file that starts with TOC.
Parameters:    indir:      req - full path to the directory of RTF files
               indata      opt - title name data (keep=tfl title)
               orderinfmt: opt - informat for ordering the RTF files
               toctitle:   opt - title for the Table of Contents
               select:     opt - user-selection of RTF files to be combined.
                                 Wild char (*, ?) selection is supported.
                                 If blank, then all RTF files are selected.
               lrecl:      opt - maximal line size (logical record length)
               file:       opt - fullpath to the output RTF file
               tocyn       opt - Y or N indicating if a TOC is desired on the first page, default is Y
Sample Call:
  --- Sample 1. Combine RTF files with assigned order. ---
    proc format;
    invalue orderinfmt(upcase just)
            'TSIEXP12A'-'TSIEXP18A'=1
            other=9999999;

  %combine( indir=XXXX\XXXX\XXXX\Output,
            orderinfmt=orderinfmt.,
            toctitle=ET743-SAR-3002i2,
            select=t* );

  --- Sample 2. Combine RTF files  ---
  %let OPATH = XXXX\XXXX\Output;
  %combine( indir=&opath.,lrecl=2000,select=T* L* G*);
Modification History:
Rev #      Modified By      Reporting Effort               Date      Description
*******************************************************************************/

%macro combine(indir=,
               indata=,
               orderinfmt=,
               toctitle=Table of Contents,
               select=T* L* F*,
               lrecl=1400,
               file=&opath\all.rtf, 
               tocyn=y,
               xwin=1); %* XWIN is for internal use only;
%if &sysscpl ^= Linux %then %do;
  %if %length(&indir) > 1 %then %do;
    %if %substr(&indir,%length(&indir),1) = \ %then
      %let indir = %substr(&indir, 1, %length(&indir)-1);
  %end;
%end;
  %if ^%sysfunc(fileexist(&indir)) %then %do;
    %put ERROR: Could not access the imput directory;
    %return;
  %end;

  %if %sysfunc(fileexist(&file)) %then
    %if &xwin %then x "del /f ""&file"""; %else %fdelete(&file);;

  %* Browse for RTF file list;
  %local i nwords word nRTF titletag taglen tocfile;  
  %do i=1 %to %sysfunc(countc(&select, %str( )))+1;
    %local sel&i;
  %end;

  %* Split the selection criteria;
  %let i = 1;
  %if %superq(select)= %then %let select = *.rtf;
  %let word = %qscan(&select, &i, %str( ));
  %do %while (&word ne);
      %if %index(&word,.) = 0 %then %let word = &word..rtf;
      %let sel&i = %trim(&word);
      %let i = %eval(&i + 1);
      %let word = %qscan(&select, &i, %str( ));
  %end;
  %let nwords = %eval(&i-1);

  %* Pick up RTF files;
  %do i=1 %to &nwords;
    %if &sysscpl ^= Linux %then %do;
    filename fin pipe "dir /a-d /on &indir\&&sel&i";
  %end;
    %else %do;
    filename fin pipe "dir /a-d /on &indir/&&sel&i";
  %end;
    data RTF_&i(where=(line^='' and line^=:'Volume' and line^=:'Directory of'));
      infile fin truncover;
      input line $260.;
      if find(line, 'Dir(s)') = 0 and find(line, 'File(s)') = 0;
    run; %* needed for libname fin to work;
  %end;

  data combine_;
    set %do i=1 %to &nwords; RTF_&i %end; nobs=count;
    length FILEID $40;
    if _n_=1 then call symputx('nRTF', count);  
    fileid = scan(line,-2);  
  %if &orderinfmt^= %then %do;
    order = input(fileid, &orderinfmt);
  proc sort data=combine_;
    by order;
  %end;      
  run;

  %if &nRTF= or &nRTF=0 %then %do;
    %put WARNING: 0 RTF is selected from &indir.;
    %return;
  %end;

  %do i=1 %to &nRTF;
    %local fileid&i title&i titname&i;
  %end;
  %if &indata ne %then %do;
    proc sql noprint;
      create table combine_title as
      select a.*,b.title
      from combine_ as a
      left join &indata as b
      on a.fileid=b.tfl;
    quit;

    data combine_;
      set combine_title;
    run;
  %end;
  data _null_;
    set combine_;
    call symputx(cats('fileid',_n_), fileid);
    %if &indata ne %then %do;
    call symputx(cats('titname',_n_), title);
    %end;

  %* Load RTF file into dataset;
  %local _lrecl _errflag;
  %let _lrecl = %eval(&lrecl + 100);
  %let _errflag = 0;
  %do i=1 %to &nRTF;
    data combine_&i;
    %if &sysscpl ^= Linux %then %do;
      infile "&indir\&&fileid&i...rtf" lrecl=&_lrecl length=linelen;
  %end;
    %else %do;
      infile "&indir/&&fileid&i...rtf" lrecl=&_lrecl length=linelen;
  %end;
      length line $&_lrecl;
      input line $varying&_lrecl.. linelen;
      if length(line) > &lrecl then call symput('_errflag', '1');
    run;
    %if &_errflag %then %do;
      %put ERROR: Line size exceeds the input value LRECL=&LRECL..
Use %nrstr(%MaxLineSize) to find out the maximal line size in input RTF files.;
      %return;
    %end;
  %end;

  %let titletag = \fi-1152\li1152\RTF\s15;
  %let taglen = %length(&titletag);
  %do i=1 %to &nRTF;
    data combine_a&i(keep=line);
      set combine_&i end=eof;
      %* Add section break, cut off the opening brace, add bookmark for non-RM RTF tables;
        if _n_=1 then line = "\sect{\*\bkmkstart &&fileid&i}{\*\bkmkend &&fileid&i}" || substr(line, 2);
      %* Cut off the ending braces;      
      %if &i < &nRTF %then %do;
        if eof then do;
          if line = '}' then stop;
          line = substr(line, 1, length(line)-1);
        end;
      %end;

      %* Add bookmark;
      line = tranwrd(line, '{\*\bkmkstart IDX}', "{\*\bkmkstart &&fileid&i}");
      line = tranwrd(line, '{\*\bkmkend IDX}', "{\*\bkmkend &&fileid&i}");
      %* Add hyperlink. Parse for titles.;
      k = find(line, "&titletag");
      if k > 0 then do;
        %* Find the end of the title;
        n = find(line,"(Study");
        if n = 0 then n = find(line,"(",-1000);
        if n = 0 then n = find(line,'\RTF \cell}');
        if n = 0 then n = find(line,'\RTF\brdrb\brdrs \cell}');
        if n > 0 then n = n - k - &taglen;
        if n > 0 then x = substr(line, k+&taglen, n); else x = substr(line, k+&taglen);
        x = "{é\fldrslt {é\ulé\cf2 &&fileid&i &&titname&i}}}: "||scan(tranwrd(x,'\tab ','|'),2,'|');
        x = "{é\field{é\*é\fldinst {HYPERLINK é\é\l ""&&fileid&i""}}" || x;
        call symputx("title&i", x);
      end;
    run;    
    %if %superq(title&i)= %then %* Failed to locate the output title;
      %let title&i =
        {é\field{é\*é\fldinst {HYPERLINK é\é\l "&&fileid&i"}}{é\fldrslt {é\ulé\cf2 &&fileid&i &&titname&i}}};
  run;
  /* new datastep added for use if no TOC is requested*/
  data combine_b&i(keep=line);
      set combine_&i end=eof;

      line = tranwrd(tranwrd(line,'\}','}'), '\{', '{');
      %if &i > 1 %then %do;
      if _n_=1 then line = "\sect" || substr(line, 2);
    %end;
      %* Cut off the ending braces;      
      %if &i < &nRTF %then %do;

        if eof then do;
          if line = '}' then stop;
          line = substr(line, 1, length(line)-1);
        end;
      %end;
    

  %end;
  run;

  %* Table of Contents;
  data toc;
    length line $&lrecl;
    label line = "&toctitle";
    %do i=1 %to &nRTF;
      line = symget("title&i"); output;
    %end;
  run;
  
  %* Generate RTF output for Table of Contents (TOC);

  %let tocfile = %sysfunc(pathname(work))\toc.rtf;
  title;
  options nonumber nodate orientation=portrait;
  ods listing close;
  ods rtf file = "&tocfile";
  ods escapechar="é";
  proc report data = toc nowd;
    column line;
  run;
  ods rtf close;
  ods listing;
 
  %* Load RTF TOC into dataset;
  data combine_0;
    infile "&tocfile" lrecl=&lrecl length=linelen;
    length line $&_lrecl;
    input line $varying&_lrecl.. linelen;
  run;
  
  %* Remove extra \ and cut off the ending };
  data combine_a0(keep=line);
    set combine_0 end=eof;
    line = tranwrd(tranwrd(line,'\}','}'), '\{', '{');
    if eof then line = substr(line, 1, length(line)-1);
  run;
  %* Combine RTFs;
  data _all;
    * if TOC is desired append TOC and files with hyperlinks/bookmarks, otherwise just bring in files ;
    %if %upcase(&tocyn) eq Y %then %do ;
    set %do i=0 %to &nRTF; combine_a&i %end;;
      %end;
  %else 
  %if %upcase(&tocyn) eq N %then %do ;
    set %do i=1 %to &nRTF; combine_b&i %end;;
      %end;

  %* Dump data (in RTF) to text file;
  data _null_;
    set _all;
    file "&file" lrecl=&lrecl;
    if line='' then put;
    else do;
      n = length(line) - length(left(line)) + 1;
      put @n line;
    end;
  run;
  %if &xwin %then x "attrib +r &file"; %else %SetReadOnly(&file);;

  %* Cleanup;
  data _null_;
    length dd $8;
    rc = filename(dd, "&tocfile");
    rc = fdelete(dd);
  proc datasets nolist;
    delete RTF_: toc _all combine_: / memtype=data;
  run;
  quit;

%mend combine;

