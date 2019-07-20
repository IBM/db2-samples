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
      ** SOURCE FILE NAME: checkerr.cbl 
      **
      ** SAMPLE: Checks for and prints to the screen SQL warnings and errors 
      **
      **         This utility file is compiled and linked in as an object
      **         module with COBOL sample programs by the supplied 
      **         makefile.
      ** 
      ** DB2 APIs USED:
      **         sqlggstt -- GET SQLSTATE MESSAGE
      **         sqlgintp -- GET ERROR MESSAGE
      **
      ** OUTPUT FILE: None 
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
       Program-ID. "checkerr".

       Data Division.
       Working-Storage Section.

       copy "sql.cbl".

      * Local variables
       77 error-rc        pic s9(9) comp-5.
       77 state-rc        pic s9(9) comp-5.

      * Variables for the GET ERROR MESSAGE API
      * Use application specific bound instead of BUFFER-SZ
      * 77 buffer-size     pic s9(4) comp-5 value BUFFER-SZ.
      * 77 error-buffer    pic x(BUFFER-SZ).
      * 77 state-buffer    pic x(BUFFER-SZ).
       77 buffer-size     pic s9(4) comp-5 value 1024.
       77 line-width      pic s9(4) comp-5 value 80.
       77 error-buffer    pic x(1024).
       77 state-buffer    pic x(1024).

       Linkage Section.
       copy "sqlca.cbl" replacing ==VALUE "SQLCA   "== by == ==
                                  ==VALUE 136==        by == ==.
       01 errloc          pic x(80).

       Procedure Division using sqlca errloc.
       Checkerr Section.
           if SQLCODE equal 0
              go to End-Checkerr.

           display "--- error report ---".
           display "ERROR occurred : ", errloc.
           display "SQLCODE : ", SQLCODE.

      ********************************
      * GET ERROR MESSAGE API called *
      ********************************
           call "sqlgintp" using
                                 by value     buffer-size
                                 by value     line-width
                                 by reference sqlca
                                 by reference error-buffer
                           returning error-rc.

      ************************
      * GET SQLSTATE MESSAGE *
      ************************
           call "sqlggstt" using
                                 by value     buffer-size
                                 by value     line-width
                                 by reference sqlstate
                                 by reference state-buffer
                           returning state-rc.

           if error-rc is greater than 0
              display error-buffer.

           if state-rc is greater than 0
              display state-buffer.

           if state-rc is less than 0
              display "return code from GET SQLSTATE =" state-rc.

           if SQLCODE is less than 0
              display "--- end error report ---"
              go to End-Prog.

           display "--- end error report ---"
           display "CONTINUING PROGRAM WITH WARNINGS!".
       End-Checkerr. exit program.
       End-Prog. stop run.
