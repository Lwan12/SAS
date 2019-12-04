proc sort data=test out=word nodupkey;by domain varname col;run;

data clean;
  set word;
  where index(varname,'TESTCD')=0;
  col=tranwrd(tranwrd(tranwrd(tranwrd(compress(col,'()'),',',' '),';',' '),'.',' '),':',' ');
  space=count(strip(col),'');
  i=1;
  do until(i>space+1);
    word=scan(col,i,'');
    if compress(word,'1234567890/%\+-_=|[]{}><') ne word or lowcase(word) in ('and' 'or' 'to' 'of' 'with' 'for' 'not' 'an' 'in' 'no' 'the' '') then delete;
    else output;
    i=i+1;
  end;
run;

proc sort data=clean out=clean_word nodupkey;by word;run;


filename fileref url 'https://www.yourdictionary.com/search/results/?q=countff';
data a;
infile fileref  lrecl=10000  dlm='>' encoding='utf-8' firstobs=1;
length text $32767;
input text @@;
run;

data b;
  set a;
  where index(text,'abnormalityprone');
run;
