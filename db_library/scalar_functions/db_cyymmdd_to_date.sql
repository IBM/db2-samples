--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns a DATE from a date integer in CYYMMDD format
 * 
 * https://stackoverflow.com/questions/63258886/how-to-convert-db2-date-to-yyymmdd-in-android
 */

CREATE OR REPLACE FUNCTION DB_CYYMMDD_TO_DATE(I INTEGER) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS DATE
RETURN
    '1899-11-30'::DATE + (I/10000) YEARS + MOD(I/100, 100) MONTHS + MOD(I, 100) DAYS
