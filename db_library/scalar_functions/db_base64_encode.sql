--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Converts a binary value into a Base64 text string
 */

--  https://stackoverflow.com/questions/56521008/how-to-use-base64decode-function-in-db2
CREATE OR REPLACE FUNCTION DB_BASE64_ENCODE(B BLOB(2G))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS CLOB(1G OCTETS)
RETURN
    XMLCAST(XMLQUERY('$d/a' PASSING XMLDOCUMENT(XMLELEMENT(NAME "a", b)) as "d") AS CLOB(1G OCTETS))