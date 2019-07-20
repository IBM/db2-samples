--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                        */
--      Version 10.2.1 for Linux, UNIX AND Windows                   */
--                                                                   */
--     Sample Monitor control tables for UNIX AND NT                 */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2016. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/

--********************************************************************/
-- Create Monitor Control tables                                     */
-- Monitor schema must be ASN and the tables are IBMSNAP             */
-- not IBMQREP, like the other Qrep  tables                          */
-- In this sample the monitor tables are created in the default      */
-- tablespace                                                        */
--********************************************************************/


CREATE TABLE ASN.IBMSNAP_CONTACTS(
CONTACT_NAME                    VARCHAR(127) NOT NULL,
EMAIL_ADDRESS                   VARCHAR(128) NOT NULL,
ADDRESS_TYPE                    CHAR(1) NOT NULL,
DELEGATE                        VARCHAR(127),
DELEGATE_START                  DATE,
DELEGATE_END                    DATE,
DESCRIPTION                     VARCHAR(1024));

CREATE UNIQUE INDEX ASN.IBMSNAP_CONTACTSX
ON ASN.IBMSNAP_CONTACTS(
CONTACT_NAME                    ASC);

ALTER TABLE ASN.IBMSNAP_CONTACTS VOLATILE CARDINALITY;

CREATE TABLE ASN.IBMSNAP_GROUPS(
GROUP_NAME                      VARCHAR(127) NOT NULL,
DESCRIPTION                     VARCHAR(1024));

CREATE UNIQUE INDEX ASN.IBMSNAP_GROUPSX
ON ASN.IBMSNAP_GROUPS(
GROUP_NAME                      ASC);

ALTER TABLE ASN.IBMSNAP_GROUPS VOLATILE CARDINALITY;

CREATE TABLE ASN.IBMSNAP_CONTACTGRP(
GROUP_NAME                      VARCHAR(127) NOT NULL,
CONTACT_NAME                    VARCHAR(127) NOT NULL);

CREATE UNIQUE INDEX ASN.IBMSNAP_CONTACTGRPX
ON ASN.IBMSNAP_CONTACTGRP(
GROUP_NAME                      ASC,
CONTACT_NAME                    ASC);

ALTER TABLE ASN.IBMSNAP_CONTACTGRP VOLATILE CARDINALITY;

CREATE TABLE ASN.IBMSNAP_MONSERVERS(
MONITOR_QUAL                    CHAR(18) NOT NULL,
SERVER_NAME                     CHAR(18) NOT NULL,
SERVER_ALIAS                    CHAR( 8),
LAST_MONITOR_TIME               TIMESTAMP NOT NULL,
START_MONITOR_TIME              TIMESTAMP,
END_MONITOR_TIME                TIMESTAMP,
LASTRUN                         TIMESTAMP NOT NULL,
LASTSUCCESS                     TIMESTAMP,
STATUS                          SMALLINT NOT NULL);

CREATE UNIQUE INDEX ASN.IBMSNAP_MONSERVERSX
ON ASN.IBMSNAP_MONSERVERS(
MONITOR_QUAL                    ASC,
SERVER_NAME                     ASC);

ALTER TABLE ASN.IBMSNAP_MONSERVERS VOLATILE CARDINALITY;

CREATE TABLE ASN.IBMSNAP_CONDITIONS(
MONITOR_QUAL                    CHAR(18) NOT NULL,
SERVER_NAME                     CHAR(18) NOT NULL,
COMPONENT                       CHAR( 1) NOT NULL,
SCHEMA_OR_QUAL                  VARCHAR(128) NOT NULL,
SET_NAME                        CHAR(18) NOT NULL WITH DEFAULT ' ',
SERVER_ALIAS                    CHAR( 8),
ENABLED                         CHAR( 1) NOT NULL,
CONDITION_NAME                  VARCHAR(20) NOT NULL,
PARM_INT                        INT,
PARM_CHAR                       VARCHAR(128),
CONTACT_TYPE                    CHAR( 1) NOT NULL,
CONTACT                         VARCHAR(127) NOT NULL);

CREATE UNIQUE INDEX ASN.IBMSNAP_CONDITIONSX
ON ASN.IBMSNAP_CONDITIONS(
MONITOR_QUAL                    ASC,
SERVER_NAME                     ASC,
COMPONENT                       ASC,
SCHEMA_OR_QUAL                  ASC,
SET_NAME                        ASC,
CONDITION_NAME                  ASC);

ALTER TABLE ASN.IBMSNAP_CONDITIONS VOLATILE CARDINALITY;

CREATE TABLE ASN.IBMSNAP_ALERTS(
MONITOR_QUAL                    CHAR(18) NOT NULL,
ALERT_TIME                      TIMESTAMP NOT NULL,
COMPONENT                       CHAR( 1) NOT NULL,
SERVER_NAME                     CHAR(18) NOT NULL,
SERVER_ALIAS                    CHAR( 8),
SCHEMA_OR_QUAL                  VARCHAR(128) NOT NULL,
SET_NAME                        CHAR(18) NOT NULL WITH DEFAULT ' ',
CONDITION_NAME                  VARCHAR(20) NOT NULL,
OCCURRED_TIME                   TIMESTAMP NOT NULL,
ALERT_COUNTER                   SMALLINT NOT NULL,
ALERT_CODE                      CHAR( 10) NOT NULL,
RETURN_CODE                     INT NOT NULL,
NOTIFICATION_SENT               CHAR(1) NOT NULL,
ALERT_MESSAGE                   VARCHAR(1024) NOT NULL);

