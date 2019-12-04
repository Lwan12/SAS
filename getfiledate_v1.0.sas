

%let myfilerf=\\Mst13\c_092_onc_cs1003_105;                                                                                                              
%macro test;  
  %global exit;
  %if %sysfunc(fileexist(&myfilerf)) %then %do;
  %let exit=1; 
  %end;                                                                                             
  %else                                                                                                                                 
  %put The external file &myfilerf does not exist.;                                                                                     
%mend test;                                                                                                                             
                                                                                                                                        
                                                                                                                     
%test;
%put &exit;
%let exit=0;

data exit;
  rc=fexist("&path");
run;

data _null_;
    call system("dir \\mst13\* /n > D:\inlist.txt");
run;

data file;                                                                                                               
   length nlst nfile nnext $100;                                                                                                                     
   rc=filename('dir',"&path");                                                                                                                     
   dirid=dopen('dir');       
   numsel=dnum(dirid);   
   do i=1 to numsel;                                                                                                                                 
     nlst=dread(dirid,i);                                                                                                                            
     nfile=scan(nlst, 1, '.');                                                                                                                       
     nnext=scan(nlst, 2, '.');  
     if nnext ne '' then do;path=strip(charval)||strip(nfile)||'.'||strip(nnext);output;end;                                                                                                                                                                                                                                
   end;                                                                                                                                                                                                                                                                                                 
   rc=dclose(dirid);    
run;  

data date;
  set file;
  rcs = filename("fileref", path);

  fid=fopen('fileref');
  moddate=input(scan(finfo(fid,'Last Modified'),1,':'),date9.);
  rc = fclose(fid);
  rcc = filename("fileref");
  format moddate yymmdd10.;
run;




%let path=\\mst13\G_049_ONC_MMY3011\;

Filename filelist pipe "dir /b /s &path*"; 

data file;                                        
 Infile filelist truncover;
 Input filename $2000.;
 if substr(filename,%length(&path)+1,1)='$' then delete;
run; 

data date;
  set path;
  rcs = filename("fileref", filename);

  fid=fopen('fileref');
  if fid=0 then delete;
  moddate=input(scan(finfo(fid,'Last Modified'),1,':'),date9.);
  rc = fclose(fid);
  rcc = filename("fileref");
  format moddate yymmdd10.;
run;
