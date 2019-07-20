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
      ** SOURCE FILE NAME: dbmconf.cbl 
      **
      ** SAMPLE: How to get, update and reset database manager configuration
      **
      ** DB2 APIs USED:
      **         sqlgxsys -- GET DATABASE MANAGER CONFIGURATION
      **         sqlgusys -- UPDATE DATABASE MANAGER CONFIGURATION
      **         sqlgrsys -- RESET DATABASE MANAGER CONFIGURATION
      **         sqlgaddr -- GET ADDRESS
      **
      ** OUTPUT FILE: dbmconf.out (available in the online documentation)
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
       Program-Id. "dbmconf".

       Data Division.
       Working-Storage Section.
       copy "sqlutil.cbl".
       copy "sqlca.cbl".

      * Local Variables
       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).

       77 user-response       pic x.

       01 dbname              pic x(8) value "sample".
       01 dbname-len          pic s9(4) comp-5 value 6.

       01 max-agents          pic 9(9) comp-5.
       01 numbdb              pic s9(4) comp-5.
       01 svcename            pic x(14).
       01 tpname              pic x(64).

      * variables for GET/UPDATE/RESET database manager configuration
       01 listnumber          pic s9(4) comp-5 value 2.

       01 list-of-lengths.
          05 token-length occurs 2 times pic 9(9) comp-5.

       01 tokenlist.
          05 tokens occurs 2 times.
             10 token         pic 9(4) comp-5.
      

             $IF P64 SET
                 10 filler    pic x(6).
             $ELSE
                 10 filler    pic x(2).  
             $END
            10 tokenptr      usage is pointer.

       Procedure Division.
       dbmconf-pgm section.

           display "Sample COBOL Program : DBMCONF.CBL".

           move SQLF-KTN-MAXAGENTS  to token(1).
           move SQLF-KTN-NUMDB      to token(2).
           move "GET ADDRESS" to errloc.
      **************************
      * GET ADDRESS API called *
      **************************
           call "sqlgaddr" using by reference max-agents
                                 by reference tokenptr(1)
                           returning rc.

           call "sqlgaddr" using by reference numbdb
                                 by reference tokenptr(2)
                           returning rc.

           display "getting the default Database Manager Configuration".
      *************************************************
      * GET DATABASE MANAGER CONFIGURATION API called *
      *************************************************
           call "sqlgxsys" using by value     listnumber
                                 by reference tokenlist
                                 by reference sqlca
                           returning rc.
           move "get database manager config" to errloc.
           call "checkerr" using SQLCA errloc.

           display "listing the database configuration".
           perform print-info.

           display "*****************************".
           display "*** IMPORTANT INFORMATION ***".
           display "*****************************".
           display " ".
           display "In the following steps of this program, an UPDATE ".
           display "and a RESET database manager configuration API will".
           display "be called, changing the current database manager".
           display "configuration to be reset to the DEFAULT values".
           display " ".
           display "Do you wish to continue? (y/n) : " with no advancing.
           accept user-response.
           display "user-response : ", user-response.

           if user-response not equal to "y" and not equal to "Y"
           then stop run.

      * Altering values of the default Database Manager Configuration
           move 250 to max-agents.
           move 15   to numbdb.
      ***************************************************
      * UPDATE DATABSE MANAGER CONFIGURATION API called *
      ***************************************************
           call "sqlgusys" using by value     listnumber
                                 by reference list-of-lengths
                                 by reference tokenlist
                                 by reference sqlca
           move "updating the database manager config" to errloc.
           call "checkerr" using SQLCA errloc.

           display "listing the UPDATEd Database Manager Configuration".
      ***************************************************
      * GET DATABASE MANAGER CONFIGURATION API called *
      ***************************************************
           call "sqlgxsys" using by value     listnumber
                                 by reference tokenlist
                                 by reference sqlca
                           returning rc.
           move "get the database manager config" to errloc.
           call "checkerr" using SQLCA errloc.

           display "listing the database configuration".
           perform print-info.

           display "RESETing the Database Manager Configuration".
      ***************************************************
      * RESET DATABASE MANAGER CONFIGURATION API called *
      ***************************************************
           call "sqlgrsys" using by reference sqlca
                           returning rc.
           move "reset the database manager config" to errloc.
           call "checkerr" using SQLCA errloc.


           display "listing the RESETed Database Manager Configuration".
      ***************************************************
      * GET DATABASE MANAGER CONFIGURATION API called *
      ***************************************************
           call "sqlgxsys" using by value     listnumber
                                 by reference tokenlist
                                 by reference sqlca
                           returning rc.
           move "get the database manager config" to errloc.
           call "checkerr" using SQLCA errloc.

           display "listing the database configuration".
           perform print-info.

       end-dbmconf. stop run.

      * PRINT DATABASE MANAGER CONFIGURATION INFORMATION
       print-info Section.

           display "Max. number of Agents                  : ",
                    max-agents.
           display "Number of concurrent active DB allowed : ",
                    numbdb.

       end-print-info. exit.
