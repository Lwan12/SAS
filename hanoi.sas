%macro hanoi(
     n=                /*specifies the number of disks*/
    ,s_per_step=       /*specifies the time per step uses, unit: second*/
    );

    data _null_;
       *** Set length for variables;
           length %do i=1 %to &n; 
                     _1_&i _2_&i _3_&i  
              %end; _temp _dash _null $%eval(2*&n+4)
              _plate $%eval(6*&n+16) 
              message suminfo $100;

           *** initialize variables;
           array _tmp (%eval(3*&n)) _1_1--_3_&n;

           do i=1 to %eval(3*&n);
          _tmp(i)="|"||repeat(" ",(2*&n+1))||"|";
           end;

       ******************
           Defines the Window
           ******************;
       window hanoi color=red rows=(23+&n) columns=(46+6*&n)
                  #5   @(16+3*&n) "Tower of Hanoi" color=yellow protect=yes

                  #8   @15 _dash color=yellow protect=yes
                       @(21+2*&n) _dash color=yellow protect=yes
                           @(27+4*&n) _dash color=yellow protect=yes

                  #9   @15 _null color=yellow protect=yes
                       @(21+2*&n) _null color=yellow protect=yes
                           @(27+4*&n) _null color=yellow protect=yes

              %do i=&n %to 1 %by -1;
            #(9+&i) @15   _1_&i. color=yellow  protect=yes
                                @(21+2*&n) _2_&i color=yellow protect=yes
                                @(27+4*&n) _3_&i color=yellow protect=yes
                               
                  %end;

                  #(10+&n)  @15 _dash color=yellow protect=yes
                            @(21+2*&n) _dash color=yellow protect=yes
                                    @(27+4*&n) _dash color=yellow protect=yes

          #(11+&n)  @15 _plate color=cyan protect=yes

          #(13+&n)  @15 suminfo color=cyan  protect=yes

          #(14+&n)  @15 message color=cyan  protect=yes
           ;

           **********************************************
           A macro for each of the steps to do the moving
           **********************************************;
           %macro step(N,From,Mid,To);
                   %if &n=1 %then %do;
                                nth+1;
                                        _temp= _&to._&&lastmiss&to;
                                _&to._&&lastmiss&to=_&from._%eval(&&lastmiss&from+1);
                                        %let lastmiss&to=%eval(&&lastmiss&to-1);
                                        _&from._%eval(&&lastmiss&from+1)=_temp;
                                        %let lastmiss&from=%eval(&&lastmiss&from+1);

                                *** display the window to show the latest move;
                                display hanoi noinput;
                                link pause ;
                   %end;
                   %else %do;
                      %step(%eval(&n-1),&from,&to,&mid);

                                nth+1;
                                        _temp= _&to._&&lastmiss&to;
                                _&to._&&lastmiss&to=_&from._%eval(&&lastmiss&from+1);
                                        %let lastmiss&to=%eval(&&lastmiss&to-1);
                                        _&from._%eval(&&lastmiss&from+1)=_temp;
                                        %let lastmiss&from=%eval(&&lastmiss&from+1);

                                          *** display the window;
                                display hanoi noinput;
                                link pause ;

                      %step(%eval(&n-1),&mid,&from,&to);
                   %end;
           %mend;      

           ***************************
           Prepare the initial figure.
           ***************************;
           _plate=repeat("_",%eval(6*&n)+16);
           _dash=repeat("-",%eval(2*&n)+3);
           _null="|"||repeat(" ",%eval(2*&n+1))||"|";

           %do i=1 %to &n;
               _1_&i.="|"||repeat(" ",%eval(&n-&i)) ||repeat("**",%eval(&i-1))||repeat(" ",%eval(&n-&i)) ||"|";
           %end;

           message="Press ENTER to start.";
                   
           *** Display the window and ask the user to press ENTER;
           display hanoi blank;


           *********************************
           Display every step of the process
           *********************************;
           call missing(message,suminfo);
           *** get the time when starts;
           timest=time();
           suminfo="Moving... Please wait...";

           *** Initial value for some macro variables.
               means the first rod is full and the other two are empty;
           %let lastmiss1=0;
           %let lastmiss2=&n;
           %let lastmiss3=&n;

           *** Move it;
           %step(&n,1,2,3)

           *** Get the time when it finishs;
           timeen=time();

           *** Prepare the summarize information;
           totaltime=timeen-timest;

           suminfo=cat("Done! Steps:"
                       ,strip(put(nth,best.))
                       ,"  Time:"
                       ,strip(put(totaltime,8.1))
                       ," seconds.");

           message="Press ENTER to close.";

           *** display the final status;
           display hanoi blank;

           *** Stop the execution;
           stop;

           *** Used to control how fast it moves;
           pause:
                 now=time() ;
                 do while((now+&s_per_step)>time()) ;
                 end ;

    run;
%mend;

options mprint;
%hanoi(n=3,s_per_step=0.3)
