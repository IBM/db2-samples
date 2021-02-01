--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * The inverse of HEX(). Converts a a hexadecimal string into a character string
 *  
 *  See my comments on DB_BINARY_TO_CHARACTER.sql
*/
CREATE OR REPLACE FUNCTION DB_UNHEX(A VARCHAR(32672 OCTETS)) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(32672 OCTETS)
RETURN DB_BINARY_TO_CHARACTER(HEXTORAW(A))
