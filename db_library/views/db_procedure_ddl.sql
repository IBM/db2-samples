--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns the CREATE PROCEDURE DDL for all stored procedures on the database
 */

CREATE OR REPLACE VIEW DB_PROCEDURE_DDL AS
SELECT
    ROUTINESCHEMA   AS PROCSCHEMA
,   ROUTINENAME     AS PROCNAME
,   SPECIFICNAME
,   TEXT            AS DDL
FROM
    SYSCAT.ROUTINES
WHERE
    ROUTINETYPE = 'P'
