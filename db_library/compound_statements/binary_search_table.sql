--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Example binary search of a table, looking for rows that cause a SQL error
 * 
 * Sometimes you want to do a "binary search" on a table, running some SQL statements on halves of data untill some condition (stops) occuring
 * 
 * This is an example of such a method, using the HASH4 function, that looks for rows that EXTERNAL TABLE will generate an error on.
 * It is a contrived examples, as for this uses cae you could just scan the table looking for embeded new lines
 *    or other characters that ET needs the ESCAPE_CHARACTER option set for.
 * Similaraly, for e.g. character values that can't be converted to say decimal, a scan wit e.g. DB_IS_DECIMAL() would be better
 * 
 * But, *sometimes* a binary search is what you need/the only way to go. Hence this example
 * 
 */
DROP TABLE BINARY_SEARCH
@
CREATE TABLE BINARY_SEARCH (
    ITERATION   SMALLINT NOT NULL
,   HASH_FROM   BIGINT NOT NULL    
,   HASH_TO     BIGINT NOT NULL
,   HIT         SMALLINT NOT NULL
)
@


DROP TABLE ET
@
CREATE EXTERNAL TABLE ET USING (
    file_name 'null'    -- use /dev/null    if that path is allowed 
                        --      add any extra USING options here (but don't add REMOTESOURCE as that is not supported in ATMOIC statements)
)      
AS (
    SELECT * FROM your_table                            -- SELECT FROM YOUR TABLE HERE
    WHERE 1=0
)
@


BEGIN 
    DECLARE ET_ERROR CONDITION FOR SQLSTATE '428IB'; 
    DECLARE HIT INTEGER DEFAULT 0;
    DECLARE ITERATION SMALLINT DEFAULT 1;
    --
    DECLARE HASH_LOW    BIGINT DEFAULT 0;  
    DECLARE HASH_MID    BIGINT;
    DECLARE HASH_HIGH   BIGINT;
    DECLARE HASH_SIDE   CHAR(4);
    --
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN SET HIT = 1; END;
    --
    SET HASH_LOW   = 0;
    SET HASH_MID   = POWER(BIGINT(2),30)-1;
    SET HASH_HIGH  = POWER(BIGINT(2),31)-1;
    --
    WHILE HASH_MID > HASH_LOW OR HASH_LOW <  HASH_HIGH
    DO
        SET HIT = 0;
        INSERT INTO ET
        SELECT *   FROM your_table                   -- SELECT FROM YOUR TABLE HERE
        WHERE ABS(HASH4(some_column))                -- ADD A COLUMN FROM YOUR TABLE HERE. A PK OR SOMETHING ELSE WITH HIGH CARDANILITY
              BETWEEN HASH_LOW AND HASH_MID
        ;
        INSERT INTO BINARY_SEARCH VALUES ( ITERATION, HASH_LOW, HASH_MID, HIT );
        IF HIT = 1 THEN
            SET HASH_HIGH  = HASH_MID;
            SET HASH_MID   = HASH_LOW + ((HASH_HIGH - HASH_LOW) / 2);
        ELSE 
            SET HASH_LOW   = HASH_MID + 1;
            SET HASH_MID   = HASH_LOW + ((HASH_HIGH - HASH_LOW) / 2);
        END IF;
        --
        SET ITERATION = ITERATION + 1;
        COMMIT;
    END WHILE;
END
@
-- Now go find the rows that hit
SELECT ABS(HASH4(some_column)) , * FROM your_table WHERE ABS(HASH4(some_column)) 
    BETWEEN (SELECT HASH_FROM FROM BINARY_SEARCH WHERE HIT = 1 ORDER BY ITERATION DESC LIMIT 1)
    AND     (SELECT HASH_TO   FROM BINARY_SEARCH WHERE HIT = 1 ORDER BY ITERATION DESC LIMIT 1)

-- Really we need to look at the BINARY_SEARCH results recursivly, to calc the FROM/TO range that has the HIT..
--  Left as an exersize for the reader.

SELECT * FROM BINARY_SEARCH ORDER BY ITERATION DESC

-- To re-run, clear out the table
DELETE  from BINARY_SEARCH WHERE 1=1
    

    --- Test
--drop TABLE your_table
--
--CREATE TABLE your_table ( some_column int, v varchar(128) )
--
--INSERT INTO your_table select rand() * 5000000, colname from syscat.columns
--
--UPDATE (SELECT * FROM your_table WHERE RAND() > .9999) SET v = 'NULL'
--
--select * from BINARY_SEARCH order by iteration desc
