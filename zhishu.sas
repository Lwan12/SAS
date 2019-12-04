data test;
  do num=1 to 999;
  output;
  end;
run;

data end;
  set test;
  n=0;
  do i=2 to num;
    if num/i=int(num/i) then n+1;
  end;
  if n=1 then output;
run;

data end;
  set test;
  n=0;
  do i=2 to num;
    if mod(num,i)=0 then n+1;
  end;
  if n=1 then output;
run;

