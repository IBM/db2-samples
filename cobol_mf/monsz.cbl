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
      ** SOURCE FILE NAME: monsz.cbl 
      **
      ** SAMPLE: How to get a database monitor snapshot
      **
      **         This program first requests for the buffer size that would
      **         required for issuing a snapshot for locks, tables, and 
      **         database level information.
      **
      **         This testcase will return SQL1611, no data was returned
      **         by Database System Monitor. Some activity must be done to
      **         generate data for the snapshot: connect to database, 
      **         manipulate data, etc
      **
      ** DB2 APIs USED:
      **         db2GetSnapshotSize -- ESTIMATE BUFFER SIZE
      **         sqlgmnss -- GET SNAPSHOT
      **
      ** OUTPUT FILE: monsz.out (available in the online documentation)
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
       Program-Id. "monsz".

       Data Division.
       Working-Storage Section.

       copy "sqlca.cbl".
       copy "sqlmon.cbl".
       copy "sqlmonct.cbl".
       copy "db2ApiDf.cbl".

      * Local Variables
       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).

       77 rezerv1             pic 9(9) comp-5 value 0.
       77 rezerv2             pic 9(9) comp-5 value 0.
       77 current-version     pic 9(9) comp-5 value 0.

      * variables for ESTIMATE DATABASE SYSTEM MONITOR BUFFER SIZE
      *  and for DATABASE SYSTEM MONITOR SNAPSHOT
       01 buff.
          05 buffer-sz        pic 9(9) comp-5 value 0.
          05 buffer           occurs 0 to 100000 times 
                              depending on buffer-sz.
             10 element       pic x.

       01 database-name.
         05 pic x(6) value "sample".
         05 pic x    value x"00".
 
       Procedure Division.
       monsz-pgm section.

           display "Sample COBOL Program : MONSZ.CBL".

      * Request SQLMA-DBASE, SQLM-DBASE-TABLES, and SQLMA-DBASE-LOCKS 
      * in sqlma

      * set the input to SQLMA structure to monitor 3 objects
           move 3 to OBJ-NUM of SQLMA.
           move SQLMA-DBASE to OBJ-TYPE of OBJ-VAR(1).
           move SQLMA-DBASE-LOCKS to OBJ-TYPE of OBJ-VAR(2).
           move SQLMA-DBASE-TABLES to OBJ-TYPE of OBJ-VAR(3).

      * monitor the sample database
           move database-name to SQLMA-OBJECT in OBJ-VAR(1).
           move database-name to SQLMA-OBJECT in OBJ-VAR(2).
           move database-name to SQLMA-OBJECT in OBJ-VAR(3).

           move SQLM-CURRENT-VERSION to current-version.

      ***********************************************************
      * ESTIMATE DATABASE SYSTEM MONITOR BUFFER SIZE API called *
      ***********************************************************

      * Prepare the DB2G-GET-SNAPSHOT-SIZE-DATA
           set DB2-PI-SQLMA-DATA of DB2G-GET-SNAPSHOT-SIZE-DATA
               to address of SQLMA.
           set DB2-PO-BUFFER-SIZE of DB2G-GET-SNAPSHOT-SIZE-DATA
               to address of buffer-sz.
           move SQLM-DBMON-VERSION8
               to DB2-I-VERSION of DB2G-GET-SNAPSHOT-SIZE-DATA.
           move SQLM-CURRENT-NODE
               to DB2-I-NODE-NUMBER of DB2G-GET-SNAPSHOT-SIZE-DATA.
           move SQLM-CLASS-DEFAULT
               to DB2-I-SNAPSHOT-CLASS of DB2G-GET-SNAPSHOT-SIZE-DATA.

      **********************************
      ** DB2GetSnapshotSize API called *
      **********************************

           call "db2GetSnapshotSize" using
                                by value     db2Version820
                                by reference DB2G-GET-SNAPSHOT-SIZE-DATA
                                by reference sqlca
                           returning rc.

           move "ESTIMATE BUFFER SIZE" to errloc.
           call "checkerr" using SQLCA errloc.

           display "Buffer size required for this snapshot is ", 
                    buffer-sz.

      ***********************************************
      * DATABASE SYSTEM MONITOR SNAPSHOT API called *
      ***********************************************
           call "sqlgmnss" using
                                 by value     rezerv1
                                 by reference sqlca
                                 by reference SQLM-COLLECTED
                                 by reference buffer(1)
                                 by value     buffer-sz
                                 by reference SQLMA
                                 by reference rezerv2
                                 by value     current-version
                           returning rc.

           move "TAKING SNAPSHOT" to errloc.
           call "checkerr" using SQLCA errloc.

       end-monsz. stop run.
