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
      ** SOURCE FILE NAME: dbupgrade.cbl 
      **
      ** SAMPLE: Demonstrates how to upgrade to a database
      **
      ** DB2 API USED:
      **         db2DatabaseUpgrade -- UPGRADE DATABASE
      **
      ***********************************************************************
      **
      ** For more information on the sample programs, see the README file. 
      **
      ** For information on developing COBOL applications, see the 
      ** Application Development Guide.
      **
      ** For information on DB2 APIs, see the Administrative API Reference.
      **
      ***********************************************************************

       Identification Division.
       Program-Id. "dbupgrade".

       Data Division.
       Working-Storage Section.

       copy "sqlenv.cbl".
       copy "sqlca.cbl".
       copy "db2ApiDf.cbl".

      * variables used for UPGRADE API
       01 database.
         49 database-length       pic s9(4) comp-5 value 0.
         49 database-name         pic x(9).

       01 usr.
         49 usrid-length   pic s9(4) comp-5 value 0.
         49 usrid-name     pic x(19).

       01 passwd.
         49 passwd-length   pic s9(4) comp-5 value 0.
         49 passwd-name     pic x(19).

       01 upgradeflag.
         49 upgrade-flags    pic s9(4) comp-5 value 0.

      * Local Variables

       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).

       Procedure Division.
       dbupgrade-pgm section.

           display "Sample COBOL Program : DBUPGRADE.CBL".

           display "Enter the name of the database : " with no advancing.
           accept database-name.
           inspect database-name tallying database-length for characters
              before initial " ".
           display " ".

           display "Enter in your user id : " with no advancing.
           accept usrid-name.

           inspect usrid-name tallying usrid-length for characters
              before initial " ".
           display " ".

           display "Enter in your password : " with no advancing.
           accept passwd-name.

           inspect passwd-name tallying passwd-length for characters
              before initial " ".
           display " ".


      **************************************
      * PREPARE DB2DATABASE-UPGRADE-STRUCT *
      **************************************

      * Prepare the DB2DATABASE-UPGRADE-STRUCT
           set DB2-PI-DB-ALIAS of DB2DATABASE-UPGRADE-STRUCT
              to address of database-name.
           set DB2-PI-USER-NAME of DB2DATABASE-UPGRADE-STRUCT
              to address of usrid-name.
           set DB2-PI-PASSWORD of DB2DATABASE-UPGRADE-STRUCT
              to address of passwd-name.
           move database-length to DB2-I-DB-ALIAS-LEN
              of DB2DATABASE-UPGRADE-STRUCT.
           move usrid-length to DB2-I-USER-NAME-LEN
              of DB2DATABASE-UPGRADE-STRUCT.
           move passwd-length to DB2-I-PASSWORD-LEN
              of DB2DATABASE-UPGRADE-STRUCT.   
           move upgrade-flags to DB2-UPGRADE-FLAGS
              of DB2DATABASE-UPGRADE-STRUCT.   

      *********************************
      * UPGRADE DATABASE API called   *
      *********************************
           call "db2DatabaseUpgrade" using
                             by value     db2Version820
                             by reference DB2DATABASE-UPGRADE-STRUCT
                             by reference sqlca
                           returning rc.
           if sqlcode equal SQLE-RC-MIG-OK
              go to dbupgrade-complete.
           move "UPGRADE DATABASE" to errloc.
           call "checkerr" using SQLCA errloc.

       dbupgrade-complete.
           display "Database Upgrade completed successfully".

       end-dbupgrade. stop run.