CREATE  INDEX ASN.IBMSNAP_ALERTSX
ON ASN.IBMSNAP_ALERTS(
MONITOR_QUAL                    ASC,
COMPONENT                       ASC,
SERVER_NAME                     ASC,
SCHEMA_OR_QUAL                  ASC,
SET_NAME                        ASC,
CONDITION_NAME                  ASC,
ALERT_CODE                      ASC);

ALTER TABLE ASN.IBMSNAP_ALERTS VOLATILE CARDINALITY;

CREATE TABLE ASN.IBMSNAP_MONTRACE(
MONITOR_QUAL                    CHAR(18) NOT NULL,
TRACE_TIME                      TIMESTAMP NOT NULL,
OPERATION                       CHAR( 8) NOT NULL,
DESCRIPTION                     VARCHAR(1024) NOT NULL);

CREATE  INDEX ASN.IBMSNAP_MONTRACEX
ON ASN.IBMSNAP_MONTRACE(
MONITOR_QUAL                    ASC,
TRACE_TIME                      ASC);

ALTER TABLE ASN.IBMSNAP_MONTRACE VOLATILE CARDINALITY;

CREATE TABLE ASN.IBMSNAP_MONTRAIL(
MONITOR_QUAL                    CHAR(18) NOT NULL,
SERVER_NAME                     CHAR(18) NOT NULL,
SERVER_ALIAS                    CHAR( 8),
STATUS                          SMALLINT NOT NULL,
LASTRUN                         TIMESTAMP NOT NULL,
LASTSUCCESS                     TIMESTAMP,
ENDTIME                         TIMESTAMP NOT NULL WITH DEFAULT ,
LAST_MONITOR_TIME               TIMESTAMP NOT NULL,
START_MONITOR_TIME              TIMESTAMP,
END_MONITOR_TIME                TIMESTAMP,
SQLCODE                         INT,
SQLSTATE                        CHAR(5),
NUM_ALERTS                      INT NOT NULL,
NUM_NOTIFICATIONS               INT NOT NULL,
SUSPENSION_NAME                 VARCHAR(128));

CREATE  INDEX ASN.IBMSNAP_MONTRAILX
ON ASN.IBMSNAP_MONTRAIL(
MONITOR_QUAL                    ASC,
LASTRUN                         ASC);

CREATE TABLE ASN.IBMSNAP_MONENQ(
MONITOR_QUAL                    CHAR( 18) NOT NULL);

CREATE TABLE ASN.IBMSNAP_MONPARMS(
MONITOR_QUAL                    CHAR( 18) NOT NULL,
ALERT_PRUNE_LIMIT               INT WITH DEFAULT 10080,
AUTOPRUNE                       CHAR(  1) WITH DEFAULT 'Y',
EMAIL_SERVER                    VARCHAR(128),
LOGREUSE                        CHAR(  1) WITH DEFAULT 'N',
LOGSTDOUT                       CHAR(  1) WITH DEFAULT 'N',
NOTIF_PER_ALERT                 INT WITH DEFAULT 3,
NOTIF_MINUTES                   INT WITH DEFAULT 60,
MONITOR_ERRORS                  VARCHAR(128),
MONITOR_INTERVAL                INT WITH DEFAULT 300,
MONITOR_PATH                    VARCHAR(1040),
RUNONCE                         CHAR(  1) WITH DEFAULT 'N',
TERM                            CHAR(  1) WITH DEFAULT 'N',
TRACE_LIMIT                     INT WITH DEFAULT 10080,
ARCH_LEVEL                      CHAR(  4) WITH DEFAULT '0905',
DELAY                           CHAR(1) WITH DEFAULT 'N');

CREATE UNIQUE INDEX ASN.IBMSNAP_MONPARMSX
ON ASN.IBMSNAP_MONPARMS(
MONITOR_QUAL                    ASC);

ALTER TABLE ASN.IBMSNAP_MONPARMS VOLATILE CARDINALITY;

CREATE TABLE ASN.IBMSNAP_TEMPLATES(
TEMPLATE_NAME                   VARCHAR(128) NOT NULL PRIMARY KEY,
START_TIME                      TIME NOT NULL,
WDAY                            SMALLINT DEFAULT null,
DURATION                        INT NOT NULL);

ALTER TABLE ASN.IBMSNAP_TEMPLATES VOLATILE CARDINALITY;

CREATE TABLE ASN.IBMSNAP_SUSPENDS(
SUSPENSION_NAME                 VARCHAR(128) NOT NULL PRIMARY KEY,
SERVER_NAME                     CHAR( 18) NOT NULL,
SERVER_ALIAS                    CHAR(  8),
TEMPLATE_NAME                   VARCHAR(128),
START                           TIMESTAMP NOT NULL,
STOP                            TIMESTAMP NOT NULL);

CREATE UNIQUE INDEX ASN.IBMSNAP_SUSPENDSX
ON ASN.IBMSNAP_SUSPENDS(
SERVER_NAME                     ASC,
START                           ASC,
TEMPLATE_NAME                   ASC);

ALTER TABLE ASN.IBMSNAP_SUSPENDS VOLATILE CARDINALITY;
