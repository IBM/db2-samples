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
      ** SOURCE FILE NAME: monreset.cbl
      **
      ** SAMPLE: How to reset database system monitor data areas
      **
      ** DB2 API USED:
      **         sqlgmrst -- RESET MONITOR
      **
      ** OUTPUT FILE: monreset.out (available in the online documentation)
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
       Program-Id. "monreset".

       Data Division.
       Working-Storage Section.

       copy "sqlutil.cbl".
       copy "sqlca.cbl".
       copy "sqlmonct.cbl".

      * Local Variables
       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).

      * variables for RESET DATABASE SYSTEM MONITOR DATA
       01 database.
         05 database-length   pic s9(4) comp-5 value 6.
         05 database-name     pic x(8) value "sample".

       Procedure Division.
       reset-pgm section.

           display "Sample COBOL Program : MONRESET.CBL".

           display "Reset Database Monitor Data for sample database".

      *******************************************************
      * RESET DATABASE SYSTEM MONITOR DATA AREAS API called *
      *******************************************************
           call "sqlgmrst" using
                                 by value   database-length
                                 by value   0
                                 by reference SQLCA
                                 by reference database-name
                                 by value   SQLM-OFF
                                 by value   0
                                 by value   SQLM-DBMON-VERSION2
                           returning rc.

           move "RESET DB MONITOR" to errloc.
           call "checkerr" using SQLCA errloc.

           display "Database Monitor Reset for sample was successful".
       end-reset. stop run.
