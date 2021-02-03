--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generate a sequence of integer values starting at 1 and going on up to 2,147,483,647
 * 
 *  There is a SMP version of this function in the smp sub folder 
 *    which uses PIPE() which is (currently) only supported on DB2 SMP servers, but can be more efficient that recursion
*/
CREATE OR REPLACE FUNCTION DB_INTEGERS (I INTEGER DEFAULT 2147483647)
    SPECIFIC DB_INTEGERS
RETURNS TABLE ("INTEGER" INTEGER)
RETURN
WITH R(II) AS (
    VALUES ( 1 )
  UNION ALL
    SELECT
        II + 1
    FROM
        R 
    WHERE 
        II <= I
)
SELECT
    II AS "INTEGER"
FROM
    R
@

ss