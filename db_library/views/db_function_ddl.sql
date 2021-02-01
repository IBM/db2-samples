--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns the CREATE FUNCTION DDL for all user defined functions on the database
 */

CREATE OR REPLACE VIEW DB_FUNCTION_DDL AS
SELECT
    ROUTINESCHEMA   AS FUNCSCHEMA
,   ROUTINENAME     AS FUNCNAME
,   SPECIFICNAME
,   TEXT            AS DDL
FROM
    SYSCAT.ROUTINES
WHERE
    FUNCTIONTYPE = 'F'
