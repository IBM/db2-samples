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
      ** SOURCE FILE NAME: d_dbconf.cbl 
      **
      ** SAMPLE: Get database configuration defaults 
      **
      ** DB2 APIs USED:
      **         sqlgddb -- GET DATABASE CONFIGURATION DEFAULTS    
      **         sqlgaddr -- GET ADDRESS                            
      **
      ** OUTPUT FILE: d_dbconf.out (available in the online documentation)
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
       Program-Id. "d_dbconf".

       Data Division.
       Working-Storage Section.
       copy "sqlutil.cbl".
       copy "sqlca.cbl".

      * Local Variables
       77 rc                  pic s9(9) comp-5.
       
       77 errloc              pic x(80).

       01 buff-page           pic 9(9) comp-5.
       01 maxfilop            pic s9(4) comp-5.
       01 softmax             pic s9(4) comp-5.
       01 logpath             pic x(256).

       
      * variables for GET ADDRESS
       01 locklist            pic s9(4) comp-5.
       01 tokenlist.
          05 tokens occurs 5 times.
             10 token         pic 9(4) comp-5.
 
             $IF P64 SET
                 10 filler    pic x(6).
             $ELSE
                 10 filler    pic x(2).
             $END
      
             10 tokenptr      usage is pointer.

      * variables for GET DATABASE CONFIGURATION DEFAULTS
       01 dbname              pic x(8) value "sample".
       01 dbname-len          pic s9(4) comp-5 value 6.
       01 listnumber          pic s9(4) comp-5 value 5.
       

       Procedure Division.
       dbconf-pgm section.

           display "Sample COBOL Program : D_DBCONF.CBL".

           move SQLF-DBTN-LOCKLIST  to token(1).
           move SQLF-DBTN-BUFF-PAGE to token(2).
           move SQLF-DBTN-MAXFILOP  to token(3).
           move SQLF-DBTN-SOFTMAX   to token(4).
           move SQLF-DBTN-LOGPATH   to token(5).
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
           call "sqlgaddr" using by reference logpath
                                 by reference tokenptr(5)
                           returning rc.
      
      **************************************************
      * GET DATABASE CONFIGURATION DEFAULTS API called *
      **************************************************
           call "sqlgddb" using by value     dbname-len
                                by value     listnumber
                                by reference tokenlist
                                by reference sqlca
                                by reference dbname
                           returning rc.
           move "GET DB CFG DEFAULTS" to errloc.
           call "checkerr" using SQLCA errloc.

           display "Max. storage for lost lists (4kb)           : ",
                    locklist.
           display "Buffer pool size (4kb)                      : ",
                    buff-page.
           display "Max. DB files open per application          : ",
                    maxfilop.
           display "percent log reclaimed before soft checkpoint: ",
                    softmax.
           display "path [not changeable]                       : ",
                    logpath.

       end-dbconf. stop run.
