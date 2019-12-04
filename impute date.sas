data t;
format b date9.;
a = '2013-05';
b = intnx('month',input(a, anydtdte.),0,'e');
run;

impute last day on month.