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
      ** SOURCE FILE NAME: dcscat.cbl 
      **
      ** SAMPLE: Get information for a DCS directory in a database
      **
      **         This program shows how to catalog to, get information
      **         for and uncatalog from a Database Connection Services 
      **         (DCS) directory. 
      **
      ** DB2 APIs USED:
      **         sqlggdge -- GET DCS DIRECTORY ENTRY
      **         sqlggdad -- CATALOG DCS DIRECTORY ENTRY
      **         sqlggdsc -- OPEN DCS DIRECTORY SCAN
      **         sqlggdgt -- GET DCS DIRECTORY ENTRIES
      **         sqlggdcl -- CLOSE DCS DIRECTORY SCAN
      **         sqlggdel -- UNCATALOG DCS DIRECTORY ENTRY
      **
      ** OUTPUT FILE: dcscat.out (available in the online documentation)
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
       Program-Id. "dcscat".

       Data Division.
       Working-Storage Section.

       copy "sqlenv.cbl".
       copy "sqlca.cbl".

      * Local Variables
       77 rc                  pic s9(9) comp-5.

       77 errloc              pic x(80).
      * Variables for the DCS DIRECTORY SCAN APIs
       77 dbcount             pic s9(4) comp-5.
       77 cbl-count           pic s9(4) comp-5 value 1.
       77 idx                 pic s9(4) comp-5.

       Procedure Division.
       dcscat-pgm section.

           display "Sample COBOL Program : DCSCAT.CBL".

           move "this is a dcs database" to COMMENT of SQL-DIR-ENTRY.
           move "dcsnm"                  to LDB     of SQL-DIR-ENTRY.
           move "targetnm"               to TDB     of SQL-DIR-ENTRY.
           move "arName"                 to AR      of SQL-DIR-ENTRY.
           move SQL-DCS-STR-ID           to
                STRUCT-ID of SQL-DIR-ENTRY.
           move " "                      to PARM    of SQL-DIR-ENTRY.

           display "cataloging the DCS database : ",
                TDB of SQL-DIR-ENTRY.
      ***********************************
      * CATALOG DCS DATABASE API called *
      ***********************************
           call "sqlggdad" using
                                 by reference sqlca
                                 by reference SQL-DIR-ENTRY
                           returning rc.

           move "cataloging the database" to errloc.
           call "checkerr" using SQLCA errloc.

           display "database ", TDB of SQL-DIR-ENTRY,
                " has been catalogued".

           display "now listing all databases".
           perform list-dcs thru end-list-dcs.

           display "now uncataloging the database that was created ",
                    TDB of SQL-DIR-ENTRY.

      *************************************
      * UNCATALOG DCS DATABASE API called *
      *************************************
           call "sqlggdel" using
                                 by reference sqlca
                                 by reference SQL-DIR-ENTRY
                           returning rc.

           move "uncataloging the database" to errloc.
           call "checkerr" using SQLCA errloc.

           display "now listing all databases [after uncatalog DCS]".
           perform list-dcs thru end-list-dcs.

       end-dcscat. stop run.

       list-dcs Section.
      **************************************
      * OPEN DCS DIRECTORY SCAN API called *
      **************************************
           call "sqlggdsc" using
                                 by reference sqlca
                                 by reference dbcount
                           returning rc.

           if sqlcode equal SQLE-RC-NO-ENTRY
              display "--- DCS directory is empty ---"
              go to close-dcs-scan.
           move "opening the database directory scan" to errloc.
           call "checkerr" using SQLCA errloc.

           if dbcount not equal 0 then
           perform display-dcs-info thru end-display-dcs-info
               varying idx from 1 by 1 until idx equal dbcount.

       display-dcs-info Section.
      *************************************
      * GET DCS DIRECTORY SCAN API called *
      *************************************
           call "sqlggdgt" using
                                 by reference sqlca
                                 by reference cbl-count
                                 by reference SQL-DIR-ENTRY
                           returning rc.

           display "number of dcs databases : " , cbl-count.

           display "Local Database Name :" , LDB of SQL-DIR-ENTRY.
           display "Target Database Name:" , TDB of SQL-DIR-ENTRY.
           display "App. Requestor Name :" , AR of SQL-DIR-ENTRY.
           display "DCS parameters      :" , PARM of SQL-DIR-ENTRY.
           display "Comment             :" , COMMENT of SQL-DIR-ENTRY.
           display "DCS Release Level   :" ,
                   RELEASE-LVL of SQL-DIR-ENTRY.
           display " ".
       end-display-dcs-info. exit.

           move "getting dcs database entries" to errloc.
           call "checkerr" using SQLCA errloc.
      *********************************************
      * GET DCS DIRECTORY FOR DATABASE API called *
      *********************************************
      * use the SQL-DIR-ENTRY from the previous call
           call "sqlggdge" using
                                 by reference sqlca
                                 by reference SQL-DIR-ENTRY
                           returning rc.

       close-dcs-scan.

      ***************************************
      * CLOSE DCS DIRECTORY SCAN API called *
      ***************************************
           call "sqlggdcl" using
                                 by reference sqlca
                           returning rc.

           move "closing the database directory scan" to errloc.
           call "checkerr" using SQLCA errloc.
       end-list-dcs. exit.
