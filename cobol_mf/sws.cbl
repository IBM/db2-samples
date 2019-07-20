      ***********************************************************************
      ** (c) Copyright IBM Corp. 2007 All rights reserved.
      ** 
      ** The following sample of source code ("Sample") is owned by International 
      ** Business Machines Corporation or one of its subsidiaries ("IBM") and is 
      ** copyrighted and licensed, not sold. You may use, copy, modify, and 
      ** distribute the Sample in any form without payment to IBM, for the purpose of 
      ** assisting you in the development of your applications.
      ** 
      ** The Sample code is provided to you on an "AS IS" basis, without warranty of 
      ** any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
      ** IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
      ** MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
      ** not allow for the exclusion or limitation of implied warranties, so the above 
      ** limitations or exclusions may not apply to you. IBM shall not be liable for 
      ** any damages you suffer as a result of using, copying, modifying or 
      ** distributing the Sample, even if IBM has been advised of the possibility of 
      ** such damages.
      ***********************************************************************
      **
      ** SOURCE FILE NAME: sws.cbl 
      **
      ** SAMPLE: How to use a database monitor switch
      **
      ** DB2 API USED:
      **         db2gMonitorSwitches -- DATABASE MONITOR SWITCH
      **
      ** OUTPUT FILE: sws.out (available in the online documentation)
      ***********************************************************************
      **
      ** For more information on the sample programs, see the README file. 
      **
      ** For information on developing COBOL applications, see the 
      ** Application Development Guide.
      **
      ** For information on DB2 APIs, see the Administrative API Reference.
      **
      ** For the latest information on programming, compiling, and running
      ** DB2 applications, visit the DB2 application development website: 
      **     http://www.software.ibm.com/data/db2/udb/ad
      ***********************************************************************

       Identification Division.
       Program-Id. "sws".

       Data Division.
       Working-Storage Section.

       copy "sqlutil.cbl".
       copy "sqlca.cbl".
       copy "sqlmonct.cbl".
       copy "sqlmon.cbl".
       copy "db2ApiDf.cbl".

      * Local Variables
       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).
       77 output-data-buffer  pic x(4096) value " ".
       77 my-output-format pic s9(9) comp-5.

       Procedure Division.
       sws-pgm section.

           display "Sample COBOL Program : SWS.CBL".

      * Initialize input variables

      *    To get a STATIC output stream, we need to specify pre-v7,
      *     else the returned datastream will be DYNAMIC

           move SQLM-DBMON-VERSION6 to DB2-I-VERSION of 
                DB2G-MONITOR-SWITCHES-DATA. 

           move 4096 to DB2-I-BUFFER-SIZE of 
                DB2G-MONITOR-SWITCHES-DATA.

           move SQLM-CURRENT-NODE to DB2-I-NODE-NUMBER of
                DB2G-MONITOR-SWITCHES-DATA.

           move 1 to DB2-I-RETURN-DATA of 
                DB2G-MONITOR-SWITCHES-DATA.

           set DB2-PI-GROUP-STATES of DB2G-MONITOR-SWITCHES-DATA
                to address of SQLM-RECORDING-GROUP.

           set DB2-PO-OUTPUT-FORMAT of DB2G-MONITOR-SWITCHES-DATA
                to address of my-output-format.

           set DB2-PO-BUFFER of DB2G-MONITOR-SWITCHES-DATA
                to address of output-data-buffer.

      * Table switch ON, UOW switch OFF, others default

           move SQLM-OFF  to INPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-UOW-SW). 

           move SQLM-ON   to INPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-TABLE-SW). 

           move SQLM-HOLD to INPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-STATEMENT-SW). 

           move SQLM-HOLD to INPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-BUFFER-POOL-SW). 

           move SQLM-HOLD to INPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-LOCK-SW). 

           move SQLM-HOLD to INPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-SORT-SW).

      * Since we're requesing V6 data, this is commented out
      *  (the TIMESTAMP switch did not exist in V6).
      *
      * Un-comment this only if V7 or V8 data was requested,
      *  in which case the resulting datastream will be DYNAMIC,
      *  and will need to be parsed (not demonstrated in this program).
      *
      *     move SQLM-HOLD to INPUT-STATE of 
      *          SQLM-RECORDING-GROUP(SQLM-TIMESTAMP-SW).
               
      **************************************
      * DATABASE MONITOR SWITCH API called *
      **************************************

           call "db2gMonitorSwitches" using
                                by value db2Version810
                                by reference DB2G-MONITOR-SWITCHES-DATA
                                by reference SQLCA
                           returning rc.

           move "MONITOR SWITCH" to errloc.
           call "checkerr" using SQLCA errloc.
      
           display " ".
           display "Print Switch Values".
           display " ".
           perform print-sws.
      
           display " ".
           display "Print their switch set time (if on)".
           display " ".
           perform print-sws-set-times.

       end-sws. stop run.

       print-sws Section.
      ***********************
      * print switch values *
      ***********************

           display "SQLM-UOW-SW       : " , OUTPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-UOW-SW).

           display "SQLM-STATEMENT-SW : " , OUTPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-STATEMENT-SW).

           display "SQLM-TABLE-SW     : " , OUTPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-TABLE-SW).

           display "SQLM-BUFFER-SW    : " , OUTPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-BUFFER-POOL-SW).

           display "SQLM-LOCK-SW      : " , OUTPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-LOCK-SW).

           display "SQLM-SORT-SW      : " , OUTPUT-STATE of 
                SQLM-RECORDING-GROUP(SQLM-SORT-SW).

      * Since we're requesing V6 data, this is commented out
      *  (the TIMESTAMP switch did not exist in V6).
      *
      * Un-comment this only if V7 or V8 data was requested,
      *  in which case the resulting datastream will be DYNAMIC,
      *  and will need to be parsed (not demonstrated in this program).
      *
      *     display "SQLM-TIMESTAMP-SW : " , OUTPUT-STATE of 
      *          SQLM-RECORDING-GROUP(SQLM-TIMESTAMP-SW).

       end-print-sws. exit.

       print-sws-set-times Section.
      ********************************
      * print switch set times if on *
      ********************************

           if SECONDS of START-TIME of 
              SQLM-RECORDING-GROUP(SQLM-UOW-SW) 
              not equal 0 then
           display "SQLM-UOW-SW start-time         : " , SECONDS of 
              START-TIME of SQLM-RECORDING-GROUP(SQLM-UOW-SW). 

           if SECONDS of START-TIME 
              of SQLM-RECORDING-GROUP(SQLM-STATEMENT-SW) 
              not equal 0 then
           display "SQLM-STATEMENT-SW start-time   : " , SECONDS of 
              START-TIME of SQLM-RECORDING-GROUP(SQLM-STATEMENT-SW). 

           if SECONDS of START-TIME 
              of SQLM-RECORDING-GROUP(SQLM-TABLE-SW) 
              not equal 0 then
           display "SQLM-TABLE-SW start-time       : " , SECONDS of 
              START-TIME of SQLM-RECORDING-GROUP(SQLM-TABLE-SW). 

           if SECONDS of START-TIME of
              SQLM-RECORDING-GROUP(SQLM-BUFFER-POOL-SW) 
              not equal 0 then
           display "SQLM-BUFFER-POOL-SW start-time : " , SECONDS of 
              START-TIME of SQLM-RECORDING-GROUP(SQLM-BUFFER-POOL-SW). 

           if SECONDS of START-TIME of 
              SQLM-RECORDING-GROUP(SQLM-LOCK-SW) 
              not equal 0 then
           display "SQLM-LOCK-SW start-time        : " , SECONDS of 
              START-TIME of SQLM-RECORDING-GROUP(SQLM-LOCK-SW). 

           if SECONDS of START-TIME of 
              SQLM-RECORDING-GROUP(SQLM-SORT-SW) 
              not equal 0 then
           display "SQLM-SORT-SW start-time        : " , SECONDS of 
              START-TIME of SQLM-RECORDING-GROUP(SQLM-SORT-SW). 

      * Since we're requesing V6 data, this is commented out
      *  (the TIMESTAMP switch did not exist in V6).
      *
      * Un-comment this only if V7 or V8 data was requested,
      *  in which case the resulting datastream will be DYNAMIC,
      *  and will need to be parsed (not demonstrated in this program).
      *
      *     if SECONDS of START-TIME of 
      *        SQLM-RECORDING-GROUP(SQLM-TIMESTAMP-SW) 
      *        not equal 0 then
      *     display "SQLM-TIMESTAMP-SW start-time   : " , SECONDS of 
      *        START-TIME of SQLM-RECORDING-GROUP(SQLM-TIMESTAMP-SW). 

       end-print-sws-set-times. exit.
