%let path =\\mst13\C_109_HEM_AND017\STAT\Original\Programs\tfl\Output\backup\20190830;

data ord;                                                                                                               
   length nlst nfile nnext $100;                                                                                                                     
   rc=filename('dir',"&path.");                                                                                                                     
   dirid=dopen('dir');       
   numsel=dnum(dirid);                                                                                                                                                                                                                                                                 
   do i=1 to numsel;                                                                                                                                 
     nlst=dread(dirid,i);                                                                                                                            
     nfile=scan(nlst, 1, '.');                                                                                                                       
     nnext=upcase(scan(nlst, 2, '.'));                                                                                                               
     if indexw("RTF", upcase(nnext)) and index(nfile,'t') and substr(reverse(strip(nfile)),1,1)='1' then output;                                                                                                                                                                                                                                   
   end;                                                                                                                                                                                                                                                                                                 
   rc=dclose(dirid);                                                                                                                                 
run; 

proc sql noprint;
  select distinct upcase(nlst) into:nlist separated by '|' from ord;
quit;
%put &nlist;


%macro readrtf(file=,batch=);
data readrtf_a;
infile "&file" missover length = l end = lastobs lrecl = 2000;
input string $varying2000. l;
rownum = _n_;

string=tranwrd(string, '{\field{\*\fldinst SYMBOL 179 \\f "Symbol" }}', '>=');
string=tranwrd(string, '{\super a} ' , '');

retain c1-c99 dropme indent;
length c1-c2 $200 c3-c99 $50;
if _n_ = 1 then dropme = 1;
array c{99} $;
if index(string, '\trowd') then do;
count = 0;
indent = 0;
do i=1 to dim(c);
c{i} = '';
end;
end;
if index(string, '{') and index(string, '\cell') then do;
count + 1;
prep = substr(string, 1, index(string, '\cell')-1);
prep = scan(prep, 2, '{');
c{count} = compress(prep, byte(13));
if count = 1 then do;
sst = substr(string, index(string, '\li') + 3);
if verify(sst, '-0123456789') > 1 then
indent=input(substr(sst, 1, verify(sst, '-0123456789') - 1), best.);
end;
if index(c{count}, '\li') then do;
c{count} = substr(c{count}, index(c{count}, '\li'));
c{count} = substr(c{count}, index(c{count}, ' ')+1);
end;
end;
if dropme = 4 then dropme = 0;
if index(string, '\sect') or
(index(compress(lowcase(string)), 'page') and
index( lowcase(string) , ' of ')) then dropme = 1;
else if index(string, '\trowd' ) and dropme = 1 then dropme = 2;
else if index(string, '\clbrdrb') and dropme = 2 then dropme = 3;
else if index(string, '\row' ) and dropme = 3 then dropme = 4;
if not dropme and index(string, '\row') then do;
allblank = 1;
do i=1 to dim(c);
if compress(c{i}, ' \') ne '' then allblank = 0;
end;
if not allblank then output;
end;
run;

proc transpose data=readrtf_a(drop=count) out=chk;
var c:;
by rownum;
run;
proc sql noprint;
select distinct _name_ into: dropper separated by ' '
from chk where _name_ not in (select _name_ from chk where col1 ne '');
select distinct count(distinct _name_) into: numvars
from chk where col1 ne '';
quit;

proc sort data=readrtf_a(drop=count &dropper) out=readrtf_b;
by indent;
run;
data readrtf_c(index=(rownum));
set readrtf_b;
by indent;
if first.indent then level + 1;
run;

data readrtf_d(drop=i num1 pct1 allblank);
set readrtf_c;
array c (&numvars) c:;
array num(&numvars) ;
array pct(&numvars) ;
do i=2 to dim(c);
if c(i) not in ('' '-') and
verify(compress(c(i)), '-0123456789.')=0 then num(i) = input(c(i), best.);
else if c(i) not in ('' '-') and
verify(compress(c(i)), '-0123456789.()')=0 then do;
num(i) = input(scan( c(i) , 1, '('), best.);
pct(i) = input(scan(compress(c(i), ')'), 2, '('), best.);
end;
end;
run;

data readrt_f_&batch._&i(keep =  c: rownum);
length segment level subitem rownum 8.;
retain segment 0 subitem;
set readrtf_d;
if level = 1 then segment + 1;
if level ne lag(level) then subitem = 0;
subitem + 1;
rownum = _n_;
run;
%mend;

%macro check;
%let i=1;
%do %until (%scan(&nlist,&i,'|') = );
%let rtf=%scan(&nlist,&i,'|');
%readrtf(file=%str(\\mst13\C_109_HEM_AND017\STAT\Original\Programs\tfl\Output\backup\20190830\&rtf),batch=old);
%readrtf(file=%str(\\mst13\C_109_HEM_AND017\STAT\Original\Programs\tfl\Output\&rtf),batch=new);


proc printto print="&vlstout.\ow_%scan(&nlist,&i,'|').txt" new;
run;

proc compare data=readrt_f_old_&i compare=readrt_f_new_&i criterion=0.00000001 listall;
run;

proc printto print=print;
run;

%let i=%eval(&i+1);

%end;
%mend;

%check;
