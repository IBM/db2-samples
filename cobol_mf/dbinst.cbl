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
      ** SOURCE FILE NAME: dbinst.cbl 
      **
      ** SAMPLE: Attach to and detach from an instance
      **
      ** DB2 APIs USED:
      **         sqlgatin -- ATTACH TO INSTANCE
      **         sqlggins -- GET INSTANCE
      **         sqlgdtin -- DETACH FROM INSTANCE
      **
      ** OUTPUT FILE: dbinst.out (available in the online documentation)
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
       Program-Id. "dbinst".

       Data Division.
       Working-Storage Section.

       copy "sqlenv.cbl".
       copy "sqlca.cbl".

      * Variables for attach to, detach from, get instance

       01 inst.
          05 db2instc-len      pic s9(4) comp-5 value 0.
          05 db2instc          pic x(18).

       01 usr.
          05 usr-name-len     pic s9(4) comp-5 value 0.
          05 usr-name         pic x(18).

       01 pass.
          05 passwd-len        pic s9(4) comp-5 value 0.
          05 passwd            pic x(18).

      * Local Variables
       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).

       Procedure Division.
       dbinst-pgm section.

           display "Sample COBOL Program : DBINST.CBL".

      * Initialize local variables

           display "enter instance name : " with no advancing.
           accept db2instc.
           inspect db2instc tallying db2instc-len for characters
              before initial " ".

           display "enter user name : " with no advancing.
           accept usr-name.
           inspect usr-name tallying usr-name-len for characters
              before initial " ".

           move space to passwd.
           display "enter passwd name : " with no advancing.
           accept passwd.
           inspect passwd tallying passwd-len for characters
              before initial " ".
           display " ".

           display "ATTACH TO INSTANCE API called for instance : "
              , db2instc.

      **********************
      * ATTACH TO INSTANCE *
      **********************
           call "sqlgatin" using
                                 by value     passwd-len
                                 by value     usr-name-len
                                 by value     db2instc-len
                                 by reference sqlca
                                 by reference passwd
                                 by reference usr-name
                                 by reference db2instc
                           returning rc.

           move "attach to instance" to errloc.
           call "checkerr" using SQLCA errloc.

           display "GET INSTANCE API called".

      ****************
      * GET INSTANCE *
      ****************
           call "sqlggins" using
                                 by reference sqlca
                                 by reference db2instc
                           returning rc.

           move "get instance name" to errloc.
           call "checkerr" using SQLCA errloc.

           display "current instance = " , db2instc.

           display "DETACHed FROM INSTANCE API called ", db2instc.

      ************************
      * DETACH FROM INSTANCE *
      ************************
           call "sqlgdtin" using
                                 by reference sqlca
                           returning rc.

           move "detach from instance" to errloc.
           call "checkerr" using SQLCA errloc.

       end-dbinst. stop run.
