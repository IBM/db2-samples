--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns the insert range number of a row on a COLUMN organized table when passed the RID_BIT() function 
 */
CREATE OR REPLACE FUNCTION DB_INSERT_RANGE(ROWID VARCHAR (16) FOR BIT DATA) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
    ASCII(SUBSTR(ROWID, 8, 1))
