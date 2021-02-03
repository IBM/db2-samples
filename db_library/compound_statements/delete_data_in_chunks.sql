--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Example of deleting X rows of data at a time from a table to avoid e.g. transaction log full on row organized tables
 * 
 */

BEGIN
    DECLARE DONE  BOOLEAN DEFAULT FALSE;  
    --
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' BEGIN SET DONE = TRUE; END;
    --
    WHILE NOT DONE
    DO
        DELETE FROM (SELECT * FROM MY_TABLE WHERE COL1 = 'A' FETCH FIRST 20000 ROWS ONLY)
        COMMIT;
    END WHILE;
END
