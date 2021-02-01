--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generates DDL for all event monitors on the database
 * 
 * db2look does not do this https://www.ibm.com/support/pages/how-can-i-export-ddl-my-event-monitor-definitions
 *   so we need to do it ourselves
 * 
 * TO DO.  Add  DBPARTITIONNUM and target tablespace etc
 */
        
CREATE OR REPLACE VIEW DB_EVENT_MONITOR_DDL AS 
SELECT
    EVMONNAME
,   'CREATE EVENT MONITOR "' || EVMONNAME 
        || CHR(10) || '" FOR ' || E.EVENTS
        || COALESCE(' MAXFILES '   || MAXFILES,'') 
        || COALESCE(' BUFFERSIZE ' || NULLIF(BUFFERSIZE,4),'')
        || CASE WHEN    IO_MODE = 'N' THEN ' NONBLOCKED' ELSE '' END
        || CASE WHEN WRITE_MODE = 'R' THEN ' REPLACE'    ELSE '' END
        || CHR(10) || 'WRITE TO ' || CASE TARGET_TYPE WHEN 'F' THEN 'FILE ''' || TARGET || '''' 
                                                  WHEN 'P' THEN 'PIPE ''' || TARGET || ''''
                                                  WHEN 'T' THEN 'TABLE' || T.TABLES 
                                                  ELSE '' END
        || CASE AUTOSTART WHEN 'Y' THEN  CHR(10) ||  'AUTOSTART' ELSE '' END     AS DDL
FROM
     SYSCAT.EVENTMONITORS M
JOIN 
(   SELECT
        EVMONNAME
    ,   LISTAGG(TYPE
                || COALESCE(' WHERE ' || FILTER,'')
        ,', ') AS EVENTS
    FROM
        SYSCAT.EVENTS
    GROUP BY
        EVMONNAME
) E
    USING (EVMONNAME)
LEFT JOIN
(   SELECT
        EVMONNAME
    ,   CHR(10) || '    ' 
        || LISTAGG(LOGICAL_GROUP || REPEAT(' ', 30 - LENGTH(LOGICAL_GROUP))
            || COALESCE(' ( TABLE "' || RTRIM(TABSCHEMA)  || '"."' || TABNAME || '"' 
            || CASE WHEN TABOPTIONS IS NOT NULL THEN ' ' || TABOPTIONS ELSE '' END
            || CASE WHEN PCTDEACTIVATE <> 100 THEN ' PCTDEACTIVATE ' || PCTDEACTIVATE ELSE '' END
            || ')','')
        ,CHR(10) || ',   ') AS TABLES
    FROM
        SYSCAT.EVENTTABLES t 
    GROUP BY
        EVMONNAME
) T
    USING (EVMONNAME)