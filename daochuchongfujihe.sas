proc sort data=finl out =_null_ nodupkey dupout =mutntran;
  where avalc='Yes';
  by usubjid;
run;

*????;
