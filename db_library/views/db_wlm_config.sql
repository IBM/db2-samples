--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Provides a denormalized view of your WLM configuration
 * 
 * Note that this code makes various assumptions about how your WLM configuration is structured
 *   and only shows certain apsects.
 * Please do customise as you need to fully catpure your particualar usages of WLM
 */


CREATE OR REPLACE VIEW DB_WLM_CONFIG AS
SELECT
    COALESCE(S.PARENTSERVICECLASSNAME || ' -> ' ,'') || S.SERVICECLASSNAME      AS OBJECT
,   S.PREFETCHPRIORITY     AS PREFETCH
,   S.OUTBOUNDCORRELATOR   AS OB_CORRELATOR 
,   W.CONNECTION_ATTRIBUTES
,   T.THRESHOLDS
,   WA.WORKCLASSNAME
,   WA.WORK_ACTIONS
--,   CASE WORKLOADTYPE WHEN 1 THEN 'CUSTOM' WHEN 2 THEN 'MIXED' WHEN 3 THEN 'INTERACTIVE' WHEN 4 THEN 'BATCH' ELSE '' END AS WORKLOADTYPE
FROM
    SYSCAT.SERVICECLASSES S
LEFT JOIN
(
    SELECT
        PARENTSERVICECLASSNAME
    ,   SERVICECLASSNAME
    ,   LISTAGG(RTRIM(CONNATTRTYPE) || ' (' || CONNATTRVALUES || ')',CHR(10))
            WITHIN GROUP( ORDER BY CONNATTRTYPE)  AS CONNECTION_ATTRIBUTES
    FROM
    (    SELECT
            PARENTSERVICECLASSNAME
        ,   SERVICECLASSNAME
        ,   CONNATTRTYPE
        ,   LISTAGG(RTRIM(CONNATTRVALUE),', ')
                WITHIN GROUP( ORDER BY CONNATTRVALUE)  AS CONNATTRVALUES
        FROM    
            (   SELECT
                    PARENTSERVICECLASSNAME
                ,   SERVICECLASSNAME
                ,   CONNATTRTYPE
                ,   CONNATTRVALUE
                FROM
                    SYSCAT.WORKLOADS W
                JOIN
                    SYSCAT.WORKLOADCONNATTR
                USING
                    (   WORKLOADID  )
                WHERE
                    ENABLED = 'Y'
             )
         GROUP BY
             PARENTSERVICECLASSNAME
         ,   SERVICECLASSNAME
         ,   CONNATTRTYPE
         )
    GROUP BY
        PARENTSERVICECLASSNAME
    ,   SERVICECLASSNAME
) W
ON S.SERVICECLASSNAME = W.SERVICECLASSNAME
AND ( S.PARENTSERVICECLASSNAME = W.PARENTSERVICECLASSNAME OR (S.PARENTSERVICECLASSNAME IS NULL AND W.PARENTSERVICECLASSNAME IS NULL))
LEFT JOIN
-- Threshholds
(
    SELECT
        SERVICECLASSID
    ,   LISTAGG(/*THRESHOLDNAME || ' : ' || */RULE || ' -> ' || RTRIM(ACTION)
            || CASE WHEN ENABLED = 'N' THEN ' (disabled)' ELSE '' END
        , CHR(10)) WITHIN GROUP( ORDER BY THRESHOLDNAME, MAXVALUE )  AS THRESHOLDS
    FROM
    (
        SELECT 
            DOMAINID            AS SERVICECLASSID
        ,   THRESHOLDNAME
        ,   THRESHOLDPREDICATE || ' > ' || MAXVALUE AS RULE
        ,   CASE EXECUTION WHEN 'R' THEN 'Remap' WHEN 'S' THEN 'Stop' WHEN 'C' THEN 'Continue' WHEN 'F' THEN 'Force off' ELSE EXECUTION END AS ACTION 
        ,   VIOLATIONRECORDLOGGED AS LOG
        ,   ENABLED
        ,   CASE ENFORCEMENT WHEN 'D' THEN 'Database' WHEN 'P' THEN 'Partition' WHEN 'W' THEN 'Workload occurrence' END AS ENFORCEMENT
        ,   MAXVALUE
        FROM 
            SYSCAT.THRESHOLDS
        WHERE
            DOMAIN IN ( 'SP', 'SB' )
        --AND ENABLED = 'Y' 
    )
    GROUP BY
        SERVICECLASSID
) T
USING ( SERVICECLASSID )
LEFT JOIN
-- Work Actions
(   SELECT
        SERVICECLASSID
    ,   WORKCLASSNAME
    ,   LISTAGG(CASE "TYPE" WHEN 'WORK TYPE' THEN 
            CASE VALUE1 WHEN 1 THEN 'ALL' WHEN 2 THEN 'READ' WHEN 3 THEN 'WRITE' WHEN 4 THEN 'CALL' WHEN 5 THEN 'DML' WHEN 6 THEN 'DDL' WHEN 7 THEN 'LOAD' ELSE '?' END
                ELSE "TYPE" || VALUE1 || COALESCE(' - ' || VALUE2,'') END
        , CHR(10) ) 
            WITHIN GROUP( ORDER BY TYPE DESC )  AS WORK_ACTIONS
    FROM
    (
        SELECT
            WC.WORKCLASSNAME
        ,   WCA.WORKCLASSSETNAME
        ,   WA.ACTIONSETNAME
        ,   "TYPE"
        ,   DECFLOAT(VALUE1)    VALUE1
        ,   CASE WHEN VALUE2 > 8e36 THEN INFINITY ELSE DECFLOAT(VALUE2) END VALUE2
        ,   VALUE3
        ,   EVALUATIONORDER
        ,   ACTIONNAME
        ,   ACTIONID
        ,   ACTIONTYPE
        ,   COALESCE(REFOBJECTID, OBJECTID)     AS SERVICECLASSID
        ,   REFOBJECTTYPE
        ,   SECTIONACTUALSOPTIONS
        ,   OBJECTTYPE
        ,   OBJECTNAME
        FROM SYSCAT.WORKCLASSATTRIBUTES WCA
        JOIN SYSCAT.WORKCLASSES         WC  USING ( WORKCLASSID, WORKCLASSSETID )
        JOIN SYSCAT.WORKCLASSSETS       WCS USING (              WORKCLASSSETID ) 
        JOIN SYSCAT.WORKACTIONS         WA  USING ( WORKCLASSID                 )
        JOIN SYSCAT.WORKACTIONSETS      WAS USING (              WORKCLASSSETID )
        WHERE
            WA.ENABLED = 'Y'
        AND WAS.ENABLED = 'Y'
        AND WAS.OBJECTTYPE = 'b'  -- Link at Work Object Set level to Service Super Class
    )
    GROUP BY
        SERVICECLASSID
    ,   WORKCLASSNAME
) WA
USING ( SERVICECLASSID )
WHERE
    S.SERVICECLASSNAME <> 'SYSDEFAULTSUBCLASS'
