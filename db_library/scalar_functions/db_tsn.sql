--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns the tuple sequence number of a row on a COLUMN organized table when passed the RID_BIT() function
 * 
 * Since Db2 11.5.3 you can use the RID() function on a column organised table to return the tuple sequence number
 *   so this function is not needed from that level onwards
 */
CREATE OR REPLACE FUNCTION DB_TSN(RID_BIT VARCHAR (16) FOR BIT DATA) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS BIGINT
RETURN
            ASCII(SUBSTR(RID_BIT, 5, 1))*4294967296 +
            ASCII(SUBSTR(RID_BIT, 4, 1))*16777216 +
            ASCII(SUBSTR(RID_BIT, 3, 1))*65536 +
            ASCII(SUBSTR(RID_BIT, 2, 1))*256 +
            ASCII(SUBSTR(RID_BIT, 1, 1))
