--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Activities queued for processing by Db2 Automatic maintenance
 */

CREATE OR REPLACE VIEW DB_AUTO_MAINT_QUEUE AS
SELECT * FROM(
SELECT  
        QUEUE_POSITION
/*DB_DP*/,       MEMBER
,       JOB_STATUS
,       JOB_TYPE
,       OBJECT_TYPE
,       OBJECT_NAME
,       JOB_DETAILS
FROM
      TABLE(MON_GET_AUTO_MAINT_QUEUE()) AS T
ORDER BY MEMBER, QUEUE_POSITION )SS
