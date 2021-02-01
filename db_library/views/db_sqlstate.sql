--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Use to lookup the full description of an SQLSTATE error message
 */

CREATE OR REPLACE VIEW DB_SQLSTATE AS
WITH T(I) AS (VALUES(0) UNION ALL SELECT I + 1 FROM T WHERE I <= 59999)
SELECT * FROM
(
    SELECT
        I AS SQLSTATE
    ,   DB_SQLERRM ( RIGHT(DIGITS(I),5) , '', '', 'EN_US', 1)     AS SHORT_MESSAGE
    ,   DB_SQLERRM ( RIGHT(DIGITS(I),5) , '', '', 'EN_US', 0)     AS FULL_MESSAGE
    FROM T
)
WHERE
    SHORT_MESSAGE IS NOT NULL
