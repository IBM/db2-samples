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
      ** SOURCE FILE NAME: dbconf.cbl 
      **
      ** SAMPLE: Update database configuration 
      **
      ** DB2 APIs USED:
      **         sqlgcrea -- CREATE DATABASE
      **         sqlgdrpd -- DROP DATABASE
      **         sqlgxdb -- GET DATABASE CONFIGURATION
      **         sqlgddb -- GET DATABASE CONFIGURATION DEFAULTS
      **         sqlgeudb -- UPDATE DATABASE CONFIGURATION
      **         sqlgrdb -- RESET DATABASE CONFIGURATION
      **         sqlgisig -- INSTALL SIGNAL HANDLER
      **         sqlgaddr -- GET ADDRESS
      **
      ** OUTPUT FILE: dbconf.out (available in the online documentation)
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
       Program-Id. "dbconf".

       Data Division.
       Working-Storage Section.
 
       copy "sqlutil.cbl".
       copy "sqlenv.cbl".
       copy "sqlca.cbl".

      * Local Variables

       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).

 
      * Variables for Create/Drop database
       77 DBNAME              pic x(8)  value "dbconf".
       77 DBNAME-LEN          pic s9(4) comp-5 value 6.
       77 ALIAS               pic x(8)  value "dbconf".
       77 ALIAS-LEN           pic s9(4) comp-5 value 6.
       77 PATH                pic x(255).
       77 PATH-LEN            pic s9(4) comp-5 value 0.
       77 reserved1           pic 9(4)  comp-5 value 0.
       77 reserved2           pic s9(4) comp-5 value 0.

      * Variables for Get/Update/Reset Database Configuration
       77 listnumber          pic s9(4) comp-5 value 4.
       77 locklist            pic s9(4) comp-5.
       77 buff-page           pic 9(9)  comp-5.
       77 maxfilop            pic s9(4) comp-5.
       77 softmax             pic s9(4) comp-5.
       77 logpath             pic x(40).
       77 reserved3           pic 9(4) comp-5 value 0.
       77 reserved4           pointer.

       01 list-of-lengths.
          05 item-length occurs 4 times pic 9(4) comp-5.

       01 tokenlist.
          05 tokens occurs 4 times.
             10 token         pic 9(4) comp-5.
             
             $IF P64 SET
	         10 filler    pic x(6).
             $ELSE
		 10 filler    pic x(2).
             $END
	     10 tokenptr      usage is pointer.

       Procedure Division.
       dbconf-pgm section.

           display "Sample COBOL Program : DBCONF.CBL".

           move SQLF-DBTN-LOCKLIST  to token(1).
           move SQLF-DBTN-BUFF-PAGE to token(2).
           move SQLF-DBTN-MAXFILOP  to token(3).
           move SQLF-DBTN-SOFTMAX   to token(4).

           move "GET ADDRESS" to errloc.
      **************************
      * GET ADDRESS API called *
      **************************
           call "sqlgaddr" using by reference locklist
                                 by reference tokenptr(1)
                           returning rc.

           call "sqlgaddr" using by reference buff-page
                                 by reference tokenptr(2)
                           returning rc.

           call "sqlgaddr" using by reference maxfilop
                                 by reference tokenptr(3)
                           returning rc.

           call "sqlgaddr" using by reference softmax
                                 by reference tokenptr(4)
                           returning rc.

      * setup database description block SQLEDBDESC
           move SQLE-DBDESC-2 to SQLDBDID.
           move 0             to SQLDBCCP.
           move 0             to SQLDBCSS.
           move 0             to SQLDBSGP.
           move 10            to SQLDBNSG.
           move -1            to SQLTSEXT.

           SET SQLCATTS        TO NULLS.
           SET SQLUSRTS        TO NULLS.
           SET SQLTMPTS        TO NULLS.

      * setup database country information structure SQLEDBDESC
           move "IBM-850"     to SQLDBCODESET of SQLEDBCOUNTRYINFO.
           move "En_US"       to SQLDBLOCALE of SQLEDBCOUNTRYINFO.

           display "CREATing the temporary database DBCONF ...".
           display "please wait... this will take a while ...".

 
      ******************************
      * CREATE DATABASE API called *
      ******************************
           call "sqlgcrea" using by value     PATH-LEN
                                 by value     ALIAS-LEN
                                 by value     DBNAME-LEN
                                 by reference sqlca
                                 by value     0
                                 by value     0
                                 by reference SQLEDBCOUNTRYINFO
                                 by reference SQLEDBDESC
                                 by reference PATH
                                 by reference ALIAS
                                 by reference DBNAME
                           returning rc.

           move "creating the database" to errloc.
           call "checkerr" using SQLCA errloc.
           display "database DBCONF created".

           display "getting the database configuration for DBCONF".
 
      **************************************************
      * GET DATABASE CONFIGURATION API called *
      **************************************************
           call "sqlgxdb" using by value     DBNAME-LEN
                                by value     listnumber
                                by reference tokenlist
                                by reference sqlca
                                by reference DBNAME
                           returning rc.

           move "get database config" to errloc.
           call "checkerr" using SQLCA errloc.

           display "listing the database configuration".
           perform print-info.

      * altering the default Database Configuration
           move 4    to locklist.
           move 2000 to buff-page.
           move 3    to maxfilop.
           move 1    to softmax.

           display "UPDATing the database configuration".
 
      ********************************************
      * UPDATE DATABASE CONFIGURATION API called *
      ********************************************
           call "sqlgeudb" using by value     reserved3
                                 by value     DBNAME-LEN
                                 by value     listnumber
                                 by reference list-of-lengths
                                 by reference tokenlist
                                 by reference sqlca
                                 by value     reserved4
                                 by reference DBNAME
                           returning rc.

      * This API always returns a warning about the risk of changing buffer page size.
      * To receive this warning uncomment the following 'move' and 'call' statements.
      *    move "updating the database configuration" to errloc.
      *    call "checkerr" using SQLCA errloc.

           display "listing the UPDATEd database configuration".
           perform print-info.

           display "RESETting the database configuration".
 
      *******************************************
      * RESET DATABASE CONFIGURATION API called *
      *******************************************
           call "sqlgrdb" using by value     DBNAME-LEN
                                by reference sqlca    
                                by reference DBNAME
                           returning rc.

           display "getting DBCONF database configuration defaults".
      **************************************************
      * GET DATABASE CONFIGURATION DEFAULTS API called *
      **************************************************
           call "sqlgddb" using by value     DBNAME-LEN
                                by value     listnumber
                                by reference tokenlist
                                by reference sqlca
                                by reference DBNAME
                           returning rc.

           move "get database config" to errloc.
           call "checkerr" using SQLCA errloc.

           display "printing the database configuration after RESET".
           perform print-info.

           display "DROPping the database DBCONF".
 
      ****************************
      * DROP DATABASE API called *
      ****************************
           call "sqlgdrpd" using by value     reserved1
                                 by value     DBNAME-LEN
                                 by reference sqlca
                                 by value     reserved2
                                 by reference DBNAME
                           returning rc.

           move "dropping the database" to errloc.
           call "checkerr" using SQLCA errloc.

       end-dbconf. stop run.

       print-info section.
      ******************************
      * PRINT INFORMATION *
      ******************************
           display " ".
           display "Max. storage for lost lists (4kb)           : ",
                    locklist.
           display "Buffer pool size (4kb)                      : ",
                    buff-page.
           display "Max. DB files open per application          : ",
                    maxfilop.
           display "percent log reclaimed before soft checkpoint: ",
                    softmax.
           display " ".

       end-print-info. exit.


