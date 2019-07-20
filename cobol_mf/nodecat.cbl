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
      ** SOURCE FILE NAME: nodecat.cbl 
      **
      ** SAMPLE: Get node directory information
      **
      **         This program shows how to catalog to, get information
      **         for, and uncatalog from, a node directory.
      **
      ** DB2 APIs USED:
      **         sqlgctnd -- CATALOG NODE
      **         sqlgnops -- OPEN NODE DIRECTORY SCAN
      **         sqlgngne -- GET NEXT NODE DIRECTORY ENTRY
      **         sqlgncls -- CLOSE NODE DIRECTORY SCAN
      **         sqlguncn -- UNCATALOG NODE
      **         sqlgdref -- DEREFERENCE ADDRESS
      **
      ** OUTPUT FILE: nodecat.out (available in the online documentation)
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
       Program-Id. "nodecat".

       Data Division.
       Working-Storage Section.

       copy "sqlenv.cbl".
       copy "sqlca.cbl".

      * Variables for catalog/uncatalog nodes

       77 node-name           pic x(8).
       77 node-name-length    pic s9(4) comp-5 value 0.

      * Local Variables
       77 rc                  pic s9(9) comp-5.
       77 errloc              pic x(80).
       77 idx                 pic 9(9) comp-5.

      * Variables for OPEN, GET, CLOSE, DEREFERENCE nodes
       01 buffer              pointer.
       77 sqleninfo-sz        pic 9(4) comp-5 value 460.
       77 disp-host           pic x(50).
       77 handle              pic 9(4) comp-5.
       77 cbl-count           pic 9(4) comp-5.

       Procedure Division.
       nodecat-pgm section.

           display "Sample COBOL Program : NODECAT.CBL".

      * Initialize local variables
           move "newnode" to node-name.
           inspect node-name tallying node-name-length for characters
              before initial " ".
           display " ".

      * Initialize SQL-NODE-STRUCT structure
           move SQL-NODE-STR-ID to STRUCT-ID of SQL-NODE-STRUCT.
           move "test node : newnode" to COMMENT of SQL-NODE-STRUCT.
           move node-name to NODENAME of SQL-NODE-STRUCT.
           move SQL-PROTOCOL-TCPIP to PROTOCOL of SQL-NODE-STRUCT.

      * for TCP/IP connections, additional information on host and server
      * needs to be entered
      * Initialize SQL-NODE-TCPIP structure
           move "hostname" to HOSTNAME of SQL-NODE-TCPIP.
           move "servicename" to SERVICE-NAME of SQL-NODE-TCPIP.

      *********************************
      * CATALOG NODE API called *
      *********************************
           call "sqlgctnd" using
                                 by reference sqlca
                                 by reference SQL-NODE-STRUCT
                                 by reference SQL-NODE-TCPIP
                           returning rc.

           move "CATALOG NODE" to errloc.
           call "checkerr" using SQLCA errloc.

           display "Now listing all nodes".
           perform list-nodes.

      *********************************
      * UNCATALOG NODE API called *
      *********************************
           call "sqlguncn" using
                                 by value     node-name-length
                                 by reference sqlca
                                 by reference node-name
                           returning rc.

           move "UNCATALOG NODE" to errloc.
           call "checkerr" using SQLCA errloc.

           display "list all nodes [after uncataloged node]".
           perform list-nodes.

       end-nodecat. stop run.

       list-nodes Section.
      ***************************************
      * OPEN NODE DIRECTORY SCAN API called *
      ***************************************
           call "sqlgnops" using
                                 by reference handle
                                 by reference cbl-count
                                 by reference sqlca
                           returning rc.

           if sqlcode equal SQLE-RC-NODE-DIR-EMPTY
              display "--- Node directory is empty ---"
              go to end-list-nodes.
           move "OPEN NODE DIRECTORY SCAN" to errloc.
           call "checkerr" using SQLCA errloc.

           if cbl-count not equal to 0
           perform get-node-entry thru end-get-node-entry
              varying idx from 0 by 1 until idx equal cbl-count.

      ****************************************
      * CLOSE NODE DIRECTORY SCAN API called *
      ****************************************
           call "sqlgncls" using
                                 by value     handle
                                 by reference sqlca
                           returning rc.

           move "CLOSE NODE DIRECTORY SCAN" to errloc.
           call "checkerr" using SQLCA errloc.

       end-list-nodes. exit.

       get-node-entry Section.

      ********************************************
      * GET NEXT NODE DIRECTORY ENTRY API called *
      ********************************************
           call "sqlgngne" using
                                 by value     handle
                                 by reference buffer
                                 by reference sqlca
                           returning rc.

      **********************************
      * DEREFERENCE ADDRESS API called *
      **********************************

           call "sqlgdref" using
                                 by value      sqleninfo-sz
                                 by reference  SQLENINFO
                                 by reference  buffer
                           returning rc.

      * printing out the node information
           move SQL-HOSTNAME of SQLENINFO to disp-host.
           display "node name         : ", SQL-NODE-NAME.
           display "node comment      : ", SQL-COMMENT of SQLENINFO.
           display "node host name    : ", disp-host.
           display "node service name : ", SQL-SERVICE-NAME.

           if SQL-PROTOCOL equal SQL-PROTOCOL-TCPIP
              display "node protocol     : TCP/IP".

           display " ".

       end-get-node-entry. exit.
