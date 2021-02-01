--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Db2 diag.log records with some arguably uninteresting records filtered out
 *
 * It is debatable what you should filter out when looking at the diag log
 *
 * What is below is only one persons view, from one engagement
 */
CREATE OR REPLACE VIEW DB_DIAG_FILTERED AS
SELECT * FROM DB_DIAG
WHERE  LEVEL <> 'I'
AND    RECTYPE IN ('DX' )
AND    FULLREC NOT LIKE '%Started archive for log file %'
AND    FULLREC NOT LIKE '%Client Information for lock escalation not available on non-coordinator node%'
AND    FULLREC NOT LIKE '%Extent Movement started on table space%'
AND    FULLREC NOT LIKE '%Performance metrics for extent movement%'
AND    FULLREC NOT LIKE '%The extent movement operation has moved all extents it could.%'
AND    FULLREC NOT LIKE '%TClear pool state EM_STARTED%'
AND    FULLREC NOT LIKE '%Started retrieve for log file%' 
AND    FULLREC NOT LIKE '%FUNCTION: DB2 UDB, database utilities, sqlubMWWarn,%'
AND    FULLREC NOT LIKE '%ABP_SUSPEND_TASK_PRO%'
AND    FULLREC NOT LIKE '%ABP_DELETE_TASK_PRO%'
AND    FULLREC NOT LIKE '%DIA8003C The interrupt  has been received.%'
AND    FULLREC NOT LIKE '%DSQLCA has already been built%'
AND    FULLREC NOT LIKE '%DIA8003C The interrupt  has been received%'
AND    FULLREC NOT LIKE '%ABP_SUSPEND_TASK_PRO%'  --Suspend the task processor%'
AND    FULLREC NOT LIKE '%Reorg Indexes Rolled Back%' 
AND    FULLREC NOT LIKE '%sqlrreorg_indexes%'
AND    FULLREC NOT LIKE '%FCM Automatic/Dynamic Resource Adjustment%' 
AND    FULLREC NOT LIKE '%db2HmonEvalReorg%'
AND    (    MSG IS NULL 
        OR 
        (   MSG NOT LIKE 'ADM4000W  A catalog cache overflow condition has occurred%'
        AND MSG NOT LIKE 'ADM1843I  Started retrieve for log file%'
        AND MSG NOT LIKE 'ADM1844I  Started archive for log file%'
        AND MSG NOT LIKE 'ADM1845I  Completed retrieve for log file%'
        AND MSG NOT LIKE 'ADM1846I  Completed archive for log file%'
        AND MSG NOT LIKE 'ADM5501I  The database manager is performing lock escalation%'
        AND MSG NOT LIKE 'ADM5502W  The escalation of %'  -- "nnnn" locks on table
        AND MSG NOT LIKE 'ADM9504W  Index reorganization on table%' 
        AND MSG NOT LIKE 'ADM6075W  The database has been placed in the WRITE SUSPENDED state.%'
        AND MSG NOT LIKE 'ADM6076W  The database is no longer in the WRITE SUSPEND state. %'
        AND MSG NOT LIKE 'ADM6008I  Extents within the following table space have been updated%'
        AND MSG NOT LIKE '%SQLCA has already been built%'
        AND MSG NOT LIKE '%DIA8050E Event monitor already active or inactive%'
        )
    )
