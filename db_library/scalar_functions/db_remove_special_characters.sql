--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Removes characters in a string that are not "plain" printable 7-bit ASCII values or TAB, LF and CR
 */

CREATE OR REPLACE FUNCTION DB_REMOVE_SPECIAL_CHARACTERS ( C CLOB(2M OCTETS) ) RETURNS CLOB(2M OCTETS)
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURN
    REGEXP_REPLACE(C,'[^\u0020-\u007E\u0009\u000A\u000D]+','')
