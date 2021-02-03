--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Add multiple range partitions in one statement
 * 
 * Db2 does not allow you to use e.g. EVERY x DAYS when ALTERing a range partition table to add new ranges
 * 
 * This is an example of using a compound statement to add multiple range partitions to the following table
 * 
 *   CREATE TABLE RP(i INT, d DATE) ORGANIZE BY ROW PARTITION BY RANGE ( d ) ( STARTING FROM '2020-11-01' ENDING AT '2021-01-01'  EXCLUSIVE EVERY  1 DAYS )
 * 
 */
BEGIN 
    DECLARE D DATE DEFAULT '2021-01-01';
    --
    WHILE D < '2021-02-01'
    DO
        EXECUTE IMMEDIATE 'ALTER TABLE RP ADD PARTITION ENDING(''' || D || ''')' ;
        SET D = D + 1 DAY;
    END WHILE;
END
@
