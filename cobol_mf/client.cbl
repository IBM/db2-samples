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
      ** SOURCE FILE NAME: client.cbl
      **
      ** SAMPLE: How to set and query a client
      **
      ** DB2 APIs USED:
      **         sqlgsetc -- SET CLIENT
      **         sqlgqryc() -- QUERY CLIENT
      **
      ** OUTPUT FILE: client.out (available in the online documentation)
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
       Program-Id. "client".

       Data Division.
       Working-Storage Section.

           copy "sqlenv.cbl".
           copy "sql.cbl".
           copy "sqlca.cbl".

      * Local Variables

       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).

      * Variables for SET/QUERY CLIENT
       77 listnumber          pic s9(4) comp-5 value 4.

       01 default-settings.
          05 default-items occurs 5 times.
            10 default-type     pic s9(4) comp-5 value 0.
            10 default-value    pic s9(4) comp-5 value 0.

       Procedure Division.
       client-pgm section.

           display "Sample COBOL Program : CLIENT.CBL".

      * setup connection setting structure SQLE-CONN-SETTING
           move SQL-CONNECT-TYPE            to SQLE-CONN-TYPE(1).
           move SQL-RULES                   to SQLE-CONN-TYPE(2).
           move SQL-DISCONNECT              to SQLE-CONN-TYPE(3).
           move SQL-SYNCPOINT               to SQLE-CONN-TYPE(4).

           display "QUERY CLIENT".

      ***************************
      * QUERY CLIENT API called *
      ***************************
           call "sqlgqryc" using
                                 by reference SQLE-CONN-SETTING
                                 by value     listnumber
                                 by reference sqlca
                           returning rc.

           move "QUERY CLIENT" to errloc.
           call "checkerr" using SQLCA errloc.

           perform print-query.

      * capture default settings
           move SQLE-CONN-VALUE(1) to default-value(1).
           move SQLE-CONN-VALUE(2) to default-value(2).
           move SQLE-CONN-VALUE(3) to default-value(3).
           move SQLE-CONN-VALUE(4) to default-value(4).

      * setup connection setting structure SQLE-CONN-SETTING
           move SQL-CONNECT-2       to SQLE-CONN-VALUE(1).
           move SQL-RULES-STD       to SQLE-CONN-VALUE(2).
           move SQL-DISCONNECT-COND to SQLE-CONN-VALUE(3).
           move SQL-SYNC-TWOPHASE   to SQLE-CONN-VALUE(4).

           display "SET CLIENT".
           display "connect type     = SQL-CONNECT-2".
           display "rules            = SQL-RULES-STD".
           display "disconnect       = SQL-DISCONNECT-COND".
           display "syncpoint        = SQL-SYNC-TWOPHASE".

      *************************
      * SET CLIENT API called *
      *************************
           call "sqlgsetc" using
                                 by reference SQLE-CONN-SETTING
                                 by value     listnumber
                                 by reference sqlca
                           returning rc.

           move "SET CLIENT" to errloc.
           call "checkerr" using SQLCA errloc.

           display "QUERY CLIENT".
      ***************************
      * QUERY CLIENT API called *
      ***************************
           call "sqlgqryc" using
                                 by reference SQLE-CONN-SETTING
                                 by value     listnumber
                                 by reference sqlca
                           returning rc.

           move "QUERY CLIENT" to errloc.
           call "checkerr" using SQLCA errloc.

           perform print-query.
      * reset connection setting with default settings
           move default-value(1) to SQLE-CONN-VALUE(1).
           move default-value(2) to SQLE-CONN-VALUE(2).
           move default-value(3) to SQLE-CONN-VALUE(3).
           move default-value(4) to SQLE-CONN-VALUE(4).

           display "SET CLIENT".
      *************************
      * SET CLIENT API called *
      *************************
           call "sqlgsetc" using
                                 by reference SQLE-CONN-SETTING
                                 by value     listnumber
                                 by reference sqlca
                           returning rc.

           move "SET CLIENT" to errloc.
           call "checkerr" using SQLCA errloc.

       end-client. stop run.

       print-query section.
      ***********************
      * SQL CONNECTION TYPE *
      ***********************
           display " ".
           display "SQL CONNECTION TYPE".
           display "===================".
           display " ".

           if SQLE-CONN-VALUE(1) equal SQL-CONNECT-1 then
              display " Enforces the rules for Remote Unit of Work"
                      " (RUOW) from previous releases."
              display "TYPE = SQL-1".

           if SQLE-CONN-VALUE(1) equal SQL-CONNECT-2 then
              display " Supports the multiple database pre unit of work"
                      " semantics DUOW."
              display "TYPE = SQL-2".

      *************
      * SQL RULES *
      *************
           display " ".
           display "SQL RULES".
           display "=========".
           display " ".

           if SQLE-CONN-VALUE(2) equal SQL-RULES-DB2 then
              display " Enables the SQL CONNECT statement to switch the"
                      " current connection to an established (dormant)"
                      " connection."
              display "TYPE = SQL-DB2".

           if SQLE-CONN-VALUE(2) equal SQL-RULES-STD then
           display "Permits the establishement of a new connection only"
                   " through SQL CONNECT statement."
           display "Under SQL_STD, the SQL SET CONNECTION statement is"
                   " used to switch the current connection to a dormant"
                   " connection."
           display "TYPE = SQL-STD".

      ******************
      * SQL DISCONNECT *
      ******************
           display " ".
           display "SQL DISCONNECT".
           display "==============".
           display " ".

           if SQLE-CONN-VALUE(3) equal SQL-DISCONNECT-EXPL then
              display " Breaks those connections that have been"
                      " explicitly marked for release at commit by the"
                      " SQL RELEASE statement."
           display "TYPE = SQL-EXPLICIT".

           if SQLE-CONN-VALUE(3) equal SQL-DISCONNECT-COND then
              display " Breaks those connections that have no open"
                      " WITH HOLD cursors at commit, and those that"
                      " have been marked for release by the"
                      " SQL RELEASE statement."
           display "TYPE = SQL-CONDITIONAL".

           if SQLE-CONN-VALUE(3) equal SQL-DISCONNECT-AUTO then
              display " Breaks all connections at commit."
           display "TYPE = SQL-AUTOMATIC".

      *****************
      * SQL SYNCPOINT *
      *****************
           display " ".
           display "SQL SYNCPOINT".
           display "=============".
           display " ".

           if SQLE-CONN-VALUE(4) equal SQL-SYNC-TWOPHASE then
              display " Requires a Transaction Manager (TM) to"
                      " coordinate two-phase commits among databases"
                      " that support this protocol."
           display "TYPE = SQL-TWOPHASE".

           if SQLE-CONN-VALUE(4) equal SQL-SYNC-ONEPHASE then
              display " Uses one-phase commits to commit the work done"
                      " by each database in multiple database"
                      " transactions. Enforces single updater,"
                      " multiple read behaviour."
           display "TYPE = SQL-ONEPHASE".

           if SQLE-CONN-VALUE(4) equal SQL-SYNC-NONE then
              display " Does not enforce two-phase commits, or"
                      " single updater, multiple read behaviour."
           display "TYPE = SQL-NONE".


       end-print-query. exit.
