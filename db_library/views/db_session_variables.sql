--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * List special registers, current application id and other session level variables
 */

CREATE OR REPLACE VIEW DB_SESSION_VARIABLES AS
SELECT * FROM (VALUES
 ( 'MONITOR ELEMENT', 'APPLICATION_HANDLE'  , CHAR((MON_GET_APPLICATION_HANDLE())   )
        , 'values MON_GET_APPLICATION_HANDLE()'
        ,'')                        
,( 'MONITOR ELEMENT', 'APPLICATION_NAME'    , (SELECT APPLICATION_NAME from table(MON_GET_CONNECTION( MON_GET_APPLICATION_HANDLE(), -1)))           
      , 'SELECT APPLICATION_NAME from table(MON_GET_CONNECTION( MON_GET_APPLICATION_HANDLE(), -1))'
      , 'jdbc:clientProgramName=<name>' )
,( 'MONITOR ELEMENT', 'WORKLOAD'
      , (SELECT WORKLOAD_NAME FROM TABLE(WLM_GET_SERVICE_CLASS_WORKLOAD_OCCURRENCES('', '', -1)) WHERE APPLICATION_HANDLE = MON_GET_APPLICATION_HANDLE())
      , 'SELECT WORKLOAD_NAME FROM TABLE(WLM_GET_SERVICE_CLASS_WORKLOAD_OCCURRENCES('''', '''', -1)) WHERE APPLICATION_HANDLE = MON_GET_APPLICATION_HANDLE()'
      , 'call WLM_SET_CLIENT_INFO(NULL, NULL, NULL, NULL, ''SYSDEFAULTADMWORKLOAD|AUTOMATIC'')')
,( 'SPECIAL REGISTER' ,'CLIENT_ACCTNG'                           ,CURRENT CLIENT_ACCTNG                           ,'values CURRENT CLIENT_ACCTNG'                          ,'CALL WLM_SET_CLIENT_INFO(NULL, NULL, NULL, ''<acctstr>'', NULL)'  )
,( 'SPECIAL REGISTER' ,'CLIENT_APPLNAME'                         ,CURRENT CLIENT_APPLNAME                         ,'values CURRENT CLIENT_APPLNAME'                        ,'CALL WLM_SET_CLIENT_INFO(NULL, NULL, ''<applname>'', NULL, NULL)' )
,( 'SPECIAL REGISTER' ,'CLIENT_USERID'                           ,CURRENT CLIENT_USERID                           ,'values CURRENT CLIENT_USERID'                          ,'CALL WLM_SET_CLIENT_INFO(''<userid>'', NULL, NULL, NULL ,NULL)'  )
,( 'SPECIAL REGISTER' ,'CLIENT_WRKSTNNAME'                       ,CURRENT CLIENT_WRKSTNNAME                       ,'values CURRENT CLIENT_WRKSTNNAME'                      ,'CALL WLM_SET_CLIENT_INFO(NULL, ''<wrkstname>'', NULL, NULL, NULL)')
,( 'SPECIAL REGISTER' ,'DATE'                                    ,CHAR(CURRENT DATE)                              ,'values CURRENT DATE'                                   ,'change the system clock time!' )
,( 'SPECIAL REGISTER' ,'DBPARTITIONNUM'                          ,CHAR(CURRENT DBPARTITIONNUM)                    ,'values CURRENT DBPARTITIONNUM'                         ,'jdbc:connectNode=<x>')               
,( 'SPECIAL REGISTER' ,'DECFLOAT ROUNDING MODE'                  ,CURRENT DECFLOAT ROUNDING MODE                  ,'values CURRENT DECFLOAT ROUNDING MODE'                  ,'CALL ADMIN_CMD(''UPDATE DB CFG USING DECFLT_ROUNDING new_value'')' )
,( 'SPECIAL REGISTER' ,'DEFAULT TRANSFORM GROUP'                 ,CURRENT DEFAULT TRANSFORM GROUP                 ,'values CURRENT DEFAULT TRANSFORM GROUP'                ,'SET CURRENT DEFAULT TRANSFORM GROUP')
,( 'SPECIAL REGISTER' ,'DEGREE'                                  ,CURRENT DEGREE                                  ,'values CURRENT DEGREE'                                 ,'SET CURRENT DEGREE')
,( 'SPECIAL REGISTER' ,'EXPLAIN MODE'                            ,CURRENT EXPLAIN MODE                            ,'values CURRENT EXPLAIN MODE'                           ,'SET CURRENT EXPLAIN MODE')
,( 'SPECIAL REGISTER' ,'EXPLAIN SNAPSHOT'                        ,CURRENT EXPLAIN SNAPSHOT                        ,'values CURRENT EXPLAIN SNAPSHOT'                       ,'SET CURRENT EXPLAIN SNAPSHOT')
,( 'SPECIAL REGISTER' ,'FEDERATED ASYNCHRONY'                    ,CHAR(CURRENT FEDERATED ASYNCHRONY)              ,'values CURRENT FEDERATED ASYNCHRONY'                   ,'SET CURRENT FEDERATED ASYNCHRONY') 
,( 'SPECIAL REGISTER' ,'IMPLICIT XMLPARSE OPTION'                ,CURRENT IMPLICIT XMLPARSE OPTION                ,'values CURRENT IMPLICIT XMLPARSE OPTION'               ,'SET CURRENT IMPLICIT XMLPARSE OPTION')
,( 'SPECIAL REGISTER' ,'ISOLATION'                               ,CURRENT ISOLATION                               ,'values CURRENT ISOLATION'                              ,'SET CURRENT ISOLATION')
,( 'SPECIAL REGISTER' ,'LOCALE LC_MESSAGES'                      ,CURRENT LOCALE LC_MESSAGES                      ,'values CURRENT LOCALE LC_MESSAGES'                     ,'SET CURRENT LOCALE LC_MESSAGES')
,( 'SPECIAL REGISTER' ,'LOCALE LC_TIME'                          ,CURRENT LOCALE LC_TIME                          ,'values CURRENT LOCALE LC_TIME'                         ,'SET CURRENT LOCALE LC_TIME')
,( 'SPECIAL REGISTER' ,'LOCK TIMEOUT'                            ,CHAR(CURRENT LOCK TIMEOUT)                      ,'values CURRENT LOCK TIMEOUT'                           ,'SET CURRENT LOCK TIMEOUT')
,( 'SPECIAL REGISTER' ,'MAINTAINED TABLE TYPES FOR OPTIMIZATION' ,CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION ,'values CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION','SET CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION')
,( 'SPECIAL REGISTER' ,'MDC ROLLOUT MODE'                        ,CURRENT MDC ROLLOUT MODE                        ,'values CURRENT MDC ROLLOUT MODE'                       ,'SET CURRENT MDC ROLLOUT MODE')
,( 'SPECIAL REGISTER' ,'MEMBER'                                  ,CHAR(CURRENT MEMBER)                            ,'values CURRENT MEMBER'                                 ,'')
,( 'SPECIAL REGISTER' ,'OPTIMIZATION PROFILE'                    ,CURRENT OPTIMIZATION PROFILE                    ,'values CURRENT OPTIMIZATION PROFILE'                   ,'SET CURRENT OPTIMIZATION PROFILE')
,( 'SPECIAL REGISTER' ,'PACKAGE PATH'                            ,CURRENT PACKAGE PATH                            ,'values CURRENT PACKAGE PATH'                           ,'SET CURRENT PACKAGE PATH')
,( 'SPECIAL REGISTER' ,'PATH'                                    ,CURRENT PATH                                    ,'values CURRENT PATH'                                   ,'SET CURRENT PATH')
,( 'SPECIAL REGISTER' ,'QUERY OPTIMIZATION'                      ,CHAR(CURRENT QUERY OPTIMIZATION)                ,'values CURRENT QUERY OPTIMIZATION'                     ,'SET CURRENT QUERY OPTIMIZATION')
,( 'SPECIAL REGISTER' ,'REFRESH AGE'                             ,CHAR(CURRENT REFRESH AGE)                       ,'values CURRENT REFRESH AGE'                            ,'SET CURRENT REFRESH AGE')
,( 'SPECIAL REGISTER' ,'SCHEMA'                                  ,CURRENT SCHEMA                                  ,'values CURRENT SCHEMA'                                 ,'SET CURRENT SCHEMA')
,( 'SPECIAL REGISTER' ,'SERVER'                                  ,CURRENT SERVER                                  ,'values CURRENT SERVER'                                 ,'')
,( 'SPECIAL REGISTER' ,'SQL_CCFLAGS'                             ,CURRENT SQL_CCFLAGS                             ,'values CURRENT SQL_CCFLAGS'                            ,'SET CURRENT SQL_CCFLAGS')
,( 'SPECIAL REGISTER' ,'TEMPORAL BUSINESS_TIME'                  ,CHAR(CURRENT TEMPORAL BUSINESS_TIME)            ,'values CURRENT TEMPORAL BUSINESS_TIME'                 ,'SET CURRENT TEMPORAL BUSINESS_TIME date_or_timestamp')
,( 'SPECIAL REGISTER' ,'TEMPORAL SYSTEM_TIME'                    ,CHAR(CURRENT TEMPORAL SYSTEM_TIME)              ,'values CURRENT TEMPORAL SYSTEM_TIME'                   ,'SET CURRENT TEMPORAL SYSTEM_TIME date_or_timestamp')
,( 'SPECIAL REGISTER' ,'TIME'                                    ,CHAR(CURRENT TIME)                              ,'values CURRENT TIME'                                   ,'change the system clock time!' )
,( 'SPECIAL REGISTER' ,'TIMESTAMP'                               ,CHAR(CURRENT TIMESTAMP)                         ,'values CURRENT TIMESTAMP'                              ,'change the system clock time!' )
,( 'SPECIAL REGISTER' ,'TIMEZONE'                                ,CHAR(CURRENT TIMEZONE)                          ,'values CURRENT TIMEZONE'                               ,'')
,( 'SPECIAL REGISTER' ,'USER'                                    ,CURRENT USER                                    ,'values CURRENT USER'                                   ,'SET SESSION AUTHORIZATION other_user')
,( 'SPECIAL REGISTER' ,'SESSION_USER'                            ,SESSION_USER                                    ,'values SESSION_USER'                                   ,'SET SESSION AUTHORIZATION other_user')
,( 'SPECIAL REGISTER' ,'SYSTEM_USER'                             ,SYSTEM_USER                                     ,'values SYSTEM_USER'                                    ,'')
,( 'VARIABLE'         ,'CLIENT_HOST          '                   ,(VALUES CLIENT_HOST              )              ,'values CLIENT_HOST           '                         ,'SET CLIENT_HOST           ') --    contains the host name of the current client, as returned by the operating system.
,( 'VARIABLE'         ,'CLIENT_IPADDR        '                   ,(VALUES CLIENT_IPADDR            )              ,'values CLIENT_IPADDR         '                         ,'SET CLIENT_IPADDR         ') --    contains the IP address of the current client, as returned by the operating system.
--,( 'VARIABLE'         ,'CLIENT_ORIGUSERID    '                   ,(VALUES CLIENT_ORIGUSERID        )              ,'values CLIENT_ORIGUSERID     '                         ,'SET CLIENT_ORIGUSERID     ') --    contains the original user identifier, as supplied by an application, usually from a multiple-tier server environment.
--,( 'VARIABLE'         ,'CLIENT_USRSECTOKEN   '                   ,(VALUES CHAR(CLIENT_USRSECTOKEN) )              ,'values CLIENT_USRSECTOKEN    '                         ,'SET CLIENT_USRSECTOKEN    ') --    contains a security token, as supplied by an application, usually from a multiple-tier server environment.
,( 'VARIABLE'         ,'MON_INTERVAL_ID      '                   ,(VALUES CHAR(MON_INTERVAL_ID)    )              ,'values MON_INTERVAL_ID       '                         ,'SET MON_INTERVAL_ID       ') --    contains the identifier for the current monitoring interval.
,( 'VARIABLE'         ,'NLS_STRING_UNITS     '                   ,(VALUES NLS_STRING_UNITS         )              ,'values NLS_STRING_UNITS      '                         ,'SET NLS_STRING_UNITS      ') --    specifies the default string units that are used when defining character and graphic data types in a Unicode database.
,( 'VARIABLE'         ,'PACKAGE_NAME         '                   ,(VALUES PACKAGE_NAME             )              ,'values PACKAGE_NAME          '                         ,'SET PACKAGE_NAME          ') --    contains the name of the currently executing package.
,( 'VARIABLE'         ,'PACKAGE_SCHEMA       '                   ,(VALUES PACKAGE_SCHEMA           )              ,'values PACKAGE_SCHEMA        '                         ,'SET PACKAGE_SCHEMA        ') --    contains the schema name of the currently executing package.
,( 'VARIABLE'         ,'PACKAGE_VERSION      '                   ,(VALUES CHAR(PACKAGE_VERSION)    )              ,'values PACKAGE_VERSION       '                         ,'SET PACKAGE_VERSION       ') --    contains the version identifier of the currently executing package.
,( 'VARIABLE'         ,'ROUTINE_MODULE       '                   ,(VALUES ROUTINE_MODULE           )              ,'values ROUTINE_MODULE        '                         ,'SET ROUTINE_MODULE        ') --    contains the module name of the currently executing routine.
,( 'VARIABLE'         ,'ROUTINE_SCHEMA       '                   ,(VALUES ROUTINE_SCHEMA           )              ,'values ROUTINE_SCHEMA        '                         ,'SET ROUTINE_SCHEMA        ') --    contains the schema name of the currently executing routine.
,( 'VARIABLE'         ,'ROUTINE_SPECIFIC_NAME'                   ,(VALUES ROUTINE_SPECIFIC_NAME    )              ,'values ROUTINE_SPECIFIC_NAME '                         ,'SET ROUTINE_SPECIFIC_NAME ') --    contains the specific name of the currently executing routine.
,( 'VARIABLE'         ,'ROUTINE_TYPE         '                   ,(VALUES ROUTINE_TYPE             )              ,'values ROUTINE_TYPE          '                         ,'SET ROUTINE_TYPE          ') --    contains the type of the currently executing routine.
,( 'VARIABLE'         ,'SQL_COMPAT           '                   ,(VALUES SQL_COMPAT               )              ,'values SQL_COMPAT            '                         ,'SET SQL_COMPAT            ') --    specifies the SQL compatibility mode. Its value determines which set of syntax rules are applied to SQL queries.
,( 'VARIABLE'         ,'TRUSTED_CONTEXT      '                   ,(VALUES TRUSTED_CONTEXT          )              ,'values TRUSTED_CONTEXT       '                         ,'SET TRUSTED_CONTEXT       ') --    contains the name of the trusted context that was matched to establish the current trusted connection.
,( 'SCALAR FUNCTION'  ,'INSTANCE_AUTHID'                         ,(VALUES AUTH_GET_INSTANCE_AUTHID())             ,'values AUTH_GET_INSTANCE_AUTHID()'                     ,'')
) x(TYPE, NAME, CURRENT_VALUE, SQL_TO_GET, SQL_TO_SET)
