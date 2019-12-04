

%let shuju=SXF:(01)1872-8756|
Body shop P1|
Book B13 |
(05)9212-0098 FJS|
PD(05)9206-4571|
Shushuophone|
(12) 6753-5513|
None here|
FDS:PD(12)6434-4532;

%put %scan(&shuju,11,'|');


%macro re;
data a;
 length ff $200;

  %do i=1 %to 9;
    ff=strip(scan("&shuju",&i,'|'));
    output;
  %end;
run;
%mend;
%re;

*prxmatch;
data zhengze1;
  set a;
  id=prxmatch('/[A-Z]?\(\d\d\)\s?\d{4}-\d{4}/',ff);
  if id>0 then output;
run;

*prxparse;

data zhengze2;
  set a;
  par=prxparse('/92/');

  if prxmatch(par,ff)>0 then output;
run;

*prxsubstr call prxsubstr(prxparse,variable,start,length);;
data zhengze3;
  set a;
  par=prxparse('/P?D?\(\d\d\)\s?\d{4}-\d{4}/');
  call prxsubstr(par,ff,s1,l1);
  if l1>0 then
  ff1=substr(ff,s1,l1);
run;

*prxposn  CALL PRXPOSN(prxparse, 1, start, length);
data zhengze4;
  set a;
  par=prxparse('/P?D?\((\d\d)\)\s?(\d{4}-\d{4})/');
  call prxsubstr(par,ff,s1,l1);
  if l1>0 then do;
  ff1=substr(ff,s1,l1);
  call PRXPOSN(par, 1, start_1, length_1);
  id1=substr(ff, start_1, length_1);
  call PRXPOSN(par, 2, start_2, length_2);
  id2=substr(ff, start_2, length_2);
  end;
run;


