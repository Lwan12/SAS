%macro recursion(i);
  %if &i=1 %then %do;1;%end;
  %else %do;&i*%recursion(%eval(&i-1))%end;
%mend;

%let n=%eval(%recursion(5));
%put %recursion(11);
data test;
  a=%recursion(12);
run;
%let i=4;
%let n=%eval(&i*5*4);
%put &n;
