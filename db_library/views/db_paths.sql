--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists file system paths used by the database
 */

CREATE OR REPLACE VIEW DB_PATHS AS 
SELECT
    TYPE
,   PATH
,   LISTAGG(DBPARTITIONNUM,',') WITHIN GROUP (ORDER BY DBPARTITIONNUM) AS MEMBERS
FROM
(   SELECT
        TYPE
    ,   REGEXP_REPLACE(PATH,'([^0-9])[0-9]{4}([^0-9])','\1xxxx\2')    AS PATH
    ,   DBPARTITIONNUM
    FROM TABLE(SYSPROC.ADMIN_LIST_DB_PATHS()) AS T
)
GROUP BY
    TYPE
,   PATH
