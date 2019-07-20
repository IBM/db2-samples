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
      ** SOURCE FILE NAME: dbsnap.cbl 
      **
      ** SAMPLE: Get a database monitor snapshot
      **
      ** DB2 APIs USED:
      **         sqlgmnsz -- ESTIMATE BUFFER SIZE  
      **         sqlgmnss -- DATABASE MONITOR SNAPSHOT
      **
      ** OUTPUT FILE: dbsnap.out (available in the online documentation)
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
       Program-Id. "dbsnap".

       Data Division.
       Working-Storage Section.

       copy "sqlca.cbl".
       copy "sqlmonct.cbl".
       copy "sqlmon.cbl".

      * Variables for catalog/uncatalog nodes

      * Local Variables
       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).

       77 rezerv1             pic 9(9) comp-5 value 0.
       77 rezerv2             pic 9(9) comp-5 value 0.
       77 current-version     pic 9(9) comp-5 value 0.

      * DATABASE SYSTEM MONITOR SNAPSHOT
       01 database.
         05 database-length   pic s9(4) comp-5.
         05 database-name     pic x(80).

       01 buff.
         05 buffer-sz         pic 9(9) comp-5 value 0.
         05 buffer            occurs 0 to 100000 times
                              depending on buffer-sz.
           10 element         pic x.

       Procedure Division.
       snap-pgm section.

           display "Sample COBOL Program : DBSNAP.CBL".

      * get database to perform snapshot on

           display "Take a snapshot of database activity".

           display "Enter the name of the database : " with no advancing.
           accept database-name.
           inspect database-name tallying database-length for characters
              before initial " ".
           inspect database-name replacing first " " by X'00'. 
           display " ".

           perform db-snap thru end-db-snap.

       end-snap. stop run.

       db-snap Section.
      ******************************************************
      * perform a snapshot of lock activity for a database *
      ******************************************************

      * request SQLMA-DBASE, and SQLMA-DBASE-LOCKS in the sqlma

           move 2 to OBJ-NUM of SQLMA.
           move SQLMA-DBASE to OBJ-TYPE(1).
           move database-name to SQLMA-OBJECT(1).
           move SQLMA-DBASE-LOCKS to OBJ-TYPE(2).
           move database-name to SQLMA-OBJECT(2).

           move SQLM-CURRENT-VERSION to current-version.

           display "estimate buffer size".
      * estimate buffer size do I need this??
           call "sqlgmnsz" using
                                 by value     rezerv1
                                 by reference sqlca
                                 by reference buffer-sz
                                 by reference SQLMA
                                 by reference rezerv2
                                 by value     current-version
                           returning rc.
           move "estimate buffer size" to errloc.
           call "checkerr" using SQLCA errloc.

           display "take a snapshot".

      ***********************
      * SNAPSHOT API called *
      ***********************
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
           move "SNAPSHOT" to errloc.
           call "checkerr" using SQLCA errloc.

       end-db-snap. exit.
