--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all objects in the catalog. Tables, Columns, Indexes etc. Essentially a UNION of all the SYSCAT catalog views
 */

CREATE OR REPLACE VIEW DB_OBJECTS 
         (       CATALOG_VIEW                  ,OBJECT_PARENT               ,OBJECT_NAME             ,SPECIFIC_NAME           ,OBJECT_TYPE       ,CREATE_DATETIME           ,MODIFY_DATETIME )
AS
          SELECT 'ATTRIBUTES'                  ,TYPESCHEMA                  ,TYPEMODULENAME          ,''                      ,TYPEMODULENAME    ,CAST(NULL AS TIMESTAMP(0)),CAST(NULL AS TIMESTAMP(0)) FROM SYSCAT.ATTRIBUTES
UNION ALL SELECT 'AUDITPOLICIES'               ,''                          ,AUDITPOLICYNAME         ,''                      ,ERRORTYPE         ,CREATE_TIME       ,NULL               FROM SYSCAT.AUDITPOLICIES
UNION ALL SELECT 'BUFFERPOOLS'                 ,''                          ,BPNAME                  ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.BUFFERPOOLS
UNION ALL SELECT 'CASTFUNCTIONS'               ,FROM_TYPESCHEMA             ,FROM_TYPEMODULENAME     ,SPECIFICNAME            ,FROM_TYPESCHEMA   ,NULL              ,NULL               FROM SYSCAT.CASTFUNCTIONS
UNION ALL SELECT 'CHECKS'                      ,TABSCHEMA                   ,CONSTNAME               ,''                      ,TYPE              ,CREATE_TIME       ,NULL               FROM SYSCAT.CHECKS
UNION ALL SELECT 'COLCHECKS'                   ,TABSCHEMA                   ,CONSTNAME               ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLCHECKS
UNION ALL SELECT 'COLGROUPCOLS'                ,TABSCHEMA                   ,TABNAME || '.' || COLNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLGROUPCOLS
UNION ALL SELECT 'COLGROUPDISTCOUNTS'          ,''                          ,''                      ,''                      ,TYPE              ,NULL              ,NULL               FROM SYSCAT.COLGROUPDISTCOUNTS
UNION ALL SELECT 'COLGROUPS'                   ,COLGROUPSCHEMA              ,COLGROUPNAME            ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLGROUPS
UNION ALL SELECT 'COLIDENTATTRIBUTES'          ,TABSCHEMA                   ,TABNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLIDENTATTRIBUTES
UNION ALL SELECT 'COLLATIONS'                  ,COLLATIONSCHEMA             ,COLLATIONNAME           ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLLATIONS
UNION ALL SELECT 'COLOPTIONS'                  ,TABSCHEMA                   ,TABNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLOPTIONS
UNION ALL SELECT 'COLUMNS'                     ,RTRIM(TABSCHEMA) || '.' ||TABNAME        ,COLNAME                 ,''                      ,TYPENAME          ,NULL              ,NULL               FROM SYSCAT.COLUMNS
UNION ALL SELECT 'CONDITIONS'                  ,CONDSCHEMA                  ,CONDMODULENAME          ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.CONDITIONS
UNION ALL SELECT 'CONTEXTATTRIBUTES'           ,''                          ,CONTEXTNAME             ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.CONTEXTATTRIBUTES
UNION ALL SELECT 'CONTEXTS'                    ,''                          ,CONTEXTNAME             ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.CONTEXTS
UNION ALL SELECT 'CONTROLS'                    ,CONTROLSCHEMA               ,CONTROLNAME             ,''                      ,CONTROLTYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.CONTROLS
UNION ALL SELECT 'DATAPARTITIONEXPRESSION'     ,TABSCHEMA                   ,TABNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.DATAPARTITIONEXPRESSION
UNION ALL SELECT 'DATAPARTITIONS'              ,TABSCHEMA                   ,DATAPARTITIONNAME       ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.DATAPARTITIONS
UNION ALL SELECT 'DATATYPES'                   ,TYPESCHEMA                  ,TYPEMODULENAME          ,''                      ,TYPEMODULENAME    ,CREATE_TIME       ,NULL               FROM SYSCAT.DATATYPES
UNION ALL SELECT 'DBPARTITIONGROUPDEF'         ,''                          ,DBPGNAME                ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.DBPARTITIONGROUPDEF
UNION ALL SELECT 'DBPARTITIONGROUPS'           ,''                          ,DBPGNAME                ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.DBPARTITIONGROUPS
UNION ALL SELECT 'EVENTMONITORS'               ,''                          ,EVMONNAME               ,''                      ,TARGET_TYPE       ,NULL              ,NULL               FROM SYSCAT.EVENTMONITORS
UNION ALL SELECT 'EVENTS'                      ,''                          ,EVMONNAME               ,''                      ,TYPE              ,NULL              ,NULL               FROM SYSCAT.EVENTS
UNION ALL SELECT 'EVENTTABLES'                 ,TABSCHEMA                   ,EVMONNAME               ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.EVENTTABLES
UNION ALL SELECT 'FULLHIERARCHIES'             ,SUB_SCHEMA                  ,SUB_NAME                ,''                      ,METATYPE          ,NULL              ,NULL               FROM SYSCAT.FULLHIERARCHIES
UNION ALL SELECT 'FUNCMAPPINGS'                ,FUNCSCHEMA                  ,FUNCNAME                ,SPECIFICNAME            ,SERVERTYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.FUNCMAPPINGS
UNION ALL SELECT 'FUNCPARMS'                   ,FUNCSCHEMA                  ,FUNCNAME                ,SPECIFICNAME            ,ROWTYPE           ,NULL              ,NULL               FROM SYSCAT.FUNCPARMS
UNION ALL SELECT 'FUNCTIONS'                   ,FUNCSCHEMA                  ,FUNCNAME                ,SPECIFICNAME            ,CHAR(RETURN_TYPE) ,CREATE_TIME       ,NULL               FROM SYSCAT.FUNCTIONS
UNION ALL SELECT 'HIERARCHIES'                 ,SUB_SCHEMA                  ,SUB_NAME                ,''                      ,METATYPE          ,NULL              ,NULL               FROM SYSCAT.HIERARCHIES
UNION ALL SELECT 'HISTOGRAMTEMPLATEBINS'       ,''                          ,TEMPLATENAME            ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.HISTOGRAMTEMPLATEBINS
UNION ALL SELECT 'HISTOGRAMTEMPLATES'          ,''                          ,TEMPLATENAME            ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.HISTOGRAMTEMPLATES
UNION ALL SELECT 'INDEXES'                     ,INDSCHEMA                   ,INDNAME                 ,''                      ,INDEXTYPE         ,CREATE_TIME       ,NULL               FROM SYSCAT.INDEXES
UNION ALL SELECT 'INDEXEXPLOITRULES'           ,IESCHEMA                    ,IENAME                  ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.INDEXEXPLOITRULES
UNION ALL SELECT 'INDEXEXTENSIONMETHODS'       ,IESCHEMA                    ,METHODNAME              ,RANGESPECIFICNAME       ,''                ,NULL              ,NULL               FROM SYSCAT.INDEXEXTENSIONMETHODS
UNION ALL SELECT 'INDEXEXTENSIONPARMS'         ,IESCHEMA                    ,IENAME                  ,''                      ,TYPENAME          ,NULL              ,NULL               FROM SYSCAT.INDEXEXTENSIONPARMS
UNION ALL SELECT 'INDEXEXTENSIONS'             ,IESCHEMA                    ,IENAME                  ,KEYGENSPECIFICNAME      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.INDEXEXTENSIONS
UNION ALL SELECT 'INDEXOPTIONS'                ,INDSCHEMA                   ,INDNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.INDEXOPTIONS
UNION ALL SELECT 'INDEXPARTITIONS'             ,INDSCHEMA                   ,INDNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.INDEXPARTITIONS
UNION ALL SELECT 'INDEXXMLPATTERNS'            ,INDSCHEMA                   ,INDNAME                 ,''                      ,TYPEMODEL         ,NULL              ,NULL               FROM SYSCAT.INDEXXMLPATTERNS
UNION ALL SELECT 'INVALIDOBJECTS'              ,OBJECTSCHEMA                ,OBJECTMODULENAME        ,''                      ,OBJECTTYPE        ,NULL              ,NULL               FROM SYSCAT.INVALIDOBJECTS
UNION ALL SELECT 'LIBRARIES'                   ,LIBSCHEMA                   ,LIBNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.LIBRARIES
UNION ALL SELECT 'LIBRARYBINDFILES'            ,LIBSCHEMA                   ,LIBNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.LIBRARYBINDFILES
UNION ALL SELECT 'LIBRARYVERSIONS'             ,LIBSCHEMA                   ,LIBNAME                 ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.LIBRARYVERSIONS
UNION ALL SELECT 'MEMBERSUBSETS'               ,''                          ,SUBSETNAME              ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.MEMBERSUBSETS
UNION ALL SELECT 'MODULEOBJECTS'               ,OBJECTSCHEMA                ,OBJECTMODULENAME        ,SPECIFICNAME            ,OBJECTTYPE        ,NULL              ,NULL               FROM SYSCAT.MODULEOBJECTS
UNION ALL SELECT 'MODULES'                     ,MODULESCHEMA                ,MODULENAME              ,''                      ,MODULETYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.MODULES
UNION ALL SELECT 'NAMEMAPPINGS'                ,LOGICAL_SCHEMA              ,LOGICAL_NAME            ,''                      ,TYPE              ,NULL              ,NULL               FROM SYSCAT.NAMEMAPPINGS
UNION ALL SELECT 'NICKNAMES'                   ,TABSCHEMA                   ,TABNAME                 ,''                      ,REMOTE_TYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.NICKNAMES
UNION ALL SELECT 'NODEGROUPDEF'                ,''                          ,NGNAME                  ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.NODEGROUPDEF
UNION ALL SELECT 'NODEGROUPS'                  ,''                          ,NGNAME                  ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.NODEGROUPS
UNION ALL SELECT 'PACKAGES'                    ,PKGSCHEMA                   ,PKGNAME                 ,''                      ,BOUNDBYTYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.PACKAGES
UNION ALL SELECT 'PERIODS'                     ,TABSCHEMA                   ,PERIODNAME              ,''                      ,PERIODTYPE        ,NULL              ,NULL               FROM SYSCAT.PERIODS
UNION ALL SELECT 'PREDICATESPECS'              ,FUNCSCHEMA                  ,FUNCNAME                ,SPECIFICNAME            ,''                ,NULL              ,NULL               FROM SYSCAT.PREDICATESPECS
UNION ALL SELECT 'PROCEDURES'                  ,PROCSCHEMA                  ,PROCNAME                ,SPECIFICNAME            ,PROGRAM_TYPE      ,CREATE_TIME       ,NULL               FROM SYSCAT.PROCEDURES
UNION ALL SELECT 'PROCPARMS'                   ,PROCSCHEMA                  ,PROCNAME                ,SPECIFICNAME            ,TYPENAME          ,NULL              ,NULL               FROM SYSCAT.PROCPARMS
UNION ALL SELECT 'REFERENCES'                  ,TABSCHEMA                   ,CONSTNAME               ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.REFERENCES
UNION ALL SELECT 'ROLES'                       ,''                          ,ROLENAME                ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.ROLES
UNION ALL SELECT 'ROUTINEOPTIONS'              ,ROUTINESCHEMA               ,ROUTINEMODULENAME       ,SPECIFICNAME            ,''                ,NULL              ,NULL               FROM SYSCAT.ROUTINEOPTIONS
UNION ALL SELECT 'ROUTINEPARMOPTIONS'          ,ROUTINESCHEMA               ,ROUTINENAME             ,SPECIFICNAME            ,''                ,NULL              ,NULL               FROM SYSCAT.ROUTINEPARMOPTIONS
UNION ALL SELECT 'ROUTINEPARMS'                ,ROUTINESCHEMA               ,ROUTINEMODULENAME       ,SPECIFICNAME            ,ROWTYPE           ,NULL              ,NULL               FROM SYSCAT.ROUTINEPARMS
UNION ALL SELECT 'ROUTINES'                    ,ROUTINESCHEMA               ,ROUTINEMODULENAME       ,SPECIFICNAME            ,ROUTINETYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.ROUTINES
UNION ALL SELECT 'ROUTINESFEDERATED'           ,ROUTINESCHEMA               ,ROUTINENAME             ,SPECIFICNAME            ,ROUTINETYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.ROUTINESFEDERATED
UNION ALL SELECT 'ROWFIELDS'                   ,TYPESCHEMA                  ,TYPEMODULENAME          ,''                      ,TYPEMODULENAME    ,NULL              ,NULL               FROM SYSCAT.ROWFIELDS
UNION ALL SELECT 'SCHEMATA'                    ,SCHEMANAME                  ,SCHEMANAME              ,''                      ,DEFINERTYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.SCHEMATA
UNION ALL SELECT 'SCPREFTBSPACES'              ,''                          ,SERVICECLASSNAME        ,''                      ,DATATYPE          ,NULL              ,NULL               FROM SYSCAT.SCPREFTBSPACES
UNION ALL SELECT 'SECURITYLABELACCESS'         ,''                          ,''                      ,''                      ,GRANTEETYPE       ,NULL              ,NULL               FROM SYSCAT.SECURITYLABELACCESS
UNION ALL SELECT 'SECURITYLABELCOMPONENTS'     ,''                          ,COMPNAME                ,''                      ,COMPTYPE          ,CREATE_TIME       ,NULL               FROM SYSCAT.SECURITYLABELCOMPONENTS
UNION ALL SELECT 'SECURITYLABELS'              ,''                          ,SECLABELNAME            ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.SECURITYLABELS
UNION ALL SELECT 'SECURITYPOLICIES'            ,''                          ,SECPOLICYNAME           ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.SECURITYPOLICIES
UNION ALL SELECT 'SECURITYPOLICYCOMPONENTRULES',''                          ,READACCESSRULENAME      ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.SECURITYPOLICYCOMPONENTRULES
UNION ALL SELECT 'SECURITYPOLICYEXEMPTIONS'    ,''                          ,ACCESSRULENAME          ,''                      ,GRANTEETYPE       ,NULL              ,NULL               FROM SYSCAT.SECURITYPOLICYEXEMPTIONS
UNION ALL SELECT 'SEQUENCES'                   ,SEQSCHEMA                   ,SEQNAME                 ,''                      ,DEFINERTYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.SEQUENCES
UNION ALL SELECT 'SERVEROPTIONS'               ,''                          ,WRAPNAME                ,''                      ,SERVERTYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.SERVEROPTIONS
UNION ALL SELECT 'SERVERS'                     ,''                          ,WRAPNAME                ,''                      ,SERVERTYPE        ,NULL              ,NULL               FROM SYSCAT.SERVERS
UNION ALL SELECT 'SERVICECLASSES'              ,''                          ,SERVICECLASSNAME        ,''                      ,CPUSHARETYPE      ,CREATE_TIME       ,NULL               FROM SYSCAT.SERVICECLASSES
UNION ALL SELECT 'STATEMENTS'                  ,PKGSCHEMA                   ,PKGNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.STATEMENTS
UNION ALL SELECT 'STOGROUPS'                   ,''                          ,SGNAME                  ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.STOGROUPS
UNION ALL SELECT 'SURROGATEAUTHIDS'            ,''                          ,''                      ,''                      ,TRUSTEDIDTYPE     ,NULL              ,NULL               FROM SYSCAT.SURROGATEAUTHIDS
UNION ALL SELECT 'TABCONST'                    ,TABSCHEMA                   ,CONSTNAME               ,''                      ,TYPE              ,NULL              ,NULL               FROM SYSCAT.TABCONST
UNION ALL SELECT 'TABLES'                      ,TABSCHEMA                   ,TABNAME                 ,''                      ,TYPE              ,CREATE_TIME       ,NULL               FROM SYSCAT.TABLES
UNION ALL SELECT 'TABLESPACES'                 ,''                          ,DBPGNAME                ,''                      ,TBSPACETYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.TABLESPACES
UNION ALL SELECT 'TABOPTIONS'                  ,TABSCHEMA                   ,TABNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.TABOPTIONS
UNION ALL SELECT 'THRESHOLDS'                  ,''                          ,THRESHOLDNAME           ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.THRESHOLDS
UNION ALL SELECT 'TRANSFORMS'                  ,TYPESCHEMA                  ,TYPENAME                ,SPECIFICNAME            ,CHAR(TYPEID)      ,NULL              ,NULL               FROM SYSCAT.TRANSFORMS
UNION ALL SELECT 'TRIGGERS'                    ,TRIGSCHEMA                  ,TRIGNAME                ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.TRIGGERS
UNION ALL SELECT 'TYPEMAPPINGS'                ,TYPESCHEMA                  ,TYPENAME                ,''                      ,TYPE_MAPPING      ,CREATE_TIME       ,NULL               FROM SYSCAT.TYPEMAPPINGS
UNION ALL SELECT 'USAGELISTS'                  ,USAGELISTSCHEMA             ,USAGELISTNAME           ,''                      ,OBJECTTYPE        ,NULL              ,NULL               FROM SYSCAT.USAGELISTS
UNION ALL SELECT 'USEROPTIONS'                 ,''                          ,SERVERNAME              ,''                      ,AUTHIDTYPE        ,NULL              ,NULL               FROM SYSCAT.USEROPTIONS
UNION ALL SELECT 'VARIABLES'                   ,VARSCHEMA                   ,VARMODULENAME           ,''                      ,TYPEMODULENAME    ,CREATE_TIME       ,NULL               FROM SYSCAT.VARIABLES
UNION ALL SELECT 'VIEWS'                       ,VIEWSCHEMA                  ,VIEWNAME                ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.VIEWS
UNION ALL SELECT 'WORKACTIONS'                 ,''                          ,ACTIONNAME              ,''                      ,ACTIONTYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.WORKACTIONS
UNION ALL SELECT 'WORKACTIONSETS'              ,''                          ,ACTIONSETNAME           ,''                      ,OBJECTTYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.WORKACTIONSETS
UNION ALL SELECT 'WORKCLASSATTRIBUTES'         ,''                          ,WORKCLASSNAME           ,''                      ,TYPE              ,NULL              ,NULL               FROM SYSCAT.WORKCLASSATTRIBUTES
UNION ALL SELECT 'WORKCLASSES'                 ,''                          ,WORKCLASSNAME           ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.WORKCLASSES
UNION ALL SELECT 'WORKCLASSSETS'               ,''                          ,WORKCLASSSETNAME        ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.WORKCLASSSETS
UNION ALL SELECT 'WORKLOADCONNATTR'            ,''                          ,WORKLOADNAME            ,''                      ,CONNATTRTYPE      ,NULL              ,NULL               FROM SYSCAT.WORKLOADCONNATTR
UNION ALL SELECT 'WORKLOADS'                   ,''                          ,WORKLOADNAME            ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.WORKLOADS
UNION ALL SELECT 'WRAPOPTIONS'                 ,''                          ,WRAPNAME                ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.WRAPOPTIONS
UNION ALL SELECT 'WRAPPERS'                    ,''                          ,WRAPNAME                ,''                      ,WRAPTYPE          ,NULL              ,NULL               FROM SYSCAT.WRAPPERS
UNION ALL SELECT 'XDBMAPGRAPHS'                ,OBJECTSCHEMA                ,OBJECTNAME              ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.XDBMAPGRAPHS
UNION ALL SELECT 'XDBMAPSHREDTREES'            ,OBJECTSCHEMA                ,OBJECTNAME              ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.XDBMAPSHREDTREES
UNION ALL SELECT 'XSROBJECTCOMPONENTS'         ,OBJECTSCHEMA                ,OBJECTNAME              ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.XSROBJECTCOMPONENTS
UNION ALL SELECT 'XSROBJECTDETAILS'            ,OBJECTSCHEMA                ,OBJECTNAME              ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.XSROBJECTDETAILS
UNION ALL SELECT 'XSROBJECTHIERARCHIES'        ,SCHEMALOCATION              ,TARGETNAMESPACE         ,''                      ,HTYPE             ,NULL              ,NULL               FROM SYSCAT.XSROBJECTHIERARCHIES
UNION ALL SELECT 'XSROBJECTS'                  ,OBJECTSCHEMA                ,OBJECTNAME              ,''                      ,OBJECTTYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.XSROBJECTS
