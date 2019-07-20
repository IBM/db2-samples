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
      ** SOURCE FILE NAME: dbstop.cbl 
      **
      ** SAMPLE: How to stop a database manager
      **
      **         This program will stop further connect to the database
      **         and will force the current users off, and shut down the
      **         database manager.
      **
      ** DB2 APIs USED:
      **         sqlgfrce -- FORCE USERS
      **         sqlgpstp -- STOP DATABASE MANAGER
      **
      ** OUTPUT FILE: dbstop.out (available in the online documentation)
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
       Program-Id. "dbstop".

       Data Division.
       Working-Storage Section.

       copy "sqlenv.cbl".
       copy "sqlca.cbl".

      * Local Variables
       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).

      * Variables for the FORCE USERS APIs
       77 sync-mode           pic 9(4) comp-5.

      * the number of occurences is an application specific value
      * this example forces all users
       77 cbl-count           pic S9(9) comp-5.

       01 agentid-array.
          05 agentid occurs 100 times pic 9(9) comp-5.

       Procedure Division.
       dbstop-pgm section.

      * need to look at "DBMONI" for more information on sqlmonss to get
      * the agentidarray

           display "Sample COBOL Program : DBSTOP.CBL".

           display "Forcing Users off DB2".
           move SQL-ASYNCH to sync-mode.
           move SQL-ALL-USERS to cbl-count.

      **************************
      * FORCE USERS API called *
      **************************
           call "sqlgfrce" using
                                 by reference   sqlca
                                 by value       sync-mode
                                 by reference   agentid-array
                                 by value       cbl-count
                           returning rc.
           if sqlcode equal SQLE-RC-NOSTARTG
              display "No start datbase manager command was issued"
              go to end-dbstop.

           move "FORCE APPLICATION ALL" to errloc.
           call "checkerr" using SQLCA errloc.

           display "Stopping the Database Manager".

      * setup stop options structure SQLEDBSTOPOPT
           move 0                   to SQL-ISPROFILE of SQLEDBSTOPOPT.
           move " "                 to SQL-PROFILE of SQLEDBSTOPOPT.
           move 0                   to SQL-ISNODENUM of SQLEDBSTOPOPT.
           move 0                   to SQL-NODENUM of SQLEDBSTOPOPT.
           move SQLE-NONE           to SQL-OPTION of SQLEDBSTOPOPT.
           move SQLE-DROP           to SQL-CALLERAC of SQLEDBSTOPOPT.


      *********************************
      * STOP DATABASE MANAGER API called *
      *********************************
           call "sqlgpstp" using
                                 by reference   SQLEDBSTOPOPT 
                                 by reference   sqlca
                           returning rc.

           move "STOPPING DATABASE MANAGER" to errloc.
           call "checkerr" using SQLCA errloc.

       end-dbstop. stop run.
