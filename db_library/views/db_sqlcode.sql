--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Use to lookup the full description of an SQLCODE error message
 */

CREATE OR REPLACE VIEW DB_SQLCODE AS
WITH T(I) AS (VALUES(1) UNION ALL SELECT I + 1 FROM T WHERE I <= 32766)
SELECT * FROM
(
    SELECT
         I AS SQLCODE
    ,   DB_SQLERRM ('SQL' || I || 'N', '', '', 'EN_US', 1)     AS SHORT_MESSAGE
    ,   DB_SQLERRM ('SQL' || I || 'N', '', '', 'EN_US', 0)     AS FULL_MESSAGE
    ,   REGEXP_REPLACE(SYSPROC.SQLERRM ('SQL' || I || 'N', '', '', 'EN_US', 0),'([\w\"]+)[ \t\f]*[\n\r][ \t\f]*([\w\"]+)','\1 \2') AS FULL_MESSAGE_NO_WORD_WRAP
    FROM T
)
WHERE
    SHORT_MESSAGE IS NOT NULL
