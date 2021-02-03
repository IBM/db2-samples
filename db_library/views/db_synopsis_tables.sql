--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows the Synopsis table name for each column organized table
 */

CREATE OR REPLACE VIEW DB_SYNOPSIS_TABLES AS 
SELECT
    T.TABSCHEMA
,   T.TABNAME
,   D.TABSCHEMA     AS SCHEMA
,   D.TABNAME       AS SYNOPSIS_TABNAME
FROM
    SYSCAT.TABLES   T
INNER JOIN
    SYSCAT.TABDEP   D
ON
    T.TABSCHEMA = D.BSCHEMA
AND T.TABNAME   = D.BNAME
AND               D.DTYPE = '7'
--INNER JOIN
--    SYSCAT.TABLES  S
--ON
--    D.TABSCHEMA = S.TABSCHEMA
--AND D.TABNAME   = S.TABNAME