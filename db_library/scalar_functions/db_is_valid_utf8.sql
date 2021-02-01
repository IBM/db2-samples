--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns 1 if the input string is a valid UTF-8 encoding, otherwise returns 0.
 */

/*
    https://stackoverflow.com/questions/397250/unicode-regex-invalid-xml-characters
    
    Excludes private use area \uE000-\uFFFD
    
    Does include, e.g. <control> characters
*/
CREATE OR REPLACE FUNCTION DB_IS_VALID_UTF8 ( c CLOB(2M OCTETS) )
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
      REGEXP_LIKE(C,'^[\u0009\u000a\u000d\u0020-\uD7FF]*$')
--    REGEXP_LIKE(C,'^[\u0009\u000a\u000d\u0020-\uD7FF\uE000-\uFFFD]*$')