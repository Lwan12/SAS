
%let outdir = \\mst13\MST_Standards\SA\Global_Library\DM_Standard_Template\Metadata;

data filelist;                                                                                                               
   length nlst nfile nnext $100;                                                                                                                     
   rc=filename('dir',"&outdir.");                                                                                                                     
   dirid=dopen('dir');       
   numsel=dnum(dirid);                                                                                                                               
                                                                                                                                      
   do i=1 to numsel;                                                                                                                                 
     nlst=dread(dirid,i);                                                                                                                            
     nfile=scan(nlst, 1, '.');                                                                                                                       
     nnext=upcase(scan(nlst, 2, '.'));                                                                                                               
     if indexw("XLSX", upcase(nnext)) then output;                                                                                                                                                                                                                                   
   end;                                                                                                                                                                                                                                                                                                 
   rc=dclose(dirid);                                                                                                                                 
run;  