-- Now include Database level thresholds
UNION ALL
SELECT 
--    THRESHOLDNAME   AS OBJECT
    'Database Threasholds' AS OBJECT
,   ''      AS PREFETCH
,   ''      AS OB_CORRELATOR 
,   ''      AS CONNECTION_ATTRIBUTES
,   THRESHOLDS
,   ''      AS WORKCLASSNAME
,   ''      AS WORK_ACTIONS
FROM
(   SELECT
--        THRESHOLDNAME
        LISTAGG(/*THRESHOLDNAME || ' : ' || */RULE || ' -> ' || ACTION, CHR(10)) WITHIN GROUP( ORDER BY MAXVALUE )  AS THRESHOLDS
    FROM
    (
        SELECT 
            THRESHOLDNAME
        ,   THRESHOLDPREDICATE || ' > ' || MAXVALUE AS RULE
        ,   CASE EXECUTION WHEN 'R' THEN 'Remap' WHEN 'S' THEN 'Stop' WHEN 'C' THEN 'Continue' WHEN 'F' THEN 'Force off' ELSE EXECUTION END AS ACTION 
        ,   VIOLATIONRECORDLOGGED AS LOG
        ,   ENABLED
        ,   CASE ENFORCEMENT WHEN 'D' THEN 'Database' WHEN 'P' THEN 'Partition' WHEN 'W' THEN 'Workload occurrence' END AS ENFORCEMENT
        ,   MAXVALUE
        FROM 
            SYSCAT.THRESHOLDS
        WHERE
            DOMAIN = 'DB'
        AND ENABLED = 'Y'
    )
--    GROUP BY
--        THRESHOLDNAME
)
--ORDER BY 1
