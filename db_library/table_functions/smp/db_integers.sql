--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generate a sequence of integer values starting at 1 and going on up to 2,147,483,647
 * 
 *  This function uses PIPE() which is (currently) only supported on DB2 SMP servers
*/
CREATE OR REPLACE FUNCTION DB_INTEGERS (I INTEGER DEFAULT 2147483647)
    SPECIFIC DB_INTEGERS
RETURNS TABLE ("INTEGER" INTEGER)
BEGIN
 DECLARE II INTEGER DEFAULT 0;
 WHILE (II < I) DO
    SET II = II + 1; 
    PIPE (II);
 END WHILE; 
 RETURN;
END
