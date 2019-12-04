*COMPGED;
data a;
  length var1 var2 $200;
  var1='coffe';var2='cafe';
run;

DATA B;
  set a;
  i=COMPGED(var1,var2);
run;
**********;

data a;
  length var $200;
  var='coffe';output;
  var='cafe';output;
run;

proc sql noprint;
  select max(length(strip(var))) into:max from a;
quit;

%let max=&max;

data c;
  set a;
  array col(*) $1 var1-var&max;
  i=1;
  do until(i>length(var));
    col(i)=substr(var,i,1);
    i=i+1;
  end;
run;

**********;

data test;
  length var col $200;
  var='coffee';col='cafe';output;
  var='coff';col='coff';output;
  var='coffe';col='ice coffe';output;
  var='URINE WHITE BLOOD CELLS INCREASED';col='NEUTROPHIL COUNT DECREASED';output;
  var='coffee';col='juice';output;
  var='NEUTROPHIL COUNT DECREASED';col='PLATELET COUNT DECREASED';output;
  var='mayday ice';col='maayday ice';output;
  var='ADJUDICATION - VENOUS / PULMONARY ARTERY THROMBOEMBOLIC EVENT_VTE';col='ADJUDICATION - VENOUS OR PULMONARY ARTERY THROMBOEMBOLIC EVENT_VTE';output;
run;

proc sql noprint;
  select max(length(strip(var))) into:vmax from test;
  select max(length(strip(col))) into:cmax from test;
quit;

%put &vmax &cmax;

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

  diff1=COMPGED(var,col);
  diff2=1-COMPLEV(var,col)/max(length(var),length(col));
  drop i j c v q p;
run;
  

*cosine similarity;
data cos;
  set test;
  *Create a pool of non-repetitive words in two variables;
  comb=strip(var)||strip(col);
  array word(%eval(&vmax+&cmax)) $1 _temporary_;
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
  array cv(%eval(&vmax+&cmax)) _temporary_;
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
  array cc(%eval(&vmax+&cmax)) _temporary_;
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
  cos=cosf/(sqrt(cosz1)*sqrt(cosz2));

  keep var col cos;
 run;
*cosine similarity end;
      

