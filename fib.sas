%macro fib(i);
  %if &i=1 %then %do;1%end;
  %if &i=2 %then %do;1%end;
  %if &i>2 %then %do;%fib(%eval(&i-1))+%fib(%eval(&i-2))%end;
%mend;

%put %fib(7);

data fib;
  fib=%fib(7);
run;


%macro fib2(n);
data fib2;
  col1=1;
  col2=1;
  array col(&n) col1-col&n;
  do i=3 to &n;
  col(i)=col(i-2)+col(i-1);
  end;
  keep col&n;
run;
%mend;
%fib2(7);

