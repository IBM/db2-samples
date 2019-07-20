/*********************************************************************/
/*  IBM DB2 Q Replication                                            */
/*                                                                   */
/*     ASNCLP sample files                                           */
/*                                                                   */
/*     Licensed Materials - Property of IBM                          */
/*                                                                   */
/*     (C) Copyright IBM Corp. 2004 All Rights Reserved              */
/*                                                                   */
/*     US Government Users Restricted Rights - Use, duplication      */
/*     or disclosure restricted by GSA ADP Schedule Contract         */
/*     with IBM Corp.                                                */
/*                                                                   */
/*********************************************************************/
/*********************************************************************/
/*                                                                   */
/*                                                                   */
/*           NOTICE TO USERS OF THE SOURCE CODE EXAMPLE              */
/*                                                                   */
/* INTERNATIONAL BUSINESS MACHINES CORPORATION PROVIDES THE SOURCE   */
/* CODE EXAMPLE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         */
/* EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO THE IMPLIED   */
/* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR        */
/* PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE */
/* SOURCE CODE EXAMPLE IS WITH YOU. SHOULD ANY PART OF THE SOURCE    */
/* CODE EXAMPLE PROVES DEFECTIVE, YOU (AND NOT IBM) ASSUME THE       */
/* ENTIRE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.     */
/*                                                                   */
/*********************************************************************/

SQL Setup - filename: "setup.sql"

3 Databases (testdb, testdb1, testdb2)

testdb  - schema BLUE
tables - AllTypes1, AllTypes2, AllTypes3, AllTypes4, AllTypes5, AllTypes6

testdb1 - schema RED
tables - AllTypes1, AllTypes2, AllTypes3, AllTypes4, AllTypes5, AllTypes6

testdb2 - schema YELLOW
tables - AllTypes1, AllTypes2, AllTypes3, AllTypes4, AllTypes5, AllTypes6

--------------------------------------------------------------------------|

Create Subgroups for 3 Node scenario Peer to Peer

CLP Script 1 - 4 multidir scripts - filename: "3Nodes.in"

3 - Nodes setup

Multidir scripts:
Create Subgroup 3Node0 with all Logical tables provided and existing. - filename: "3Node0.in"
Create Subgroup 3Node1 with all Logical table names provided two existing. - filename: "3Node1.in"
Create Subgroup 3Node2 with all Logical table names provided one existing. - filename: "3Node2.in"
Create Subgroup 3Node3 with only source table name provided w/ 3 Logical Tables. - filename: "3Node3.in"


--------------------------------------------------------------------------|

Create Subgroups for 2 Node scenario Peer to Peer

CLP Script 2 - 3 multidir scripts - filename: "2Nodes.in"

2 - Nodes setup
2 Databases (testdb, testdb1)

Multidir scripts:
Create Subgroup 2Node0 with all Logical tables provided and existing. - filename: "2Node0.in"
Create Subgroup 2Node1 with one Logical table existing w/ custom Has Load Phase, Error Action, Load Type, SQL States - filename: "2Node1.in"
Create Subgroup 2Node2 with one Logical table existing w/ 3 Logical Tables - filename: "2Node2.in"

--------------------------------------------------------------------------|

Create Subgroups for Bidirectional

CLP Script 3 - 3 multidir scripts - filename: "Bidir.in"

2 - Nodes only
2 Databases (testdb, testdb1)

Multidir scripts:
Create Subgroup Bidir0 with all Logical tables provided and existing. - filename: "Bidir0.in"
Create Subgroup Bidir1 with all Logical tables provided and existing w/ custom attributes in one direction. - filename: "Bidir1.in"
Create Subgroup Bidir2 with all Logical tables provided and existing w/ custom attributes in both directions. - filename: "Bidir2.in"
Create Subgroup Bidir3 with all Logical tables provided and existing w/ 2 Logical Tables - filename: "Bidir3.in"

--------------------------------------------------------------------------|

Update Subgroups for Peer to Peer and Bidirectional

CLP Script 4 - 3 multidir scripts - filename: "Update.in"

Multidir scripts:
Update all attributes for Subgroup 3Node0 - filename: "Update0.in"
Update all attributes for Subgroup 3Node3 - Logical table using reference table AllTypes5 - filename: "Update1.in"
Update all attributes for Subgroup 2Node0 - filename: "Update2.in"
Update all attributes for both directions of Subgroup Bidir0 - filename: "Update3.in"

--------------------------------------------------------------------------|

Adding a logical table to a Subgroup for Peer to Peer

CLP Script 5 - 1 multidir scripts - filename: "Addtables.in"

Multidir scripts:
Add a Logical Table using source table AllTypes5 to Subgroup 3Node3 - filename: "Addtables.in"

--------------------------------------------------------------------------|

Delete Subgroups/Logical Tables for Peer to Peer and Bidirectional

CLP Script 6 - 4 multidir scripts - filename: "Delete.in"

Multidir scripts:
Drop Logical Table for Subgroup 3Node3 - Logical table using reference table AllTypes5 - filename: "Delete0.in"
Drop Subgroup 3Node3 - filename: "Delete1.in"
Drop Subgroup 2Node2 - filename: "Delete2.in"
Drop Subgroup Bidir0 - filename: "Delete3.in"
