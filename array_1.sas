data test;
  array ori(10) $200 A1-A10;
  do i=1 to 5;
    if mod(i,3)=0 then ori(i)='i'||strip(put(i,best.));
    output;
  end;
  do i=1 to 10;
    if mod(i,7)=0 then ori(i)='i'||strip(put(i,best.));
    output;
  end;
  do i=5 to 10;
    if mod(i,5)=0 then ori(i)='i'||strip(put(i,best.));
    output;
  end;
  do i=8 to 10;
    if mod(i,2)=0 then ori(i)='i'||strip(put(i,best.));
    output;
  end;
  drop i ;
run;




data end;
set test;
  array ori(10) A1-A10;
  array chg(10) $200 B1-B10;
  m=0;
  do i=1 to 10;
  if ori(i) ne '' then do;m+1;chg(m)=ori(i);end;
  end; 
run;
