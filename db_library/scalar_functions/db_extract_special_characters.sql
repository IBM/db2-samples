--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows the first 4 runs of characters that are not "plain" printable 7-bit ASCII values
 */

CREATE OR REPLACE FUNCTION DB_EXTRACT_SPECIAL_CHARACTERS ( C CLOB(2M OCTETS) ) RETURNS CLOB(2M OCTETS)
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURN
             REGEXP_EXTRACT(C,'[^\u0020-\u007E\u0009\u000A\u000D]+',1,1)
||  COALESCE(REGEXP_EXTRACT(C,'[^\u0020-\u007E\u0009\u000A\u000D]+',1,2),'')
||  COALESCE(REGEXP_EXTRACT(C,'[^\u0020-\u007E\u0009\u000A\u000D]+',1,3),'')
||  COALESCE(REGEXP_EXTRACT(C,'[^\u0020-\u007E\u0009\u000A\u000D]+',1,4),'')
