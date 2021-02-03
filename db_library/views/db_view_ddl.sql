--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns the DDL used to create VIEWs
 */

CREATE OR REPLACE VIEW DB_VIEW_DDL AS
SELECT  V.VIEWSCHEMA
,       V.VIEWNAME
,       V.TEXT        AS DDL
,       DB_FORMAT_SQL(TEXT)  AS FORMATTED_DDL
FROM
    SYSCAT.VIEWS  V
INNER JOIN
    SYSCAT.TABLES T
ON
    T.TABSCHEMA = V.VIEWSCHEMA 
AND T.TABNAME   = V.VIEWNAME
AND T.TYPE = 'V'  -- exclude MQTs