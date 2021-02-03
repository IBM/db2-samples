--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns 1 if the input string only holds characters from the ISO-8859-1 (aka Latin-1) codepage, else returns 0
 */

CREATE OR REPLACE FUNCTION DB_IS_LATIN1 ( C CLOB(2M OCTETS) ) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
    REGEXP_LIKE(C,'^[\u0000-\u007F\u00A0-\u00FF]*$')