--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns common separated lists of column names for all tables
 */

CREATE OR REPLACE VIEW DB_COLUMN_LIST AS
SELECT  
    TABSCHEMA
,   TABNAME
,   LISTAGG('"' || COLNAME || '"', ',')               WITHIN GROUP (ORDER BY COLNO)   AS COMMA_LIST
,   LISTAGG('"' || COLNAME || '"', CHR(10) || ',   ') WITHIN GROUP (ORDER BY COLNO)   AS LF_LIST
,   LISTAGG(       COLNAME       , ',')               WITHIN GROUP (ORDER BY COLNO)   AS COMMA_UNQUOTED_LIST
,   LISTAGG(       COLNAME       , CHR(10) || ',   ') WITHIN GROUP (ORDER BY COLNO)   AS LF_UNQUOTED_LIST
,   LISTAGG('"' || COLNAME || '"', ',')               WITHIN GROUP (ORDER BY COLNAME) AS COMMA_SORTED_LIST
,   LISTAGG('"' || COLNAME || '"', CHR(10) || ',   ') WITHIN GROUP (ORDER BY COLNAME) AS LF_SORTED_LIST
,   LISTAGG(       COLNAME       , ',')               WITHIN GROUP (ORDER BY COLNAME) AS COMMA_UNQUOTED_SORTED_LIST
,   LISTAGG(       COLNAME       , CHR(10) || ',   ') WITHIN GROUP (ORDER BY COLNAME) AS LF_UNQUOTED_SORTED_LIST
FROM
    SYSCAT.COLUMNS C
GROUP BY
    TABSCHEMA
,   TABNAME
