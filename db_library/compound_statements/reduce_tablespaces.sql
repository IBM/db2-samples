--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Kick off a tablespace REDUCE MAX on all tablespaces with any free or pending free pages
 *  
 * Note that ALTER TABLESPACE REDUCE [MAX] is a background task.
 * 
 * You can monitor progres with the db_tablespace_reduce_progress.sql  view
 * 
 * Running many at the same time might not be ideal if you have lots of tablespaces, but might be OK
 * 
 * Not that if there are not extents to move "REDUCE MAX" incorectly skips reducing the size of the tablespace.
 *   In such a scenrio, you can run a REDUcE after the LOWER HIGH WATER MARK has completed (see db_tablespace_reduce_progress.sql)
 */

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
             'ALTER TABLESPACE "' || TBSP_NAME || '" REDUCE MAX'                AS STMT
        ,    'ALTER TABLESPACE "' || TBSP_NAME || '" LOWER HIGH WATER MARK'     AS STMT1
        ,    'ALTER TABLESPACE "' || TBSP_NAME || '" REDUCE'                    AS STMT2
        ,    SUM(TBSP_USED_PAGES)                                   AS USED_PAGES
        ,    SUM(TBSP_FREE_PAGES)                                   AS FREE_PAGES
        ,    SUM(TBSP_PENDING_FREE_PAGES)                           AS PENDING_FREE_PAGES
        ,    SUM(TBSP_PENDING_FREE_PAGES + TBSP_FREE_PAGES)         AS FREE_OR_PENDING_PAGES
        FROM    
            TABLE(MON_GET_TABLESPACE('', -2)) AS T
        WHERE
            RECLAIMABLE_SPACE_ENABLED = 1
        AND (TBSP_PENDING_FREE_PAGES + TBSP_FREE_PAGES) > 0
        AND TBSP_STATE NOT IN
            (   'SQLB_REBAL_IN_PROGRESS'
            ,   'SQLB_BACKUP_PENDING'
            ,   'SQLB_MOVE_IN_PROGRESS'
            ,   'SQLB_RESTORE_IN_PROGRESS'
            ,   'SQLB_RESTORE_PENDING'
            ,   'SQLB_RECOVERY_PENDING'
            ,   'SQLB_ROLLFORWARD_IN_PROGRESS'
            ,   'SQLB_ROLLFORWARD_PENDING'
            ,   'SQLB_REDIST_IN_PROGRESS'
            ,   'SQLB_PSTAT_DELETION'
            ,   'SQLB_PSTAT_CREATION'
            ,   'SQLB_STORDEF_PENDING'
            ,   'SQLB_DISABLE_PENDING'
            ,   'SQLB_QUIESCED_SHARE'
            ,   'SQLB_QUIESCED_UPDATE'
            ,   'SQLB_QUIESCED_EXCLUSIVE'
            )
        GROUP BY
            TBSP_NAME 
        ORDER BY
            FREE_OR_PENDING_PAGES
    DO
        EXECUTE IMMEDIATE C.STMT;
    END FOR;
END
@
