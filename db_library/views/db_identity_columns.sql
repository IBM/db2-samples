--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0
  
/*
 * Lists all Identity columns
 * 
 *  * Note that if you have done an ALTER IDENTITY RESTART WITH
 *   but not then taken a new identity value
 *   then you won't see the new restart value via the Db2 catalog views
 *   It is in the table "packed descriptor" which db2look can access,
 *   or you could use e.g.  
 *      db2cat -p sequence -d YOURDB -s SEQ_SCHEMA -n SEQ_NAME -t | grep Restart
 *   to see the unsed RESTART value
 */

CREATE OR REPLACE VIEW DB_IDENTITY_COLUMNS AS
SELECT
    TABSCHEMA
,   TABNAME
,   COLNAME
,   C.TYPENAME
,   C.NULLS
,   NEXTCACHEFIRSTVALUE
,   CACHE
,   START
,   INCREMENT
,   MINVALUE
,   MAXVALUE
,   CYCLE
--,   SEQID
FROM
     SYSCAT.COLIDENTATTRIBUTES  I
JOIN SYSCAT.COLUMNS             C  USING (TABSCHEMA, TABNAME,  COLNAME)
--JOIN SYSCAT.SEQUENCES   S  USING (SEQID)
