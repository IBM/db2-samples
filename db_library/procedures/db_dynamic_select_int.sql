--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/* 
 * A procedure to run the passed SQL statement and one integer parameter, and return it's result as a dynamic result set
 *
 */

CREATE OR REPLACE PROCEDURE DB_DYNAMIC_SELECT_INT
(   
    IN SELECT_STMT     CLOB(16M OCTETS)   -- 2M is the documented statement limit
,   IN PARAM_MARKER_BIGINT       BIGINT    
)
    SPECIFIC DB_DYNAMIC_SELECT_INT
    DYNAMIC RESULT SETS 1
BEGIN
    DECLARE S STATEMENT;
    DECLARE C CURSOR WITH RETURN TO CALLER FOR S;
    --
    PREPARE S FROM SELECT_STMT;
    OPEN C USING PARAM_MARKER_BIGINT ;
END
