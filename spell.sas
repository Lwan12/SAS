proc sort data=test out=word(drop=var) nodupkey;where domain='AE';by domain varname col;run;

option NOXWAIT noxsync;

ods rtf file="D:\temp.rtf" style=JOURNAL;
PROC PRINT DATA=word LABEL;
RUN;
ods rtf close;


%LET RC=%SYSFUNC(SYSTEM(START WINWORD));

data _null_;
  x=sleep(5);
run;


FILENAME word DDE 'WINWORD|SYSTEM';

DATA _null_;
FILE word;
/*Below command will clear all initial error at the start up*/
PUT '[On Error Resume Next]';
/*below command will open the target document*/
PUT '[FILEOPEN.Name = "' "D:\temp.rtf" '"]';
/*Below command will execute the SPELLCHECK VBA code*/
PUT '[SPELLCHECK()]';

RUN;


