--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows the total used and available size of the storage paths available to the database
 */

CREATE OR REPLACE VIEW DB_STORAGE AS
/*
 *  This view can't tell if the storage paths point to a shared or didicated filesystem for each database partition
 *   Currenly we just remove temp storage groups as a poot attempt to work-around that issue
 */
SELECT
    STORAGE_GROUP_NAME
,   DB_STORAGE_PATH
,   CASE WHEN DBPARTITIONNUM = 0 THEN 'NP' ELSE 'P' END PART
,   ROUND(SUM(FS_TOTAL_SIZE)       / power(1024.0,3),0)  AS SIZE_GB
,   ROUND(SUM(FS_USED_SIZE)        / power(1024.0,3),0)  AS USED_GB
,   ROUND(SUM(STO_PATH_FREE_SIZE)  / power(1024.0,3),0)  AS FREE_GB
,   ROUND((SUM(FS_USED_SIZE) / SUM(FS_TOTAL_SIZE)::DECFLOAT) * 100,2)  AS PCT_FULL
,   CASE WHEN COUNT(*) > 1 THEN DECIMAL((1 - NULLIF(AVG(DECFLOAT(FS_TOTAL_SIZE)),0)/ NULLIF(MAX(DECFLOAT(FS_TOTAL_SIZE)),0))*100,5,2) END   AS SIZE_SKEW
,   CASE WHEN COUNT(*) > 1 THEN DECIMAL((1 - NULLIF(AVG(DECFLOAT(FS_USED_SIZE )),0)/ NULLIF(MAX(DECFLOAT(FS_USED_SIZE )),0))*100,5,2) END   AS USED_SKEW
FROM TABLE(ADMIN_GET_STORAGE_PATHS(NULL,-2)) AS T
WHERE
    STORAGE_GROUP_NAME NOT LIKE '%TEMP%'
GROUP BY
    STORAGE_GROUP_NAME
,   DB_STORAGE_PATH
,   CASE WHEN DBPARTITIONNUM = 0 THEN 'NP' ELSE 'P' END
