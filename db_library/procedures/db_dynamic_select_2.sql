--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/* 
 * A procedure to run the passed two SQL statements and return thier results as a dynamic result sets
 *
 */

CREATE OR REPLACE PROCEDURE DB_DYNAMIC_SELECT_2
(   
    IN SELECT_STMT_1     CLOB(16M OCTETS)   -- 2M is the documented statement limit
,   IN SELECT_STMT_2     CLOB(16M OCTETS)   -- 2M is the documented statement limit    
)
    SPECIFIC DB_DYNAMIC_SELECT_2
    DYNAMIC RESULT SETS 2
BEGIN
    DECLARE S1 STATEMENT;
    DECLARE S2 STATEMENT;
    DECLARE C1 CURSOR WITH RETURN TO CALLER FOR S1;
    DECLARE C2 CURSOR WITH RETURN TO CALLER FOR S2;
    --
    PREPARE S1 FROM SELECT_STMT_1;
    OPEN C1;
    PREPARE S2 FROM SELECT_STMT_2;
    OPEN C2;
END
