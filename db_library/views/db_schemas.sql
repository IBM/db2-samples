--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all schemas in the database
 */

CREATE OR REPLACE VIEW DB_SCHEMAS AS
SELECT
    SCHEMANAME
,   DEFINER
,   CREATE_TIME
,   REMARKS
,   DESCRIPTION
FROM
    SYSCAT.SCHEMATA
LEFT JOIN
    (VALUES
     ('DB2GSE',               'IBM DB2 Geodetic Spatial Extender catalog views')
    ,('DB2INST1',             'IBM DB2 Database Instance Owner schema')
    ,('DB2OE',                'IBM DB2 Optimization Expert - Workload index advisor tables')
    ,('DB2OSC',               'IBM DB2 Optimization Service Center tables?')
    ,('DSCSTMALERT',          '')
    ,('DSJOBMGR',             'dashDB scheduling')
    ,('DSSCHED',              'dashDB scheduling')
    ,('DSSHSV1',              'dashDB internal')
    ,('DSWEB',                '')
    ,('DSWEBSECURITY',        '')
    ,('GOSALES',              'Sample tables. Originally use by Cognos for demonstrations')
    ,('GOSALESDW',            'Sample tables. Originally use by Cognos for demonstrations')
    ,('GOSALESHR',            'Sample tables. Originally use by Cognos for demonstrations')
    ,('GOSALESMR',            'Sample tables. Originally use by Cognos for demonstrations')
    ,('GOSALESRT',            'Sample tables. Originally use by Cognos for demonstrations')
    ,('HEALTHMETRICS',        '')
    ,('IBMADT',               'dashDB internal')
    ,('IBMIOCM',              '')
    ,('IBMOTS',               'dashDB internal')
    ,('IBMPDQ',               'dashDB metadata about the instance')
    ,('IBMCONSOLE',           'Db2 Managment Console tables')
    ,('IBM_DSM_VIEWS',        '')
    ,('IBM_RTMON',            '')
    ,('IBM_RTMON_BASELINE',   '')
    ,('IBM_RTMON_DATA',       '')
    ,('IBM_RTMON_EVMON',      '')
    ,('IBM_RTMON_METADATA',   '')
    ,('IDAX',                 'Db2 In Database Analytics')
    ,('NULLID',               'Db2 Package sets')
    ,('NULLIDR1',             'Db2 REOPT ONCE Package sets')
    ,('NULLIDRA',             'Db2 REOPT ALWAYS Package sets')
    ,('OPM',                  'IBM Optim Performance Manager')
    ,('OQT',                  'IBM Optim Query Workload Tuner')
    ,('PROCMGMT',             'IBM Data Server Manager')
    ,('QUERYTUNER',           'IBM Optim Query Worlkoad Tuner')
    ,('SPARKCOL',             '')
    ,('SQLJ',                 'SQLJ Packages')
    ,('ST_INFORMTN_SCHEMA',   'Geospatial extender')
    ,('SYSCAT',               'Db2 System Catalog Views')
    ,('SYSFUN',               'Db2 Alternative System Functions')
    ,('SYSIBM',               'Db2 System Catalog Tables, functions etc')
    ,('SYSIBMADM',            'Db2 Built-in monitoring functions and views')
    ,('SYSIBMINTERNAL',       'Db2 internal routines')
    ,('SYSIBMTS',             '')
    ,('SYSPROC',              'Db2 Built-in procedures')
    ,('SYSPUBLIC',            'Public aliases')
    ,('SYSSTAT',              'Db2 System Catalog Statistics Views')
    ,('SYSTOOLS',             'Used by a variety of IBM tools. Home to Explain tables and other such things')
) AS D (SCHEMANAME, DESCRIPTION )
USING
    ( SCHEMANAME )
