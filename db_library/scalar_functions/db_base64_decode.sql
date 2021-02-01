--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Converts a Base64 string into a binary value
 */

-- https://stackoverflow.com/questions/56521008/how-to-use-base64decode-function-in-db2

CREATE OR REPLACE FUNCTION DB_BASE64_DECODE(C CLOB(1G OCTETS))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS BLOB(2G)
RETURN
    XMLCAST(XMLQUERY('$d/a' PASSING XMLDOCUMENT(XMLELEMENT(NAME "a", C)) AS "d") AS BLOB(2G))