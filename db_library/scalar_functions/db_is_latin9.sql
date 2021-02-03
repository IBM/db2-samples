--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns 1 if the input string only holds characters from the ISO-8859-15 (aka Latin-9) codepage, else returns 0
 * 
 */

CREATE OR REPLACE FUNCTION DB_IS_LATIN9 ( C CLOB(2M OCTETS) ) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
    REGEXP_LIKE(C,'^[\u0000-\u007F\u00A0-\u00A3\u00A5\u00A7\u00A9-\u00B3\u00B5-\u00B7\u00B9-\u00BB\u00BF-\u00FF\u20AC\u0160\0161\u017D\u017E\u0152\u0153\u0178]*$')