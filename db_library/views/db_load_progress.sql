--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Show progress on any LOAD statements
 * 
 * TO-DO, filter other utilities out (or change the name of the view...)
 */

CREATE OR REPLACE VIEW DB_LOAD_PROGRESS AS
SELECT
    SNAPSHOT_TIMESTAMP      -- TIMESTAMP   The date and time that the snapshot was taken.
,   UTILITY_ID              -- INTEGER     utility_id - Utility ID . Unique to a database partition.
,   PROGRESS_SEQ_NUM        --  INTEGER     progress_seq_num - Progress sequence number . If serial, the number of the phase. If concurrent, then could be NULL.
,   UTILITY_STATE           -- VARCHAR(16)     utility_state - Utility state . This interface returns a text identifier based on the defines in sqlmon.h
,   PROGRESS_DESCRIPTION   -- VARCHAR(2048)   progress_description - Progress description
,   PROGRESS_START_TIME    -- TIMESTAMP   progress_start_time - Progress start time . Start time if the phase has started, otherwise NULL.
--,   SUM(CASE WHEN PROGRESS_WORK_METRIC = 'BYTES' THEN PROGRESS_TOTAL_UNITS ELSE 0 END) AS BYTES
,   SUM(CASE WHEN PROGRESS_WORK_METRIC = 'ROWS'  THEN PROGRESS_TOTAL_UNITS ELSE 0 END) AS ROWS
FROM
    TABLE(SNAP_GET_UTIL_PROGRESS(-2))
GROUP BY
    SNAPSHOT_TIMESTAMP 
,   UTILITY_ID          
,   PROGRESS_SEQ_NUM    
,   UTILITY_STATE       
,   PROGRESS_DESCRIPTION
,   PROGRESS_START_TIME
