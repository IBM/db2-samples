--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns a DATE from a JD Edwards "Julian" date integer in CYYDDD format
 * 
 * From https://stackoverflow.com/questions/63455575/db2-can-you-write-a-function-or-macro-emedded-in-the-sql-to-simplify-a-complex
 */

CREATE OR REPLACE FUNCTION DB_CYYDDD_TO_DATE(I INTEGER) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS DATE
RETURN
    '1899-12-31'::DATE + (I/1000) YEARS + MOD(I, 1000) DAYS
