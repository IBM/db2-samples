--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/* 
 * A sample procedure to allow users to cancel their own statements
 * 
 * Needed because, Db2 does not allow a user to cancel their own statements otherwise
 * 
 * This is maybe usefull in an environemnt where you are sharing userids,
 *   but is anoying when you have a good security regiem, but client application that can "leave statements running" without a clear way to cancel them
 *
 * 
 * Credit to Paul Bird for this code   https://www.idug.org/p/bl/et/blogaid=557
 */

CREATE OR REPLACE PROCEDURE DB_CANCEL_MY_ACTIVITY 
(   
    IN APPHANDLE  BIGINT
,   IN UOWID      BIGINT
,   IN ACTIVITYID BIGINT
)
         SPECIFIC DB_CANCEL_MY_ACTIVITY
LANGUAGE SQL
BEGIN
    DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
    DECLARE ERRMSG VARCHAR(1024);
    DECLARE ACTCOUNT BIGINT DEFAULT 0;
    DECLARE C1 CURSOR FOR (
        SELECT
            COUNT(*)
        FROM
            TABLE(SYSPROC.WLM_GET_WORKLOAD_OCCURRENCE_ACTIVITIES    ( NULL, -2 ))     AS A
        ,   TABLE(SYSPROC.WLM_GET_SERVICE_CLASS_WORKLOAD_OCCURRENCES( NULL, NULL,-2)) AS B
        WHERE
            A.APPLICATION_HANDLE = B.APPLICATION_HANDLE 
        AND A.ACTIVITY_ID        = B.WORKLOAD_OCCURRENCE_ID 
        AND A.UOW_ID             = B.UOW_ID 
        AND A.DBPARTITIONNUM     = B.DBPARTITIONNUM 
        AND B.SESSION_AUTH_ID    = SESSION_USER)
        ; 
    OPEN C1; 
    FETCH C1 INTO ACTCOUNT;  
    IF (ACTCOUNT > 0) 
    THEN
        CALL WLM_CANCEL_ACTIVITY( APPHANDLE, UOWID, ACTIVITYID ); 
    ELSE
        SET ERRMSG = 'Activity not found for current session user: ' || SESSION_USER; 
        SIGNAL SQLSTATE '70001' SET MESSAGE_TEXT = ERRMSG; 
    END IF; 
END

GRANT EXECUTE ON PROCEDURE DB_CANCEL_MY_ACTIVITY TO PUBLIC         
@
