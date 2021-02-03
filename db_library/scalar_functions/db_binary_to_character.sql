--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Converts a BINARY value to a character string. I.e. removes the FOR BIT DATA tag from a binary string
 */

/*
 "Remove" the FOR BIT DATA tag on a binary string.
 
 Credit https://stackoverflow.com/questions/7913300/convert-hex-value-to-char-on-db2/42371427#42371427
 
 Not sure why it works!  It needs to be within an ATOMIC compound statement, and does not work with a simple return

 Useful because both
 
     values 'K'::VARBINARY::VARCHAR
 and 
     values BX'4B'::VARCHAR
 
 return the following error
 
    ‪A‬‎ ‪value‬‎ ‪with‬‎ ‪data‬‎ ‪type‬‎ ‪‬‎"‪SYSIBM.VARBINARY"‬‎ ‪cannot‬‎ ‪be‬‎ ‪CAST‬‎ ‪to‬‎ ‪type‬‎ ‪‬‎"‪SYSIBM.VARCHAR"‬‎.‪‬‎.‪‬‎ ‪SQLCODE‬‎=‪‬‎-‪461‬‎,‪‬‎ ‪SQLSTATE‬‎=‪42846‬‎,‪‬‎ ‪DRIVER‬‎=‪4‬‎.‪26‬‎.‪14

  BTW on Db2 11.5 you can use the inbuilt UTIL_RAW module instead
 
    E.g.  VALUES SYSIBMADM.UTL_RAW.CAST_TO_VARCHAR2( your_varchar_for_bit_data_column::VARBINARY)
 
*/

CREATE OR REPLACE FUNCTION DB_BINARY_TO_CHARACTER(A VARCHAR(32672 OCTETS) FOR BIT DATA) RETURNS VARCHAR(32672 OCTETS)
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN ATOMIC
    RETURN A;
END