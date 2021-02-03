--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Run a dummy select for from every table on the database
 * 
 * This is usefull to force all tables to be picked up by the MON_GET_TABLE monitoring function
 *   which only includes objects that have been accesses since the last Db2 restart
 * 
 */

CREATE TABLE SYSTOOLS.DUMMY(I INT)

@

BEGIN 
    DECLARE NOT_ALLOWED CONDITION FOR SQLSTATE '57016';    -- Skip LOAD pending tables etc. I.e. SQL0668N Operation not allowed 
    DECLARE UNDEFINED_NAME CONDITION FOR SQLSTATE '42704'; -- Skip tables that no longer exist/not commited
    DECLARE CONTINUE HANDLER FOR NOT_ALLOWED, UNDEFINED_NAME BEGIN END;
--    
    FOR D AS 
        SELECT 'UPDATE SYSTOOLS.DUMMY SET I = 0 WHERE 0 = (SELECT 1 FROM "' || TABSCHEMA || '"."' || TABNAME || '" LIMIT 1)' AS S 
        FROM
            SYSCAT.TABLES
        WHERE
            TYPE IN ('T','S') 
        --AND TABSCHEMA NOT LIKE 'SYS%'
        WITH UR
  DO   
      EXECUTE IMMEDIATE D.S;
  END FOR;
END
