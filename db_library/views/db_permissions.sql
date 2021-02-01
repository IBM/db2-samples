--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists and Row and Column Access Control (RCAC) permissions you have applied on the system (from SYSCAT.CONTORLS)
 */

CREATE OR REPLACE VIEW DB_PERMISSIONS AS
SELECT 
    TABSCHEMA
,   TABNAME
,   CONTROLNAME
,       'CREATE OR REPLACE PERMISSION "' || CONTROLNAME || '  ON "' || TABSCHEMA || '"."' || TABNAME || CHR(34) 
    || ' FOR ROWS WHERE ' || RULETEXT
    || ' ENFORCED FOR ALL ACCESS ' || CASE ENABLE WHEN 'Y' THEN 'ENABLE' ELSE 'DISABLE' END
    AS DDL
FROM
    SYSCAT.CONTROLS