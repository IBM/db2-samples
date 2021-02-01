--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns SQL that can select the locked row corresponding to a passed row LOCK_NAME
 * 
 * Based on the "Have lock, seek row: A handy function to retrieve a row, given a lock" article by Serge Rielau
 *  which used to be hosted here https://www.ibm.com/developerworks/community/blogs/SQLTips4DB2LUW/entry/lock2row?lang=en
 *  but is now avaialbe here 
 *    https://community.ibm.com/community/user/hybriddatamanagement/viewdocument/have-lock-seek-row-a-handy-functi?CommunityKey=ea909850-39ea-4ac4-9512-8e2eb37ea09a&tab=librarydocuments&LibraryFolderKey=44bf3d32-40ec-406b-ba6e-797935f128a1&DefaultView=folder 
 *  from the SQL Tips archive here
 *   https://community.ibm.com/community/user/hybriddatamanagement/communities/community-home/all-news?communitykey=ea909850-39ea-4ac4-9512-8e2eb37ea09a&tab=librarydocuments
 * 
 */

CREATE OR REPLACE FUNCTION DB_LOCK_NAME_TO_SELECT(LOCK_NAME VARCHAR(32)) 
    CONTAINS SQL --ALLOW PARALLEL
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(512)
RETURN 
SELECT
    'SELECT * FROM "' || F.TABSCHEMA  || '"."' || F.TABNAME || '" AS T'
    || ' WHERE RID(T) = ' || COALESCE(F.RID,F.TSNID)
    || ' AND DATASLICEID = '  || F.DATA_PARTITION_ID
    ||' WITH UR'
FROM    
    (SELECT
             MAX(CASE WHEN NAME = 'DATA_PARTITION_ID' THEN BIGINT(VALUE) ELSE 0 END) * power(bigint(2),48)
           + MAX(CASE WHEN NAME = 'PAGEID'            THEN BIGINT(VALUE) ELSE 0 END) * power(bigint(2),16) 
           + MAX(CASE WHEN NAME = 'ROWID'             THEN BIGINT(VALUE) END)   AS RID
    ,   MAX(CASE WHEN NAME = 'DATA_PARTITION_ID' THEN INT(VALUE) ELSE 0 END)    AS DATA_PARTITION_ID
    ,   MAX(CASE WHEN NAME = 'TABSCHEMA' THEN RTRIM(VALUE) ELSE '' END)         AS TABSCHEMA
    ,   MAX(CASE WHEN NAME = 'TABNAME'   THEN       VALUE  ELSE '' END)         AS TABNAME
    ,   MAX(CASE WHEN NAME = 'TBSP_NAME' THEN       VALUE  ELSE '' END)         AS TBSP_NAME
    ,   MAX(CASE WHEN NAME = 'TSNID'     THEN BIGINT(VALUE)  ELSE -1 END)       AS TSNID
    FROM
        TABLE(MON_FORMAT_LOCK_NAME(LOCK_NAME)) F
    ) F
