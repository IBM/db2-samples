--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all Sequences
 * 
 * Note that if you have done an ALTER SEQUENCE RESTART WITH
 *   but not then taken a new sequence value with e.g. VALUES NEXT VAL FOR seqeuence
 *   then you won't see the new restart value via the Db2 catalog views
 *   It is in the table "packed descriptor" which db2look can access,
 *   or you could use e.g.  
 *      db2cat -p sequence -d YOURDB -s SEQ_SCHEMA -n SEQ_NAME -t | grep Restart
 *   to see the unsed RESTART value
 */

CREATE OR REPLACE VIEW DB_SEQUENCES AS
SELECT
    SEQSCHEMA
,   SEQNAME
,      CASE SEQTYPE WHEN 'I' THEN 'IDENTITY' WHEN 'S' THEN 'SEQUENCE' END AS SEQTYPE
,   NEXTCACHEFIRSTVALUE
,   CACHE
,   START
,   INCREMENT
,   MINVALUE
,   MAXVALUE
,   CYCLE
--,   SEQID
FROM
    SYSCAT.SEQUENCES
