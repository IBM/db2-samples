--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns 1 if the input string only contains 7-bit ASCII characters, otherwise returns 0.
 */

CREATE OR REPLACE FUNCTION DB_IS_ASCII ( C CLOB(2M OCTETS) ) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
    REGEXP_LIKE(C,'^[\u0000-\u007F]*$')