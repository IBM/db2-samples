--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns true if a value would need the ESCAPE_CHARATER setting to allow EXTERNAL TABLE to EXPORT in text format
 * 
 * If you have a line feed in a column, you need to set ESCAPE_CHARACTER to allow it to be exported
 * If you have a Carriage return in a column, you need to set CRINSTRING YES or set ESCAPE_CHARACTER to allow it to be exported
 * If you have the word NULL (any case) or a pipe in a column, you need to set ESCAPE_CHARACTER  or change NULL_VALUE and/or DELIMITER 
 * 

 CREATE EXTERNAL TABLE '/tmp/tmp.txt' USING ( REMOTESOURCE YES ESCAPE_CHARACTER '\' DELIMITER '|' CRINSTRING YES ) 
 AS VALUES 
   ( 'line feed'     , chr(10) )  -- needs to have ESCAPE_CHARACTER set else you will get SQL20569N with Reason code 3
 , ( 'Carriage return', chr(13) )  -- needs to have ESCAPE_CHARACTER set or set CRINSTRING YES else you will get SQL20569N with Reason code 3
 , ( 'nul1 word'     , 'NULL'  )  -- needs to have ESCAPE_CHARACTER set or change the NULL_VALUE to something different else you will get SQL20569N rc3
 , ( 'pipe'          , '|'     )  -- needs to have ESCAPE_CHARACTER set or change the DELIMITER  to something different else you will get SQL20569N rc3
 , ( 'backslash'     , '\'     )  -- only gets escaped if used as the ESCAPE_CHARACTER
 , ( 'double quote'  , '"'     )  -- does not get escaped on export 
 , ( 'single quote'  , ''''    )  -- does not get escaped on export
 , ( 'zero byte'     ,  x'00'  )  -- does not get escaped on export
 , ( 'NUL1 value'    , NULL    )  -- does not get escaped on export

 * 
*/

CREATE OR REPLACE FUNCTION DB_NEEDS_ESCAPING ( c CLOB(2M OCTETS) )
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
    REGEXP_LIKE(C,'((NULL)|([\|\u000a\u000d]))',1,'i')
