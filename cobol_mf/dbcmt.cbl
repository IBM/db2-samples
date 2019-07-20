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
      ** SOURCE FILE NAME: dbcmt.cbl 
      **
      ** SAMPLE: Change a database comment in the database directory
      **
      ** DB2 APIs USED:
      **         db2gDbDirOpenScan -- OPEN DATABASE DIRECTORY SCAN
      **         db2gDbDirGetNextEntry -- GET NEXT DATABASE DIRECTORY ENTRY
      **         db2gDbDirCloseScan -- CLOSE DATABASE DIRECTORY SCAN
      **         sqlgdcgd -- CHANGE DATABASE COMMENT
      **         sqlgisig -- INSTALL SIGNAL HANDLER
      **         sqlgdref -- DEREFERENCE ADDRESS
      **
      ** OUTPUT FILE: dbcmt.out (available in the online documentation)
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
       Program-Id. "dbcmt".

       Data Division.
       Working-Storage Section.

       copy "sqlenv.cbl".
       copy "sqlutil.cbl".
       copy "sqlca.cbl".
       copy "db2ApiDf.cbl".

      * Local Variables
       77 rc                  pic s9(9) comp-5.
       77 idx                 pic 9(4) comp-5.
       77 errloc              pic x(80).

      * Variables for the CHANGE DATABASE COMMENT API
       77 new-comment-len   pic 9(4) comp-5 value 22.
       77 path-len          pic 9(4) comp-5 value 0.
       77 alias-len         pic 9(4) comp-5 value 0.
       77 new-comment       pic x(31) value "THIS IS A NEW Comment".
       77 path              pic x(1025).

      * Variables for OPEN/CLOSE DATABASE DIRECTORY APIs.
       77 dbCount           pic 9(4) comp-5.

      * Variables for GET NEXT DATABASE DIRECTORY ENTRY API.
       77 db-dir-info-sz    pic 9(4) comp-5 value 1654.
       77 disp-drive        pic x(50).

       Procedure Division.
       dbcmt-pgm section.
           display "Sample COBOL Program : DBCMT.CBL".

      **************************
      * INSTALL SIGNAL HANDLER *
      **************************
           call "sqlgisig" using
                                 by reference sqlca
                           returning rc.

           move path-len to DB2-I-PATH-LEN
                of DB2G-DB-DIR-OPEN-SCAN-STRUCT.

           set DB2-PI-PATH of DB2G-DB-DIR-OPEN-SCAN-STRUCT
                to address of path.

      ******************************************
      * OPEN DATABASE DIRECTORY SCAN API called *
      *******************************************
           call "db2gDbDirOpenScan" using
                       by value      DB2VERSION820
                       by reference  DB2G-DB-DIR-OPEN-SCAN-STRUCT
                       by reference  sqlca
                 returning rc.

           move "OPEN DATABASE DIRECTORY SCAN" to errloc.
           call "checkerr" using SQLCA errloc.

           move DB2-O-HANDLE of DB2G-DB-DIR-OPEN-SCAN-STRUCT
              to DB2-I-HANDLE of DB2G-DB-DIR-CLOSE-SCAN-STRUCT.

           move DB2-O-NUM-ENTRIES of DB2G-DB-DIR-OPEN-SCAN-STRUCT
              to dbCount.

           perform get-db-entry thru end-get-db-entry
              varying idx from 0 by 1 until idx equal dbCount.

       after-change-comment.

      ********************************************
      * CLOSE DATABASE DIRECTORY SCAN API called *
      ********************************************
           call "db2gDbDirCloseScan" using
                          by value      DB2VERSION820
                          by reference  DB2G-DB-DIR-OPEN-SCAN-STRUCT
                          by reference  sqlca
                     returning rc.

           move "CLOSE DATABASE DIRECTORY SCAN" to errloc.
           call "checkerr" using SQLCA errloc.

       end-dbcmt. stop run.

       get-db-entry section.

      ************************************************
      * GET NEXT DATABASE DIRECTORY ENTRY API called *
      ************************************************

      * set pointer to DB2G-DB-DIR-OPEN-SCAN-STRUCT
           move DB2-O-HANDLE of DB2G-DB-DIR-OPEN-SCAN-STRUCT to
              DB2-I-HANDLE of DB2G-DB-DIR-NEXT-ENTRY-STRUCT.
              
           call "db2gDbDirGetNextEntry" using
                          by value      DB2VERSION820
                          by reference  DB2G-DB-DIR-NEXT-ENTRY-STRUCT
                          by reference  sqlca
                    returning rc.

      **********************************
      * DEREFERENCE ADDRESS API called *
      **********************************
           call "sqlgdref" using
                       by value       db-dir-info-sz
                       by reference  DB2DB-DIR-INFO
                       by reference  DB2-PO-DB-DIR-ENTRY of
                                        DB2G-DB-DIR-NEXT-ENTRY-STRUCT
                 returning rc.
      
           if SQL-DBNAME-N equal "SAMPLE  "
              go to Change-Comment.

       end-get-db-entry. exit.

       Change-Comment Section.

           inspect SQL-ALIAS-N tallying alias-len for characters
              before initial " ".

           inspect new-comment tallying new-comment-len for characters
              before initial " ".

      ***************************
      * CHANGE DATABASE COMMENT *
      ***************************
           call "sqlgdcgd" using
                                 by value       new-comment-len
                                 by value       path-len
                                 by value       alias-len
                                 by reference   sqlca
                                 by reference   new-comment
                                 by reference   path
                                 by reference   SQL-ALIAS-N
                           returning rc.
           move "CHANGE DATABASE COMMENT" to errloc.
           call "checkerr" using SQLCA errloc.

           display "CHANGE DATABASE COMMENT successful".
       end-Change-Comment. go to after-change-comment.
