--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all possible WLM threshold types
 */

CREATE OR REPLACE VIEW DB_THRESHOLD_TYPES AS
SELECT
    RTRIM(THRESHOLD_TYPE)   AS THRESHOLD_TYPE
,   THRESHOLD_CATEGORY
,   QUEUING
,   THRESHOLD_DESCRIPTION
,   THRESHOLD_PREDICATE
,   DOMAINS
,   ENFORCEMENT
,   NOTES
FROM TABLE(
VALUES
 ('No','Activity','Upper bound for the amount of time the database manager allows an activity to run. The amount of time does not include the time that the activity was queued by a WLM concurrency threshold'
    ,'ACTIVITYTOTALRUNTIME          ' , '> integer-value DAY | DAYS | HOUR | HOURS | MINUTE | MINUTES | SECONDS                   ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
,('No','Activity','upper bound for the amount of time the database manager allows an activity to run.'
    ,'ACTIVITYTOTALRUNTIMEINALLSC   ' , '> integer-value DAY | DAYS | HOUR | HOURS | MINUTE | MINUTES | SECONDS                   ','SUBCLASS','MEMBER','')
,('No','Activity','upper bound for the amount of time the database manager will allow an activity to execute, including the time the activity was queued.'
    ,'ACTIVITYTOTALTIME             ' , '> integer-value DAY | DAYS | HOUR | HOURS | MINUTE | MINUTES | SECONDS                   ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
,('No','Aggregate','The maximum amount of system temporary space that can be consumed by a set of statements in a service class on a member'
    ,'AGGSQLTEMPSPACE               ' , '> integer-value K | M | G                                                                ','SUBCLASS','MEMBER','')
,('Yes','Aggregate','Upper bound on the number of recognized database coordinator activities that can run concurrently on all members in the specified domain'
    ,'CONCURRENTDBCOORDACTIVITIES   ' , '> integer-value  AND QUEUEDACTIVITIES > [0|integer-value|UNBOUNDED]                      ','DATABASE, work action, SUPERCLASS, SUBCLASS','DATABASE, MEMBER (pS only)','')
-- https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.admin.wlm.doc/doc/r0051917.html
-- A value of zero means that any new database coordinator activities will be prevented from executing.
-- CALL statements are not controlled by this threshold, but all nested child activities started within the called routine are under this threshold's control
-- User-defined functions are controlled by this threshold, but child activities nested in a user-defined function are not controlled.
-- Trigger actions that invoke CALL statements and the child activities of these CALL statements are not controlled by this threshold
,('No','Aggregate','Upper bound on the number of concurrent occurrences for the workload on each member'
    ,'CONCURRENTWORKLOADACTIVITIES  ' , '> integer-value                                                                          ','WORKLOAD','MEMBER','')
,('No','Aggregate','Upper bound on the number of concurrent coordinator activities and nested activities for the workload on each member'
    ,'CONCURRENTWORKLOADOCCURRENCES ' , '> integer-value                                                                          ','WORKLOAD','WORKLOAD OCCURRENCE','')
,('No','Connection','Upper bound for the amount of time the database manager will allow a connection to remain idle'
    ,'CONNECTIONIDLETIME            ' , '> integer-value DAY | DAYS | HOUR | HOURS | MINUTE | MINUTES                             ','DATABASE, SUPERCLASS','DATABASE','')
--If you specify the STOP EXECUTION action with CONNECTIONIDLETIME thresholds, the connection for the application is dropped when the threshold is exceeded. 
--  Any subsequent attempt by the application to access the data server will receive SQLSTATE 5U026.
,('No','Activity','Upper bound for the amount of processor time that an activity may consume during its lifetime on a particular member'
    ,'CPUTIME                       ' , '> integer-value HOUR | HOURS | MINUTE | MINUTES | SECOND | SECONDS  CHECKING EVERY integer-value SECONDS','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','MEMBER','')
,('No','Activity','Upper bound for the amount of processor time that an activity may consume on a particular member while it is executing in a particular service subclass'
    ,'CPUTIMEINSC                   ' , '> integer-value HOUR | HOURS | MINUTE | MINUTES | SECOND | SECONDS  CHECKING EVERY integer-value SECONDS','SUBCLASS','MEMBER','')
,('No','Activity','Defines one or more data tag values specified on a table space that the activity touches'
    ,'DATATAGINSC                   ' , '[NOT] IN (integer-constant, ...)                                                         ','SUBCLASS','MEMBER','')
,('No','Activity','upper bound for the optimizer-assigned cost (in timerons) of an activity'
    ,'ESTIMATEDSQLCOST              ' , '> bigint-value                                                                           ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
--a threshold for a work action definition domain is created using a CREATE WORK ACTION SET or ALTER WORK ACTION SET statement, and the work action set must be applied to a workload or a database
,('No','Activity','The maximum shared sort memory that may be requested by a query as a percentage of the total database shared sort memory (sheapthres_shr).'
    ,'SORTSHRHEAPUTIL               ' , '> integer-value PERCENT  AND BLOCKING ADMISSION FOR integer-value                        ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','Available from Db2 11.5.2.0')
,('No','Activity','Upper bound on the number of rows that may be read by an activity during its lifetime on a particular member'
    ,'SQLROWSREAD                   ' , '> bigint-value                                                                           ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
,('No','Activity','Upper bound on the number of rows that may be read by an activity on a particular member while it is executing in a service subclass'
    ,'SQLROWSREADINSC               ' , '> bigint-value  CHECKING EVERY integer-value SECOND | SECONDS                            ','SUBCLASS','MEMBER','')
,('No','Activity','Upper bound for the number of rows returned to a client application from the application server'
    ,'SQLROWSRETURNED               ' , '> integer-value                                                                          ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
,('No','Activity','The maximum amount of system temporary space that can be consumed by an SQL statement on a member'
    ,'SQLTEMPSPACE                  ' , '> integer-value K | M | G                                                                ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
,('Yes (enforced at 0)','Aggregate','Upper bound on the number of coordinator connections that can run concurrently on a member'
    ,'TOTALMEMBERCONNECTIONS        ' , '> integer-value                                                                          ','DATABASE'  ,'MEMBER','not enforced for users with DBADM or WLMADM authority.')
,('Yes','Aggregate','Upper bound on the number of coordinator connections that can run concurrently on a member in a specific service superclass'
    ,'TOTALSCMEMBERCONNECTIONS      ' , '> integer-value AND QUEUEDCONNECTIONS > [0|integer-value|UNBOUNDED]                        ','SUPERCLASS','MEMBER','') 
-- Specifies a queue size for when the maximum number of coordinator connections is exceeded.
-- Specifying UNBOUNDED will queue every connection that exceeds the specified maximum number of coordinator connections
---   and the threshold-exceeded-actions will never be executed. The default is zero.
,('No','Unit of Work','Upper bound for the amount of time the database manager will allow a unit of work to execute'
    ,'UOWTOTALTIME                  ' , '> integer-value DAY | DAYS | HOUR | HOURS | MINUTE | MINUTES | SECONDS                   ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
) AS T(QUEUING, THRESHOLD_CATEGORY, THRESHOLD_DESCRIPTION, THRESHOLD_TYPE, THRESHOLD_PREDICATE, DOMAINS, ENFORCEMENT, NOTES )
