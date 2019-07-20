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
      ** SOURCE FILE NAME: dbcat.cbl 
      **
      ** SAMPLE: Catalog to and uncatalog from a database 
      **
      ** DB2 APIs USED:
      **         sqlgcadb -- CATALOG DATABASE 
      **         db2gDbDirOpenScan -- OPEN DATABASE DIRECTORY SCAN
      **         db2gDbDirGetNextEntry -- GET NEXT DATABASE DIRECTORY ENTRY      
      **         db2gDbDirCloseScan -- CLOSE DATABASE DIRECTORY SCAN          
      **         sqlguncd -- UNCATALOG DATABASE
      **         sqlgdref -- DEREFERENCE ADDRESS                    
      **
      ** OUTPUT FILE: dbcat.out (available in the online documentation)
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
       Program-Id. "dbcat".

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

      * Variables for the CATALOG/UNCATALOG DATABASE APIs
       77 dce-prin-len      pic 9(4) comp-5.
       77 comment-len       pic 9(4) comp-5.
       77 path-len          pic 9(4) comp-5.
       77 nname-len         pic 9(4) comp-5.
       77 alias-len         pic 9(4) comp-5.
       77 db-len            pic 9(4) comp-5.
       77 authentication    pic 9(4) comp-5.
       77 dce-prin          pic x(21).
       77 cbl-comment       pic x(31).
       77 path              pic x(1025).
       77 nname             pic x(9).
       77 loc-type          pic x.
       77 alias             pic x(9).
       77 database          pic x(9).

      * Variables for OPEN/CLOSE DATABASE DIRECTORY APIs.
       77 dbCount           pic 9(4) comp-5.
       77 dbHandle          pic 9(4) comp-5.

      * Variables for GET NEXT DATABASE DIRECTORY ENTRY API.
       77 db-dir-info-sz    pic 9(4) comp-5 value 1654.
       77 disp-drive        pic x(50).

       Procedure Division.
       dbcat-pgm section.
           display " ".
           display "Sample COBOL Program : DBCAT.CBL".
      
           move 0 to dce-prin-len.
      
           move "this is a test database" to cbl-comment.
           move 23 to comment-len.
      
           move 0 to path-len.
           move 0 to nname-len.
           move SQL-AUTHENTICATION-SERVER to authentication.
           move SQL-INDIRECT to loc-type.
           move "newalias" to alias.
           move 8 to alias-len.
           move "newdata" to database.
           move 7 to db-len.
      
           display " ".
           display "cataloging the new database".
      
      *******************************
      * CATALOG DATABASE API called *
      *******************************
           call "sqlgcadb" using
                                 by value       dce-prin-len
                                 by value       comment-len
                                 by value       path-len
                                 by value       nname-len
                                 by value       alias-len
                                 by value       db-len
                                 by reference   sqlca
                                 by reference   dce-prin
                                 by value       authentication
                                 by reference   cbl-comment
                                 by reference   path
                                 by reference   nname
                                 by value       loc-type
                                 by reference   alias
                                 by reference   database
                           returning rc.

           move "CATALOG DATABASE" to errloc.
           call "checkerr" using SQLCA errloc.
      
           display " ".
           display "listing all databases...".
           display "========================".
           perform list-db.
      
           display "UNCATALOGing the database that was created".
      
      *********************************
      * UNCATALOG DATABASE API called *
      *********************************
           call "sqlguncd" using
                                 by value       alias-len
                                 by reference   sqlca
                                 by reference   alias
                           returning rc.

           move "UNCATALOG DATABASE" to errloc.
           call "checkerr" using SQLCA errloc.
      
           display " ".
           display "Listing all databases [after UNCATALOG]".
           display "=======================================".
           perform list-db.
       end-dbcat. stop run.

       list-db Section.

           move path-len to DB2-I-PATH-LEN
                of DB2G-DB-DIR-OPEN-SCAN-STRUCT.

           set DB2-PI-PATH of DB2G-DB-DIR-OPEN-SCAN-STRUCT
                to address of path.

      *******************************************
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
              to dbcount.

           perform get-db-entry thru end-get-db-entry
              varying idx from 0 by 1 until idx equal dbCount.

      ********************************************
      * CLOSE DATABASE DIRECTORY SCAN API called *
      ********************************************
           call "db2gDbDirCloseScan" using
                        by value      DB2VERSION820
                        by reference  DB2G-DB-DIR-CLOSE-SCAN-STRUCT
                        by reference  sqlca
                returning rc.

           move "CLOSE DATABASE DIRECTORY SCAN" to errloc.
           call "checkerr" using SQLCA errloc.

       end-list-db. exit.

       get-db-entry section.
      
      ************************************************
      * GET NEXT DATABASE DIRECTORY ENTRY API called *
      ************************************************
      * set pointer to DB2G-DB-DIR-OPEN-SCAN-STRUCT
           move DB2-O-HANDLE of 
              DB2G-DB-DIR-OPEN-SCAN-STRUCT to
              DB2-I-HANDLE of
              DB2G-DB-DIR-NEXT-ENTRY-STRUCT.
      
           call "db2gDbDirGetNextEntry" using
                         by value DB2VERSION820
                         by reference  DB2G-DB-DIR-NEXT-ENTRY-STRUCT
                         by reference  sqlca
                     returning rc.
      
      **********************************
      * DEREFERENCE ADDRESS API called *
      **********************************
           call "sqlgdref" using
               by value      db-dir-info-sz
               by reference  DB2DB-DIR-INFO
               by reference  DB2-PO-DB-DIR-ENTRY of 
                                DB2G-DB-DIR-NEXT-ENTRY-STRUCT
            returning rc.

           display " ".
      
      * Displaying the contents of the DB2DB-DIR-INFO structure.
      * The DB2DB-DIR-INFO structure is found in file "db2ApiDf.cbl" which is copied
      * into this program.  The "db2ApiDf.cbl" file can be found in the
      * "sqllib/include/cobol*" directory.

           display "alias :                 ",
                    SQL-ALIAS-N.

           display "database name :         ",
                    SQL-DBNAME-N.

           display "node name :             ",
                    SQL-NODENAME-N.

           display "database release type : ",
                    SQL-DBTYPE-N.

           display "database comment :      ",
                    SQL-COMMENT-N.

           display "database entry type :   ",
                    SQL-TYPE-N.
      
           if SQL-AUTHENTICATION-N equal SQL-AUTHENTICATION-SERVER
              display "authentication :        SERVER".
      
           if SQL-AUTHENTICATION-N equal SQL-AUTHENTICATION-CLIENT
              display "authentication :        CLIENT".
      
           if SQL-AUTHENTICATION-N equal SQL-AUTHENTICATION-DCS
              display "authentication :        DCS".
      
              display " ".

       end-get-db-entry. exit.
