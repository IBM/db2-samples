--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists current completed backup images from SYSIBMADM.DB_HISTORY
 */

CREATE OR REPLACE VIEW DB_BACKUPS AS
SELECT
        TIMESTAMP(START_TIME,0)                       AS START_DATETIME
,       TIMESTAMP(END_TIME,0)                         AS END_DATETIME
,             HOURS_BETWEEN(END_TIME, START_TIME)     AS HOURS
,       MOD(MINUTES_BETWEEN(END_TIME, START_TIME),60) AS MINS
,       MOD(SECONDS_BETWEEN(END_TIME, START_TIME),60) AS SECS
,       COMMENT                                       AS OPERATION
,       CASE OPERATIONTYPE
            WHEN 'D' THEN 'Delta Offline'
            WHEN 'E' THEN 'Delta Online'
            WHEN 'F' THEN 'Offline'
            WHEN 'I' THEN 'Incremental Offline'
            WHEN 'N' THEN 'Online'
            WHEN 'O' THEN 'Incremental Online'
        END                                           AS BACKUP_TYPE
,       LOCATION                                      AS BACKUP_LOCATION
,       SQLCODE
,       NUM_TBSPS
,       MEMBERS
,       TBSPNAMES   AS TABLESPACES
FROM
(   SELECT
        START_TIME
    ,   END_TIME
    ,   COMMENT
    ,   OPERATIONTYPE
    ,   LOCATION
    ,   SQLCODE
    ,   NUM_TBSPS
    ,   TBSPNAMES
    ,   LISTAGG(DBPARTITIONNUM,',') WITHIN GROUP ( ORDER BY DBPARTITIONNUM) AS MEMBERS
    FROM
	(   SELECT DISTINCT    -- Use distinct because we get duplicate entries back from DB_HISTORY
		    START_TIME
		,   END_TIME
		,   COMMENT
		,   OPERATIONTYPE
		,   LOCATION
		,   SQLCODE
		,   NUM_TBSPS
	    ,   VARCHAR(TBSPNAMES,32000) AS TBSPNAMES -- Convert the BLOB to VARCHAR to allow the aggregation
	    ,   DBPARTITIONNUM
	    FROM
	        SYSIBMADM.DB_HISTORY H
	    WHERE
	        OPERATION = 'B'
	) AS SS
       GROUP BY
        START_TIME
    ,   END_TIME
    ,   COMMENT
    ,   OPERATIONTYPE
    ,   LOCATION
    ,   SQLCODE
    ,   NUM_TBSPS
    ,   TBSPNAMES
) AS S