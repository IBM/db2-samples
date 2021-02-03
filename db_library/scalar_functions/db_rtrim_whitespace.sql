--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Trim trailing whitespace characters such as such No Break Space as well as Tab, New Line, Form Feed and Carriage Returns.
 * 
 * The inbuilt RTRIM() function only trims U+0020 SPACE characters (i.e. 0x20 in UTF-8 and ASCII )
 * 
 * This function is usefull if you need to match what e.g. a Java RTRIM function would do
 * 
 * It trims the set of characters that have the Unicode whitespace property or are Tab, New Line, Form Feed and Carriage Return
 *  I.e. it trims the set is defined by [\t\n\f\r\p{Z}]
 * 
 *  This is the same set that are java.lang.Character.isWhitespace()    
 *
 */

CREATE OR REPLACE FUNCTION DB_RTRIM_WHITESPACE ( C CLOB(2M OCTETS) ) RETURNS CLOB(2M OCTETS)
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURN
    REGEXP_REPLACE(C,'\s+$','')
