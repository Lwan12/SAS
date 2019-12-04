data test;
  length text $200;
  id=1;text='AD(FF=,DSE=12d,AC=)';output;
  id=2;text='(AF=,AB=,AD=)';output;
  id=3;text='AFD_F(AD=,AC=d,GDA=,FE3=)';output;
  id=4;text='XX(CC=)';output;
  id=5;text='FA(GE=ASD,XD=12d,EE=ADE)';output;
  id=6;text='(XEF=\*FAD*\,XAE=12d)';output;
run;


data end;
  length tiqu $200;
  set test;
  num=count(text,'=');
  do i=1 to num;
    if i=1 then do;
      tiqu=substr(text,find(text,'(')+1,find(text,'=')-find(text,'(')-1);e1=find(text,'=');s1=0;
      output;
    end;
    else do;
      tiqu=substr(text,find(text,',',s1+1)+1,find(text,'=',e1+1)-find(text,',',s1+1)-1);e1=find(text,'=',e1+1);s1=find(text,',',s1+1)+1; 
      output;
    end;
  end;
run;


data fin;
  set test;
  tt=substrn(text,index(text,'(')+1,index(text,')')-index(text,'(')-1);
  n=count(text,'=');
  do i=1 to n;
   nn=substrn(scan(tt,i,"="),index(scan(tt,i,"="),',')+1);output;
  end;
run; 
